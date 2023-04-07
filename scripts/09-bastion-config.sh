#!/bin/bash

## Create Control-Plane LB
if ! multipass list | grep -q "bastion"; then
  if ! multipass list | grep -q "cp-1"; then
    echo "Configuring Bastion Server: bastion"
    multipass transfer /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa bastion:/home/ubuntu/.ssh/
    multipass exec bastion -- chmod +x /tmp/bastion.sh
    multipass exec bastion -- sudo bash /tmp/bastion.sh
fi