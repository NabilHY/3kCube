#!/bin/bash

virsh uri # sanity check — should print qemu:///system

sudo mkdir -p /var/lib/libvirt/images
virsh pool-define-as default dir --target /var/lib/libvirt/images
virsh pool-start default
virsh pool-autostart default

virsh net-define /dev/stdin <<EOF
<network>
  <name>vagrant-private</name>
  <bridge name='virbr-vagrant' stp='on' delay='0'/>
  <ip address='192.168.56.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.56.2' end='192.168.56.254'/>
    </dhcp>
  </ip>
</network>
EOF
virsh net-start vagrant-private
virsh net-autostart vagrant-private

virsh pool-list --all
virsh net-list --all
