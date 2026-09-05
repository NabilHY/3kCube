#!/bin/bash
set -eou pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <repo_name>" >&2
	exit 1
fi

REPO_NAME="$1"
REPO_PATH="$HOME/$REPO_NAME"
REMOTE_PATH="/home/osboxes/$REPO_NAME"
SCRIPTS_DIR="$REMOTE_PATH/p3/scripts"
SSH_PORT=2222
SSH_TARGET="osboxes@localhost"
SSH_KEY="$HOME/.ssh/osboxes_vm_ed25519"

SSH_OPTS=(-i "$SSH_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no)

remote_exec() {
    if [ "$#" -eq 0 ]; then
        echo "ERROR: remote_exec called with no command" >&2
        return 1
    fi
    ssh -t -p "$SSH_PORT" "${SSH_OPTS[@]}" "$SSH_TARGET" "$@"
}

if [ ! -d "$REPO_PATH" ]; then
    echo "ERROR: $REPO_PATH not found, nothing to copy" >&2
    exit 1
fi
echo "===> Repo: $REPO_PATH"

if [ ! -f "$SSH_KEY" ]; then
    echo "===> Generating dedicated SSH keypair at $SSH_KEY"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "copy-and-prov@$(hostname)"
fi

VM_NAME="fedora"
if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "===> VM $VM_NAME already registered, skipping create/copy/prov"
    VM_STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -oP '(?<=VMState=")[a-z]+' || echo "unknown")
    if [ "$VM_STATE" = "running" ]; then
        echo "===> VM already running, skipping start"
    else
        echo "===> Starting VM $VM_NAME"
        VBoxManage startvm "$VM_NAME" --type headless || true
    fi
    echo "===> Waiting for SSH on port $SSH_PORT..."
    SSH_UP=0
    for i in $(seq 1 30); do
        if ssh -p "$SSH_PORT" "${SSH_OPTS[@]}" -o ConnectTimeout=2 \
            "$SSH_TARGET" true 2>/dev/null; then
            SSH_UP=1
            break
        fi
        sleep 2
    done
    if [ "$SSH_UP" -ne 1 ]; then
        echo "ERROR: SSH did not come up on port $SSH_PORT after 60s" >&2
        exit 1
    fi
    echo "===> SSH is up"
    echo "===> Run build"
    remote_exec "bash $SCRIPTS_DIR/exec.sh"
else
    echo "===> VM not registered yet, running full setup"
	bash "$REPO_PATH"/bonus/scripts/osboxes-vm.sh

    echo "===> Waiting for SSH on port $SSH_PORT before first contact..."
    SSH_UP=0
    for i in $(seq 1 30); do
        if ssh -p "$SSH_PORT" -o IdentitiesOnly=no -o StrictHostKeyChecking=no \
            -o ConnectTimeout=2 -o PasswordAuthentication=yes \
            "$SSH_TARGET" true 2>/dev/null; then
            SSH_UP=1
            break
        fi
        sleep 2
    done
    if [ "$SSH_UP" -ne 1 ]; then
        echo "ERROR: SSH did not come up on port $SSH_PORT after 60s" >&2
        exit 1
    fi

    echo "===> Installing our public key on the VM (password prompt expected here, once)"
    ssh-copy-id -i "${SSH_KEY}.pub" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_TARGET"

    echo "===> Sync repo to remote VM"
    rsync -az --delete -e "ssh -p $SSH_PORT ${SSH_OPTS[*]}" "$REPO_PATH" "$SSH_TARGET:/home/osboxes/"

    remote_exec "bash $SCRIPTS_DIR/ssh-setup.sh"
    echo "===> Run build"
    remote_exec "bash $SCRIPTS_DIR/exec.sh"
fi

echo "===> Running tests on CD Pipeline"
remote_exec "python3 $SCRIPTS_DIR/test-cd.py delete"
remote_exec "python3 $SCRIPTS_DIR/test-cd.py update $REPO_PATH"
