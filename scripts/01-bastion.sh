#!/bin/bash

## Create Control-Plane LB
if ! multipass list | grep -q "bastion"; then
  echo "Creating Bastion Server: bastion"
  multipass launch -n bastion -c 2 -m 2G -d 10G
  multipass transfer base.sh lb-cp:/tmp/base.sh
  multipass exec bastion -- chmod +x /tmp/base.sh
  multipass exec bastion -- sudo bash /tmp/base.sh
fi