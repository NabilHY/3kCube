#!/bin/bash
set -euo pipefail

# Nuke and reinit every single time this runs. setup_cluster is triggered
# by hand against long-lived VMs (run: "never" in the Vagrantfile) — without
# this, repeated runs can leave a regenerated server CA out of sync with
# whatever token/state the agent is holding, which is exactly what "CA hash
# does not match" / indefinite "server is not ready" means. This is not
# optional for a script you intend to re-run against a VM that isn't fresh.
systemctl stop k3s 2>/dev/null || true
rm -rf /var/lib/rancher/k3s /etc/rancher/k3s
rm -f /vagrant/node-token

export INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --advertise-address=192.168.56.110 --flannel-iface=eth1 --write-kubeconfig-mode 644 --disable=traefik --disable=metrics-server"
echo "Starting K3s server installation..."
curl -sfL https://get.k3s.io | sh -
echo "K3s installation succeeded!"

echo "Installing kubectl"
curl -fLO "https://dl.k8s.io/release/$(curl -fL -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl
echo "kubectl installation succeeded!"

echo "Waiting for server token generation..."
until [ -s /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

# Atomic write: the agent checks for a non-empty file, so a partial write
# here would hand it a truncated token — same race class as before, just
# one file over.
cat /var/lib/rancher/k3s/server/node-token >/vagrant/.node-token.tmp
mv /vagrant/.node-token.tmp /vagrant/node-token
chown vagrant:vagrant /vagrant/node-token
chmod 644 /vagrant/node-token
echo "node-token published to /vagrant/node-token"

echo "Verifying node is registered with the correct internal IP..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
# Full path deliberately — non-login provisioning shells don't reliably
# have /usr/local/bin on PATH even though the binary is genuinely there.
/usr/local/bin/kubectl get nodes -o wide

# Persist KUBECONFIG for the vagrant user's future interactive sessions,
# so `vagrant ssh` + `kubectl` works without exporting it by hand every time.
if ! grep -q KUBECONFIG /home/vagrant/.bashrc 2>/dev/null; then
  echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >>/home/vagrant/.bashrc
fi
