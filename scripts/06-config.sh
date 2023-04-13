#!/bin/bash

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

1. Open two terminals side by side in your VSCode editor.
2. Follow the instructions below.

## =====
## Control-Plane Load Balancer, terminal #1
## =====
## We will be using the CP LB to view the control-plane nodes coming online
## We will also be able to view ingress traffic through the LB to the nodes


1. From terminal #1, login to the Control-Place Load Balancer
-----
sudo multipass shell lb-cp

2. Run the command to view the CLI UI for HAproxy.
-----
sudo hatop -s /var/run/haproxy/haproxy.sock

3. Watch this interface to see the Control-Plane nodes come online.
-----



## =====
## Bastion Node, terminal #2
## =====
## We will be using the Bastion node as the centralized point to manage all nodes.
## The bastion prevents exposure of the HA RKE2 cluster to the world.

1. From terminal #2, login to the Bastion node
-----
sudo multipass shell bastion


2. SSH to the CP-1 Node from the Bastion Node
-----
ssh cp-1


3. Install RKE2 on CP-1 as the primary control-plane server
-----
curl -sfL https://get.rke2.io | sudo sh -


4. Create the directory to store the configuration for RKE2
-----
sudo mkdir -p /etc/rancher/rke2/


5. Edit the config.yaml file
-----
sudo vim /etc/rancher/rke2/config.yaml


6. Paste the following into the /etc/rancher/rke2/config.yaml file
-----
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


7. Save the configuration
-----
:wq (ENTER)


8. Reload the Systemctl daemon and enable the rke2-server. It will take a few moments to come online.
-----
sudo systemctl daemon-reload
sudo systemctl enable --now rke2-server


9. Verify the cluster has come online
-----
sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes


## =====
## Control-Plane Load Balancer, terminal #1
## =====
## Watch the interface in the HAproxy load balancer UI
## First to come online will be controlplane-9345, main1
## Next to come online will be controlplane-6443, main1
## When both of these show UP, you can move on to the next step



## =====
## Bastion Node, terminal #2
## =====
## Once the first control-plane node is online, we can add additional nodes to the cluster
## Using the Bastion node, we will switch from cp-1 to cp-2 and so forth

1. From terminal #2, exit the cp-1 server back to the Bastion node command line
-----
exit

2. SSH to the CP-2 Node from the Bastion Node
-----
ssh cp-2


3. Install RKE2 on CP-2 as the first secondary control-plane server
-----
curl -sfL https://get.rke2.io | sudo sh -


4. Create the directory to store the configuration for RKE2
-----
sudo mkdir -p /etc/rancher/rke2/


5. Edit the config.yaml file
-----
sudo vim /etc/rancher/rke2/config.yaml


6. Paste the following into the /etc/rancher/rke2/config.yaml file. Note the addition of the "server" parameter.
-----
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


7. Save the configuration
-----
:wq (ENTER)


8. Reload the Systemctl daemon and enable the rke2-server. It will take a few moments to come online.
-----
sudo systemctl daemon-reload
sudo systemctl enable --now rke2-server


9. Verify the cluster has come online
-----
sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes


10. Repeat steps 1-7 for the remaining CP-3 server node, changing cp-2 to cp-3.
-----


## =====
## Control-Plane Load Balancer, terminal #1
## =====
## Watch the interface in the HAproxy load balancer UI
## First to come online will be controlplane-9345, main3
## Next to come online will be controlplane-6443, main3
## When both of these show UP, you will have successfully deployed the HA control-plane



## =====
## Bastion Node, terminal #2
## =====
## Now, add the worker nodes to the cluster. There are 3 worker nodes: wrkr-1, wrkr-2, wrkr-3
## Repeat the steps below for each of the worker nodes to bring them online.

1. From terminal #2, exit the cp-3 server back to the Bastion node command line
-----
exit

2. SSH to the WRKR-1 Node from the Bastion Node
-----
ssh wrkr-1


3. Install RKE2 on WRKR-1. Note the command is different from earlier.
-----
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh -


4. Create the directory to store the configuration for RKE2
-----
sudo mkdir -p /etc/rancher/rke2/


