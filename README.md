# AlphaBravo Baremetal HA Cluster

This repository contains scripts and configurations for setting up a highly available RKE2 Kubernetes environment on a bare metal server using Multipass virtual environment installation.

## Server Requirements

- Baremetal Server running Ubuntu
- Ability to run KVM on the baremetal server
- 16 CPU
- 22GB RAM
- 250GB Disk

## Usage

To create the Node infrastructure and set up the environment, run the following:

```bash
## Deploy an infrastructure using Terraform
cd terraform
cp terraform.tfvars.dist terraform.tfvars
## Add your AWS credentials and SSH key info
vim terraform.tfvars
terraform init
terraform plan
terraform apply

## Recommended to wait 5 mins before running Ansible
## Scripts will take about 5-10 minutes to complete
cd ../ansible
./configure -k ~/.ssh/<ssh_key>

## SSH to the server
## The IP addresses can be found in the ansible/inventory.txt file
ssh -i ~/.ssh/<ssh_key> ubuntu@<ip_address>

## Watch the deployment on the Baremetal server
watch -n5 sudo multipass list

## Take down the HA cluster
sudo ./destroy_nodes.sh

## Destroy the infrastructure
terraform destroy
```