#!/bin/bash

## Check to see if this is an Ubuntu environment
if ! grep -q "ID=ubuntu" /etc/os-release; then
  echo "Not running on Ubuntu. Exiting."
  exit 1
fi

## Check if the script is running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo privilages."
  exit 1
fi

## Install Multipass on Ubuntu
snap install multipass --classic

## Install Deps
apt update -qq >/dev/null 2>&1
apt install -qq -y jq >/dev/null 2>&1
curl -sSLO "https://dl.k8s.io/release/$(curl -L -sS https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
mv kubectl /usr/bin/kubectl
chmod +x /usr/bin/kubectl

## Create Control-Plane LB
if ! multipass list | grep -q "lb-cp"; then
  echo "Creating Control-Plane Load Balancer: lb-cp"
  multipass launch -n lb-cp -c 2 -m 2G -d 10G
  multipass transfer scripts/base.sh lb-cp:/tmp/base.sh
  multipass exec lb-cp -- chmod +x /tmp/base.sh
  multipass exec lb-cp -- sudo bash /tmp/base.sh
fi

## Create Worker LB
if ! multipass list | grep -q "lb-wrkr"; then
  echo "Creating Worker Load Balancer: lb-wrkr"
  multipass launch -n lb-wrkr -c 2 -m 2G -d 10G
  multipass transfer scripts/base.sh lb-wrkr:/tmp/base.sh
  multipass exec lb-cp -- chmod +x /tmp/base.sh
  multipass exec lb-cp -- sudo bash /tmp/base.sh
fi

## Create 3 Control-Plane Nodes
for i in {1..3}; do
  if ! multipass list | grep -q "cp-$i"; then
    echo "Creating Control-Plane Node: cp-$i"
    multipass launch -n cp-$i -c 2 -m 4G -d 20G
    multipass transfer scripts/base.sh cp-$i:/tmp/base.sh
    multipass exec lb-cp -- chmod +x /tmp/base.sh
    multipass exec lb-cp -- sudo bash /tmp/base.sh
  fi
done

## Create 3 Agent Nodes
for i in {1..3}; do
  if ! multipass list | grep -q "wrkr-$i"; then
    echo "Creating Worker Node: wrkr-$i"
    multipass launch -n wrkr-$i -c 2 -m 2G -d 20G
    multipass transfer scripts/base.sh cp-$i:/tmp/base.sh
    multipass exec lb-cp -- chmod +x /tmp/base.sh
    multipass exec lb-cp -- sudo bash /tmp/base.sh
  fi
done

## Declare an associative array to store node IP addresses
declare -A node_ips

## Get the list of node names
node_names=$(multipass list --format csv | tail -n +2 | cut -d, -f1)

## Iterate through the node names and store their IP addresses in the associative array
for name in $node_names; do
  ip_address=$(multipass info $name --format json | jq -r '.info."'"$name"'".ipv4[0]')
  node_ips["$name"]="$ip_address"
done

## Show the RKE2 config.yaml
cat << EOF > rke2-install.txt

## -----
## RKE2 Installation Instructions
## -----
## Install the rke2-server service
curl -sfL https://get.rke2.io | sudo sh -
sudo mkdir -p /etc/rancher/rke2/
sudo vim /etc/rancher/rke2/config.yaml

## Install rke2-agent service
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh -
sudo mkdir -p /etc/rancher/rke2/
sudo vim /etc/rancher/rke2/config.yaml

## Systemctl Server commands
sudo systemctl daemon-reload
sudo systemctl enable --now rke2-server

## Systemctl Agent commands
sudo systemctl daemon-reload
sudo systemctl enable --now rke2-agent

## -----
## Primary Server config.yaml
## -----
token: QMXrt0w8BWFO5Z1D0zLm5VKq5HF74Yl8EE9IR72YUqUtaeW4Xix1tCgdzJU0meE5
write-kubeconfig-mode: "0644"
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
tls-san:
  - demo.ablabs.io
  - ${node_ips[cp-1]}
  - ${node_ips[cp-2]}
  - ${node_ips[cp-3]}
  - ${node_ips[lb-cp]}
  - ${node_ips[lb-wrkr]}

