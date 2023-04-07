#!/bin/bash

## Create Control-Plane LB
if ! multipass list | grep -q "bastion"; then
  echo "Creating Bastion Server: bastion"
  multipass launch -n bastion -c 2 -m 2G -d 10G
  multipass transfer base.sh lb-cp:/tmp/base.sh
  multipass exec lb-cp -- chmod +x /tmp/base.sh
  multipass exec lb-cp -- sudo bash /tmp/base.sh
fi