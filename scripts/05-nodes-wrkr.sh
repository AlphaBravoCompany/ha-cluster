#!/bin/bash

## Create 3 Worker Nodes
for i in {1..3}; do
  if ! multipass list | grep -q "wrkr-$i"; then
    echo "Creating Worker Node: wrkr-$i"
    multipass launch -n wrkr-$i -c 2 -m 2G -d 20G
    multipass transfer base.sh lb-cp:/tmp/base.sh
    multipass exec lb-cp -- chmod +x /tmp/base.sh
    multipass exec lb-cp -- sudo bash /tmp/base.sh
  fi
done