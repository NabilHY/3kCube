.PHONY: help p1 p1-provision p1-clean p1-re p1-status \
	p1-ssh-server p1-ssh-agent p1-halt \
	p2 p2-clean p2-re p2-halt p2-restore p2-status p2-ssh

## Show this help
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## //' > /dev/null
	@echo "Usage: make <target>"
	@echo ""
	@awk '/^# ═/{header=1; next} header && /^# /{gsub(/^# /,""); printf "\n\033[1m%s\033[0m\n", $$0; header=0; next} header{header=0} /^## /{desc=substr($$0,4)} /^[a-z][a-z0-9_-]*:/{if(desc){printf "  \033[36m%-16s\033[0m %s\n", $$1, desc; desc=""}}' $(MAKEFILE_LIST)

P1_DIR   = ./p1
SERVER   = member1S
AGENT    = member2SW

P2_DIR   = ./p2
P2_SERVER = nhayounS

# ═══════════════════════════════════════════════════════════
# P1
# ═══════════════════════════════════════════════════════════

# K3S Token
TOKEN_FILE:= $(P1_DIR)/.node-token

$(TOKEN_FILE):
	echo "Generating new K3s cluster token..."
	openssl rand -hex 32 > $(TOKEN_FILE)
	chmod 600 $(TOKEN_FILE)

# ──── Build ────────────────────────────────────────────────

## Bring up both VMs (runs install_deps automatically)
p1: p1-clean $(TOKEN_FILE)
	@echo "⟶  Bringing up server and agent VMs …"
	cd $(P1_DIR) && vagrant up
	cd $(P1_DIR) && vagrant provision $(AGENT)  --provision-with install_agent_k3s

## Destroy VMs and wipe the node-token
p1-clean:
	@echo "⟶  Destroying VMs and cleaning up …"
	rm -rf $(TOKEN_FILE)
	cd $(P1_DIR) && vagrant destroy -f


## Tear down and rebuild from scratch
p1-re: p1-clean p1

## Halt (power off) both VMs without destroying them
p1-halt:
	cd $(P1_DIR) && vagrant halt

# ──── Info / Debug ─────────────────────────────────────────

## Show VM status
p1-status:
	cd $(P1_DIR) && vagrant status

## SSH into the server node
p1-ssh-server:
	cd $(P1_DIR) && vagrant ssh $(SERVER)

## SSH into the agent node
p1-ssh-agent:
	cd $(P1_DIR) && vagrant ssh $(AGENT)

# ═══════════════════════════════════════════════════════════
# P2
# ═══════════════════════════════════════════════════════════

# ──── Build ────────────────────────────────────────────────

## Bring up the server VM
p2: p2-clean
	@echo "⟶  Bringing up p2 server VM …"
	cd $(P2_DIR) && vagrant up

## Destroy the VM
p2-clean:
	@echo "⟶  Destroying p2 VM …"
	cd $(P2_DIR) && vagrant destroy -f

## Tear down and rebuild from scratch
p2-re: p2-clean p2

## Halt (power off) the VM without destroying it
p2-halt:
	cd $(P2_DIR) && vagrant halt

## Restore VM to the kubectl-installed snapshot
p2-restore:
	cd $(P2_DIR) && vagrant snapshot restore $(P2_SERVER) kubectl-installed

# ──── Info / Debug ─────────────────────────────────────────

## Show VM status
p2-status:
	cd $(P2_DIR) && vagrant status

## SSH into the server node
p2-ssh:
	cd $(P2_DIR) && vagrant ssh $(P2_SERVER)
