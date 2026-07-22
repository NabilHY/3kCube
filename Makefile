.PHONY: p1 p1-provision p1-clean p1-re p1-status \
	p1-ssh-server p1-ssh-agent p1-halt

P1_DIR   = ./p1
SERVER   = member1S
AGENT    = member2SW

# ──── Build ────────────────────────────────────────────────

## Bring up both VMs (runs install_deps automatically)
p1: p1-clean
	@echo "⟶  Bringing up server and agent VMs …"
	cd $(P1_DIR) && rm -rf node-token
	cd $(P1_DIR) && vagrant up
	cd $(P1_DIR) && vagrant provision $(SERVER) --provision-with setup_cluster
	cd $(P1_DIR) && vagrant provision $(AGENT)  --provision-with setup_cluster	
	cd $(P1_DIR) && vagrant provision $(SERVER)  --provision-with setup_controller

## Destroy VMs and wipe the node-token
p1-clean:
	@echo "⟶  Destroying VMs and cleaning up …"
	cd $(P1_DIR) && vagrant destroy -f
	rm -f $(P1_DIR)/node-token

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
