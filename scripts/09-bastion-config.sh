#!/bin/bash

## Create Control-Plane LB
if ! multipass list | grep -q "bastion"; then
  if ! multipass list | grep -q "bastion"; then
    echo "Configuring Bastion Server: bastion"
    sudo multipass transfer /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa bastion:/home/ubuntu/.ssh/id_rsa
    sudo multipass transfer /usr/local/bin/kubectl bastion:/home/ubuntu/kubectl
    sudo multipass exec bastion -- chmod +x /tmp/bastion.sh
    sudo multipass exec bastion -- sudo bash /tmp/bastion.sh
  fi
fi
