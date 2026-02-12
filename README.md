# Terra-Anis-1: Automated Azure Multi-Region Network

Automated deployment of a multi-region Azure network using **Terraform** and **Ansible**. One `terraform apply` builds the entire infrastructure — 3 VNets, hub-and-spoke peering, private DNS, and VMs in every subnet — then Ansible configures them all from a central control node.

Built as a showcase for automated networking in Azure. The goal is a plug-and-play network that can be extended with NVAs, web proxies, firewalls, or any other networking components.

## Architecture

```
                        ┌─────────────────────────────────────┐
                        │     CoreServicesVnet (East US)       │
                        │           10.20.0.0/16               │
                        │                                      │
                        │  SharedServices  ── Ansible-VM-01    │
                        │  Database        ── DatabaseServer-01│
                        │  PublicWeb       ── WebServer-01     │
                        └──────────┬──────────┬────────────────┘
                                   │          │
                          Peering  │          │  Peering
                                   │          │
          ┌────────────────────────┘          └────────────────────────┐
          │                                                           │
┌─────────┴───────────────────┐                     ┌─────────────────┴─────────┐
│  ManufacturingVnet          │                     │  ResearchVnet             │
│  (West Europe)              │                     │  (Southeast Asia)         │
│  10.30.0.0/16               │                     │  10.40.0.0/16             │
│                             │                     │                           │
│  MfgSystems ── MfgServer-01 │                     │  Research ── ResearchSvr  │
│  Sensor1 ── SensorServer-01 │                     └───────────────────────────┘
│  Sensor2 ── SensorServer-02 │
│  Sensor3 ── SensorServer-03 │
└─────────────────────────────┘
```

**Private DNS Zone:** `azure.poms.tech` — all VMs auto-register and are reachable by hostname.

## Prerequisites

- Azure CLI logged in (`az login`)
- Terraform installed
- SSH keypair in `keys/ansible_rsa` and `keys/ansible_rsa.pub`

## Before You Deploy: Update the NSG

Update the NSG rule in `nsg.tf` with your real public IP address to allow SSH access to the Ansible VM:

```hcl
source_address_prefix = "YOUR.PUBLIC.IP/32"
```

You can find your public IP by running `curl ifconfig.me`.

## Step 1: Deploy the Infrastructure

```bash
terraform init
terraform apply -auto-approve
```

This single command:
1. Creates 3 VNets with hub-and-spoke peering
2. Deploys the Ansible control VM with cloud-init (installs Ansible, az CLI, generates SSH keys, uploads pubkey to Key Vault)
3. Waits for cloud-init to complete before proceeding
4. Reads the SSH public key from Key Vault and deploys 7 compute VMs across all subnets
5. Auto-registers every VM in the Ansible inventory using DNS names

## Step 2: SSH to the Ansible VM

The SSH command is shown in the Terraform output:

```bash
ssh -i keys/ansible_rsa azure_user@<ansible_vm_public_ip>
```

## Step 3: Run the Ansible Playbook

On the Ansible VM:

```bash
cd ~/ansible
ansible-playbook deploy-nginx.yml
```

This installs nginx and net-tools on all 7 compute VMs and deploys a custom web page showing the server name and IP.

## Step 4: Test Network Connectivity

From the Ansible VM, curl each server by DNS name to prove the multi-region network is up:

```bash
# Core Services VNet (East US)
curl webserver-01.azure.poms.tech
curl databaseserver-01.azure.poms.tech

# Manufacturing VNet (West Europe)
curl mfgserver-01.azure.poms.tech
curl sensorserver-01.azure.poms.tech
curl sensorserver-02.azure.poms.tech
curl sensorserver-03.azure.poms.tech

# Research VNet (Southeast Asia)
curl researchserver-01.azure.poms.tech
```

Each response will show the server hostname and private IP, confirming connectivity across all three regions via VNet peering.

## Step 5: Tear Down

```bash
terraform destroy -auto-approve
```

## A Note on Structure

Having all compute resources in a single `compute.tf` is not best practice for production. In a real environment you would separate resources by function or use Terraform modules. Here it is done deliberately for ease of deployment — the goal is a plug-and-play network to test Azure networking concepts (NVAs, web proxies, firewalls, load balancers, etc.) with minimal setup. The focus of this project is demonstrating automated networking and Ansible configuration, not Terraform code structure.

## Technologies

- **Terraform** — Infrastructure as Code
- **Ansible** — Configuration Management
- **Azure Key Vault** — Secure SSH key exchange between VMs
- **Azure Private DNS** — Hostname resolution across VNets
- **Cloud-Init** — VM bootstrapping

---

*Automated DevOps deployment by Adrian Baker* — [aibots.poms.tech](https://aibots.poms.tech)