## -----
## Secondary Server config.yaml
## -----
server: https://${node_ips[lb-cp]}:9345
token: QMXrt0w8BWFO5Z1D0zLm5VKq5HF74Yl8EE9IR72YUqUtaeW4Xix1tCgdzJU0meE5
write-kubeconfig-mode: "0644"
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
tls-san:
  - demo.ablabs.io
  - ${node_ips[cp-1]}
  - ${node_ips[cp-2]}
  - ${node_ips[cp-3]}
  - ${node_ips[lb-cp]}
  - ${node_ips[lb-wrkr]}

## -----
## Agent config.yaml
## -----
server: https://${node_ips[lb-cp]}:9345
token: QMXrt0w8BWFO5Z1D0zLm5VKq5HF74Yl8EE9IR72YUqUtaeW4Xix1tCgdzJU0meE5
write-kubeconfig-mode: "0644"
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
tls-san:
  - demo.ablabs.io
  - ${node_ips[cp-1]}
  - ${node_ips[lb-cp]}
  - ${node_ips[lb-wrkr]}


EOF

## Create the Control-Plane HAProxy config file
cat << EOF > config/haproxy-cp.cfg
global
  stats socket /var/run/haproxy/haproxy.sock mode 0600 level admin
backend controlplane-6443
  server main1 ${node_ips[cp-1]}:6443 check
  server main2 ${node_ips[cp-2]}:6443 check
  server main3 ${node_ips[cp-3]}:6443 check
backend controlplane-9345
  server main1 ${node_ips[cp-1]}:9345 check
  server main2 ${node_ips[cp-2]}:9345 check
  server main3 ${node_ips[cp-3]}:9345 check
frontend k8s-admin
  bind *:6443
  use_backend controlplane-6443
frontend k8s-register
  bind *:9345
  use_backend controlplane-9345
listen stats
  bind *:8404
  stats enable
  stats uri /monitor
EOF

## Create the Worker HAProxy config file
cat << EOF > config/haproxy-wrkr.cfg
global
  stats socket /var/run/haproxy/haproxy.sock mode 0600 level admin
backend wrk-http
  server main1 ${node_ips[wrkr-1]}:80 check
  server main2 ${node_ips[wrkr-2]}:80 check
  server main3 ${node_ips[wrkr-3]}:80 check
backend wrk-https
  server main1 ${node_ips[wrkr-1]}:443 check
  server main2 ${node_ips[wrkr-2]}:443 check
  server main3 ${node_ips[wrkr-3]}:443 check
frontend http
  bind *:80
  use_backend wrk-http
frontend https
  bind *:443
  use_backend wrk-https
listen stats
  bind *:8405
  stats enable
  stats uri /monitor
EOF

## Configure Control-Plane LB
if multipass list | grep -q "lb-cp"; then
  echo "Configuring Control-Plane Load Balancer: lb-cp"
  multipass transfer config/haproxy-cp.cfg lb-cp:/tmp/haproxy.cfg
  multipass transfer scripts/lb.sh lb-cp:/tmp/lb.sh
  multipass exec lb-cp -- chmod +x /tmp/lb.sh
  multipass exec lb-cp -- sudo bash /tmp/lb.sh
fi

## Configure Worker LB
if multipass list | grep -q "lb-wrkr"; then
  echo "Configuring Worker Load Balancer: lb-wrkr"
  multipass transfer config/haproxy-wrkr.cfg lb-wrkr:/tmp/haproxy.cfg
  multipass transfer scripts/lb.sh lb-wrkr:/tmp/lb.sh
  multipass exec lb-wrkr -- chmod +x /tmp/lb.sh
  multipass exec lb-wrkr -- sudo bash /tmp/lb.sh
fi

## Run the HAProxy UI
cat << EOF

To run the UI for the load balancer, log into lb-cp or lb-wrkr:
sudo multipass shell lb-cp
sudo hatop -s /var/run/haproxy/haproxy.sock

EOF