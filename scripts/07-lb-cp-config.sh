#!/bin/bash

## Configure Control-Plane LB
if multipass list | grep -q "lb-cp"; then
  echo "Configuring Control-Plane Load Balancer: lb-cp"
  multipass transfer haproxy-cp.cfg lb-cp:/tmp/haproxy.cfg
  multipass transfer lb.sh lb-cp:/tmp/lb.sh
  multipass exec lb-cp -- chmod +x /tmp/lb.sh
  multipass exec lb-cp -- sudo bash /tmp/lb.sh
fi