.PHONY: help p1 p1-provision p1-clean p1-re p1-status \
	p1-ssh-server p1-ssh-agent p1-halt \
	p2 p2-test p2-clean p2-re p2-halt p2-restore p2-status p2-ssh \
	p3 p3-clean p3-re p3-status p3-test \
	bonus bonus-clean bonus-re bonus-status bonus-test

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

P3_DIR   = ./p3
BONUS_DIR = ./bonus
SOPS_AGE_KEY_FILE ?= $(HOME)/.config/sops/age/keys.txt
export SOPS_AGE_KEY_FILE


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
	@$(MAKE) p2-test

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

# ═══════════════════════════════════════════════════════════
# P3
# ═══════════════════════════════════════════════════════════

# ──── Build ────────────────────────────────────────────────

## Set up k3d cluster with ArgoCD CD pipeline
p3: p3-clean
	@echo "⟶  Setting up p3 (k3d + ArgoCD) …"
	bash $(P3_DIR)/scripts/exec.sh

## Delete the k3d cd-cluster
p3-clean:
	@echo "⟶  Destroying p3 k3d cluster …"
	-k3d cluster delete cd-cluster

## Tear down and rebuild from scratch
p3-re: p3-clean p3

# ──── Info / Debug ─────────────────────────────────────────

## Show k3d cluster and pod status
p3-status:
	@echo "── k3d clusters ──"
	-k3d cluster list
	@echo ""
	@echo "── kubectl nodes ──"
	-kubectl get nodes
	@echo ""
	@echo "── all pods ──"
	-kubectl get pods -A

## Run CD validation test (delete or update): make p3-test ACTION=delete
p3-test:
	@test -n "$(ACTION)" || { echo "Usage: make p3-test ACTION=<delete|update>"; exit 1; }
	cd $(P3_DIR)/scripts && python3 test-cd.py $(ACTION)

# ═══════════════════════════════════════════════════════════
# BONUS
# ═══════════════════════════════════════════════════════════

# ──── Build ────────────────────────────────────────────────

## Set up k3d cluster with ArgoCD + Gitea CD pipeline
bonus: bonus-clean
	@test -f "$(SOPS_AGE_KEY_FILE)" \
		|| { echo "ERROR: age private key not found at $(SOPS_AGE_KEY_FILE)"; \
		     echo "       Place the matching private key for the encrypted secret there"; exit 1; }
	@echo "⟶  Setting up bonus (k3d + ArgoCD + Gitea) …"
	bash $(BONUS_DIR)/scripts/exec.sh

## Delete the k3d cd-cluster
bonus-clean:
	@echo "⟶  Destroying bonus k3d cluster …"
	-k3d cluster delete cd-cluster

## Tear down and rebuild from scratch
bonus-re: bonus-clean bonus

# ──── Info / Debug ─────────────────────────────────────────

## Show k3d cluster and pod status
bonus-status:
	@echo "── k3d clusters ──"
	-k3d cluster list
	@echo ""
	@echo "── kubectl nodes ──"
	-kubectl get nodes
	@echo ""
	@echo "── all pods ──"
	-kubectl get pods -A

## Run CD validation test (delete or update): make bonus-test ACTION=delete
bonus-test:
	@test -n "$(ACTION)" || { echo "Usage: make bonus-test ACTION=<delete|update>"; exit 1; }
	cd $(BONUS_DIR)/scripts && python3 test-cd.py $(ACTION)
