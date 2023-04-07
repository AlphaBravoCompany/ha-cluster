#!/bin/bash

## Create Control-Plane LB
if ! multipass list | grep -q "bastion"; then
  if ! multipass list | grep -q "cp-1"; then
    echo "Configuring Bastion Server: bastion"
    multipass transfer cp-1:/etc/rancher/rke2/rke2.yaml .
    multipass transfer --parents rke2.yaml bastion:/home/ubuntu/.kube/config
    multipass exec bastion -- chmod +x /tmp/bastion.sh
    multipass exec bastion -- sudo bash /tmp/bastion.sh
fi