5. Edit the config.yaml file
-----
sudo vim /etc/rancher/rke2/config.yaml


6. Paste the following into the /etc/rancher/rke2/config.yaml file. Note the difference in the config.
-----
server: https://${node_ips[lb-cp]}:9345
token: QMXrt0w8BWFO5Z1D0zLm5VKq5HF74Yl8EE9IR72YUqUtaeW4Xix1tCgdzJU0meE5


7. Save the configuration
-----
:wq (ENTER)


8. Reload the Systemctl daemon and enable the rke2-agent. It will take a few moments to come online.
-----
sudo systemctl daemon-reload
sudo systemctl enable --now rke2-agent


9. Verify the worker node has come online
-----
exit
ssh cp-1
sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes


10. Repeat steps 1-7 for the remaining worker nodes.
-----

11. Once the worker nodes have successfully deployed, copy the K8s config to the Bastion.
-----
exit (to the Bastion node)
mkdir ~/.kube
chmod 755 ~/.kube
scp cp-1:/etc/rancher/rke2/rke2.yaml ~/.kube/config
chmod 600 ~/.kube/config
NODE_IP="${node_ips[lb-cp]}" sed -i "s/127\.0\.0\.1/${NODE_IP}/g" ~/kube/config

12. Run kubectl from the Bastion to control the K8s cluster
-----
kubectl get nodes
kubectl get pods -A


EOF

## Show the RKE2 config.yaml
cat << EOF > rke2-install.mdtl

1. Open two terminals side by side in your VSCode editor.
2. Follow the instructions below.

---
## Control-Plane Load Balancer, terminal #1
---

- We will be using the CP LB to view the control-plane nodes coming online. 
- We will also be able to view ingress traffic through the LB to the nodes.


1. From terminal #1, login to the Control-Place Load Balancer

`sudo multipass shell lb-cp` {{ execute "T1"}}

2. Run the command to view the CLI UI for HAproxy.

`sudo hatop -s /var/run/haproxy/haproxy.sock` {{ execute "T1"}}

3. Watch this interface to see the Control-Plane nodes come online.


---
## Bastion Node, terminal #2
---

- We will be using the Bastion node as the centralized point to manage all nodes.
- The bastion prevents exposure of the HA RKE2 cluster to the world.

1. From terminal #2, login to the Bastion node

`sudo multipass shell bastion` {{ execute "T2"}}


2. SSH to the CP-1 Node from the Bastion Node

`ssh cp-1` {{ execute "T2"}}


3. Install RKE2 on CP-1 as the primary control-plane server

`curl -sfL https://get.rke2.io | sudo sh -` {{ execute "T2"}}


4. Create the directory to store the configuration for RKE2

`sudo mkdir -p /etc/rancher/rke2/` {{ execute "T2"}}


5. Edit the config.yaml file (using the text in the next step).

If you are not familiar with vim, to edit, click the "i" key on your keyboard. 

To save, click the "ESC" key, then type ":wq" and hit "ENTER".

`sudo vim /etc/rancher/rke2/config.yaml` {{ execute "T2"}}


6. Paste the following into the /etc/rancher/rke2/config.yaml file. 

To copy, highlight the below text and git "CTRL + C".

```
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
```


7. Reload the Systemctl daemon and enable the rke2-server. It will take a few moments to come online.

`sudo systemctl daemon-reload` {{ execute "T2"}}

`sudo systemctl enable --now rke2-server` {{ execute "T2"}}


8. Verify the cluster has come online

`sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes` {{ execute "T2"}}


---
## Control-Plane Load Balancer, terminal #1
---

- Watch the interface in the HAproxy load balancer UI.
- First to come online will be controlplane-9345, main1.
- Next to come online will be controlplane-6443, main1.
- When both of these show UP, you can move on to the next step.


---
## Bastion Node, terminal #2
---

- Once the first control-plane node is online, we can add additional nodes to the cluster
- Using the Bastion node, we will switch from cp-1 to cp-2 and so forth

1. From terminal #2, exit the cp-1 server back to the Bastion node command line

`exit` {{ execute "T2"}}

