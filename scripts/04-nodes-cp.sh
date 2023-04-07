#!/bin/bash

## Create 3 Control-Plane Nodes
for i in {1..3}; do
  if ! multipass list | grep -q "cp-$i"; then
    echo "Creating Control-Plane Node: cp-$i"
    multipass launch -n cp-$i -c 2 -m 4G -d 20G
    multipass transfer base.sh lb-cp:/tmp/base.sh
    multipass exec lb-cp -- chmod +x /tmp/base.sh
    multipass exec lb-cp -- sudo bash /tmp/base.sh
  fi
done