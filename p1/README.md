## Part 1: Vagrant & K3s

The instructions themselves were simple: two VMs, one k3s server and one k3s agent. In practice this was the most complex part, because so many variables were left open — box choice, provider, network setup — and each combination came with its own failure mode.

### Provider choice: libvirt over VirtualBox

Different boxes supported different volume mount types, and provider performance varied a lot — some setups were noticeably slower than others. I settled on **libvirt/QEMU**: it was faster in practice and takes advantage of the host's kernel modules directly, rather than going through a heavier virtualization layer. Tested on Fedora and Ubuntu hosts.

### Distro choice: Alpine

Early on, the server and agent nodes would consistently fail to connect — pinging the k3s server from the agent would always fail, even with a correct node token. After ruling out token/config issues, I switched the box to **Alpine**, which resolved the connectivity problem and came with the added benefit of a much lighter footprint (faster boot, minimal packages), which suits k3s well in a resource-constrained environment.

Setup followed this guide: https://oneuptime.com/blog/post/2026-03-20-k3s-alpine-linux/view

### VirtualBox vs. libvirt: is the Vagrantfile portable?

The Vagrantfile can technically run under either VirtualBox or libvirt, since `generic/alpine319` is a multi-provider box — but only libvirt gets explicit resource tuning (CPU and memory), via a `config.vm.provider :libvirt` block. There's no equivalent `:virtualbox` block, so running this under VirtualBox would fall back to its own default resource allocation instead of the values set here.

Vagrant does **not** rewrite or convert the file to match whatever provider is installed — it simply skips provider blocks that don't apply to the one you're using.
```

### Node token

Both `server.sh` and `agent.sh` expect a pre-existing token at `/vagrant/.node-token`. This file must be generated **before** `vagrant up` runs — the provisioning scripts fail fast (`exit 1`) if it's missing or empty.

### Provisioning order

Each node runs its provisioners in a fixed sequence:

1. `deps.sh` — base package installation (`apk`-based, since the box is Alpine).
2. `kernel-modules.sh` — loads and persists the kernel modules k3s needs (`br_netfilter`, `overlay`, `nf_conntrack`), applies the required `sysctl` settings, enables cgroups via OpenRC, and disables swap.
3. `server.sh` / `agent.sh` — installs k3s itself, in controller or agent mode respectively.

This ordering is deliberate: the environment must be fully prepared — modules loaded, sysctl applied, swap off, dependencies present — before the k3s installer ever runs, instead of racing dependency setup against k3s startup.

Note that the agent's k3s provisioner is defined with `run: "never"`, meaning `vagrant up` does **not** install the agent automatically — it only runs when explicitly triggered (e.g. `vagrant provision --provision-with install_agent_k3s`), ensuring the server is fully up and the token exists before the agent attempts to join.