2. SSH to the CP-2 Node from the Bastion Node

`ssh cp-2` {{ execute "T2"}}


3. Install RKE2 on CP-2 as the first secondary control-plane server

`curl -sfL https://get.rke2.io | sudo sh -` {{ execute "T2"}}


4. Create the directory to store the configuration for RKE2

`sudo mkdir -p /etc/rancher/rke2/` {{ execute "T2"}}


3. Edit the config.yaml file (using the text in the next step).

`sudo vim /etc/rancher/rke2/config.yaml` {{ execute "T2"}}


4. Paste the following into the /etc/rancher/rke2/config.yaml file. Note the addition of the "server" parameter.

```
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
```

6. Reload the Systemctl daemon and enable the rke2-server. It will take a few moments to come online.

`sudo systemctl daemon-reload` {{ execute "T2"}}

`sudo systemctl enable --now rke2-server` {{ execute "T2"}}

7. Verify the cluster has come online

`sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes` {{ execute "T2"}}

8. Repeat steps 1-7 for the remaining CP-3 server node, changing step 2 from `ssh cp-2` to `ssh cp-3`.


---
## Control-Plane Load Balancer, terminal #1
---

- Watch the interface in the HAproxy load balancer UI
- First to come online will be controlplane-9345, main3
- Next to come online will be controlplane-6443, main3
- When both of these show UP, you will have successfully deployed the HA control-plane

---
## Bastion Node, terminal #2
---

- Now, add the worker nodes to the cluster. There are 3 worker nodes: wrkr-1, wrkr-2, wrkr-3
- Repeat the steps below for each of the worker nodes to bring them online.

1. From terminal #2, exit the cp-3 server back to the Bastion node command line

`exit` {{ execute "T2"}}

2. SSH to the WRKR-1 Node from the Bastion Node

`ssh wrkr-1` {{ execute "T2"}}


3. Install RKE2 on WRKR-1. Note the command is different from earlier.

`curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh -` {{ execute "T2"}}


4. Create the directory to store the configuration for RKE2

`sudo mkdir -p /etc/rancher/rke2/` {{ execute "T2"}}


5. Edit the config.yaml file (using the text in the next step).

`sudo vim /etc/rancher/rke2/config.yaml` {{ execute "T2"}}


6. Paste the following into the /etc/rancher/rke2/config.yaml file. Note the difference in the worker config from what we saw on the control plane nodes.

```
server: https://${node_ips[lb-cp]}:9345
token: QMXrt0w8BWFO5Z1D0zLm5VKq5HF74Yl8EE9IR72YUqUtaeW4Xix1tCgdzJU0meE5
```

7. Reload the Systemctl daemon and enable the rke2-agent. It will take a few moments to come online.

`sudo systemctl daemon-reload` {{ execute "T2"}}

`sudo systemctl enable --now rke2-agent` {{ execute "T2"}}


8. Verify the worker node has come online

`Ctrl + C` {{ interrupt "T1" }}

`ssh cp-1` {{ execute "T1"}}

`sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes` {{ execute "T1"}}


8. Repeat steps 1-7 for the remaining worker nodes.

9. Once the worker nodes have successfully deployed, copy the K8s config to the Bastion.

First, exit the cp-1 server back to the Bastion node command line.

`exit` {{ execute "T2"}}

`mkdir ~/.kube` {{ execute "T2"}}

`chmod 755 ~/.kube` {{ execute "T2"}}

`scp cp-1:/etc/rancher/rke2/rke2.yaml ~/.kube/config` {{ execute "T2"}}

`chmod 600 ~/.kube/config` {{ execute "T2"}}

`NODE_IP="${node_ips[lb-cp]}" sed -i "s/127\.0\.0\.1/${NODE_IP}/g" ~/kube/config` {{ execute "T2"}}

10. Run kubectl from the Bastion to control the K8s cluster

`kubectl get nodes` {{ execute "T2"}}

`kubectl get pods -A` {{ execute "T2"}}


EOF

## Create the Control-Plane HAProxy config file
cat << EOF > haproxy-cp.cfg
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
cat << EOF > haproxy-wrkr.cfg
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