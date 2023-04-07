# AlphaBravo Baremetal HA Cluster

This repository contains scripts and configurations for setting up a highly available RKE2 Kubernetes environment on a bare metal server using Multipass virtual environment installation.

## Server Requirements

- Baremetal Server running Ubuntu
- Ability to run KVM on the baremetal server
- 16 CPU
- 22GB RAM
- 200GB Disk

## Usage

To create the Node infrastructure and set up the environment, simply run the `create_nodes.sh` script:

```bash
## Deploy an infrastructure using Terraform
cd terraform
terraform init
terraform plan
terraform apply

## Once Terraform has completed, run Ansible
## This will take about 5-10 minutes to complete
cd ../ansible
./configure -k ~/.ssh/<ssh_key>

## SSH to the server
## The IP addresses can be found in the ansible/inventory.txt file
ssh -i ~/.ssh/<ssh_key> ubuntu@<ip_address>

## Watch the deployment
watch -n5 sudo multipass list

## Take down the HA cluster
sudo ./destroy_nodes.sh

## Destroy the infrastructure
terraform destroy
```