# AlphaBravo Baremetal HA Cluster

This repository contains scripts and configurations for setting up a highly available RKE2 Kubernetes environment on a bare metal server using Multipass virtual environment installation.

## Server Requirements

- Baremetal Server running Ubuntu
- Ability to run KVM on the baremetal server
- 16 CPU
- 22GB RAM
- 200GB Disk

## Overview

- The `create_nodes.sh` script creates the Node infrastructure
- Installs all necessary dependencies for running a Multipass virtual environment installation
- Creates 3 control plane nodes, 3 worker/agent nodes, and 2 load balancers
- Configures the load balancers with HAproxy
  - `lb-cp` load balancer using ports 6443 and 9345 for the control plane nodes
  - `lb-wrkr` load balancer using ports 80 and 443 to the worker/agent nodes
- Designed for deploying a RKE2 Kubernetes environment on a bare metal server

## Scripts

The `scripts` folder contains the following scripts:

- `base.sh`: Installs all common items across all nodes
- `lb.sh`: Installs the requirements for HAproxy on the load balancer nodes

## Config Directory

The `config` directory contains:

- A placeholder text file
- Used to store dynamically generated HAproxy configs for the `lb-cp` and `lb-wrkr` nodes
- In the future, other possible dynamically generated configs

## Usage

To create the Node infrastructure and set up the environment, simply run the `create_nodes.sh` script:

```bash
## The installation will take several minutes to complete
sudo ./create_nodes.sh

## Take down the environment
sudo ./destroy_nodes.sh
```