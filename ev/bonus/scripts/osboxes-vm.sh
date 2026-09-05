#!/bin/bash
set -eou pipefail

VM_PATH="$HOME/goinfre/fedora.vdi"
VM_NAME="fedora"
VM_DOWNLOAD="https://ixpeering.dl.sourceforge.net/project/osboxes/v/vb/18-F-d/42/Server/64bit.7z?viasf=1&fid=0259256c38930193&e=1787920453&st=ZMZj2ngg_XOFSZ791T0bTQ"
ARCHIVE_PATH="$HOME/goinfre/fedora_archive.7z"
SSH_PORT=2222

# ---------------------------------------------------------------------------
# 1. VDI: skip download+extract entirely if it's already there
# ---------------------------------------------------------------------------
verify_archive() {
    # Returns 0 if the .7z is structurally sound, 1 otherwise.
    python3 -c "
import py7zr, sys
try:
    with py7zr.SevenZipFile(sys.argv[1]) as z:
        pass
    sys.exit(0)
except Exception as e:
    print(f'archive check failed: {e}', file=sys.stderr)
    sys.exit(1)
" "$1"
}

if [ -f "$VM_PATH" ]; then
    echo "===> VDI already exists at $VM_PATH, skipping download/extract"
else
    if [ -f "$ARCHIVE_PATH" ]; then
        echo "===> Archive found at $ARCHIVE_PATH, verifying integrity..."
        if verify_archive "$ARCHIVE_PATH"; then
            echo "===> Archive is valid, skipping fetch"
        else
            echo "===> Cached archive is corrupt, removing and re-downloading"
            rm -f "$ARCHIVE_PATH"
        fi
    fi

    if [ ! -f "$ARCHIVE_PATH" ]; then
        echo "===> Downloading VM archive..."
        curl -fL -C - --retry 10 --retry-connrefused --retry-delay 3  -o "$ARCHIVE_PATH" "$VM_DOWNLOAD"
        echo "===> Verifying freshly downloaded archive..."
        if ! verify_archive "$ARCHIVE_PATH"; then
            echo "ERROR: downloaded archive is corrupt (bad link, expired signed URL, or truncated transfer)" >&2
            rm -f "$ARCHIVE_PATH"
            exit 1
        fi
    fi

    echo "===> Extracting archive"
    python3 -c "import py7zr,sys; py7zr.SevenZipFile(sys.argv[1]).extractall(sys.argv[2])" \
        "$ARCHIVE_PATH" "$HOME/goinfre/"
    rm -f "$ARCHIVE_PATH"

    mv "$HOME/goinfre/64bit/Fedora 42 Server (64bit).vdi" "$HOME/goinfre/64bit/fedora.vdi"
    mv "$HOME/goinfre/64bit/fedora.vdi" "$VM_PATH"
fi

# ---------------------------------------------------------------------------
# 2. VM registration: skip create+attach if the VM is already registered
# ---------------------------------------------------------------------------
if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "===> VM $VM_NAME already registered, skipping create"
else
    echo "===> Creating VM $VM_NAME"
    VBoxManage createvm --name "$VM_NAME" --ostype "Fedora_64" --register
    VBoxManage modifyvm "$VM_NAME" \
        --memory 4096 \
        --cpus 4 \
        --pae on \
        --longmode on \
        --nic1 nat
    VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAHCI
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA" \
        --port 0 --device 0 --type hdd --medium "$VM_PATH"
fi

# ---------------------------------------------------------------------------
# 3. Port forwards: delete-then-add so a rerun doesn't error on "already exists"
# ---------------------------------------------------------------------------
echo "===> Ensuring port forwards"
VBoxManage modifyvm "$VM_NAME" --natpf1 delete "guest ssh" 2>/dev/null || true
VBoxManage modifyvm "$VM_NAME" --natpf1 "guest ssh,tcp,,${SSH_PORT},,22" 2>/dev/null || true
VBoxManage modifyvm "$VM_NAME" --natpf1 delete "web traffic" 2>/dev/null 2>/dev/null || true
VBoxManage modifyvm "$VM_NAME" --natpf1 "web traffic,tcp,,8000,,8000" || true
echo "Added port forwarfing rules 8000->8000 2222->22"

# ---------------------------------------------------------------------------
# 4. Start: skip if already running
# ---------------------------------------------------------------------------
VM_STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -oP '(?<=VMState=")[a-z]+' || echo "unknown")

if [ "$VM_STATE" = "running" ]; then
    echo "===> VM already running, skipping start"
else
    echo "===> Starting VM $VM_NAME"
    VBoxManage startvm "$VM_NAME" --type headless 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 5. Wait for SSH to actually accept connections before handing control back
# ---------------------------------------------------------------------------
echo "===> Waiting for SSH on port $SSH_PORT..."
SSH_UP=0
for i in $(seq 1 30); do
    if ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=2 \
        osboxes@localhost true 2>/dev/null; then
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
