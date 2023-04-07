#!/bin/bash

## Configure Worker LB
if multipass list | grep -q "lb-wrkr"; then
  echo "Configuring Worker Load Balancer: lb-wrkr"
  multipass transfer haproxy-wrkr.cfg lb-wrkr:/tmp/haproxy.cfg
  multipass transfer lb.sh lb-wrkr:/tmp/lb.sh
  multipass exec lb-wrkr -- chmod +x /tmp/lb.sh
  multipass exec lb-wrkr -- sudo bash /tmp/lb.sh
fi