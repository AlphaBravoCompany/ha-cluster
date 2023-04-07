#!/bin/bash

## Create Control-Plane LB
if ! multipass list | grep -q "lb-cp"; then
  echo "Creating Control-Plane Load Balancer: lb-cp"
  multipass launch -n lb-cp -c 2 -m 2G -d 10G
  multipass transfer base.sh lb-cp:/tmp/base.sh
  multipass exec lb-cp -- chmod +x /tmp/base.sh
  multipass exec lb-cp -- sudo bash /tmp/base.sh
fi