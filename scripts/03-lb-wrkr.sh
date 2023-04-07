#!/bin/bash

## Create Worker LB
if ! multipass list | grep -q "lb-wrkr"; then
  echo "Creating Worker Load Balancer: lb-wrkr"
  multipass launch -n lb-wrkr -c 2 -m 2G -d 10G
  multipass transfer base.sh lb-wrkr:/tmp/base.sh
  multipass exec lb-wrkr -- chmod +x /tmp/base.sh
  multipass exec lb-wrkr -- sudo bash /tmp/base.sh
fi