# Terra-Anis-1: Automated Azure Multi-Region Network

Automated deployment of a multi-region Azure network using **Terraform** and **Ansible**. One `terraform apply` builds the entire infrastructure — 3 VNets, hub-and-spoke peering, private DNS, NAT gateways, an Application Gateway, and VMs in every subnet — then Ansible configures them all from a central control node.

Built as a showcase for automated networking in Azure. The goal is a plug-and-play network that can be extended with NVAs, web proxies, firewalls, load balancers, or any other networking components.

## Architecture

```
                        ┌─────────────────────────────────────────┐
                        │      CoreServicesVnet (East US)          │
                        │            10.20.0.0/16                  │
                        │        NAT GW: core-nat-gateway          │
                        │                                          │
                        │  AppGateway  ── lab-app-gateway ──► PIP │◄── Internet
                        │                (lab-appgw.eastus         │    /web → WebServer-01
                        │                 .cloudapp.azure.com)     │    /mfg → MfgServer-01
                        │                                          │
                        │  SharedServices  ── Ansible-VM-01        │
                        │  Database        ── DatabaseServer-01    │
                        │  PublicWeb       ── WebServer-01         │
                        │                                          │
                        │  NSG: allow-ssh-from-home (port 22)      │
                        └──────────┬──────────┬────────────────────┘
                                   │          │
                          Peering  │          │  Peering
                                   │          │
          ┌────────────────────────┘          └────────────────────────┐
          │                                                            │
┌─────────┴───────────────────┐                     ┌─────────────────┴─────────┐
│  ManufacturingVnet          │                     │  ResearchVnet             │
│  (West Europe)              │                     │  (Southeast Asia)         │
│  10.30.0.0/16               │                     │  10.40.0.0/16             │
│  NAT GW: mfg-nat-gateway    │                     │  NAT GW: research-nat-gw  │
│                             │                     │                           │
│  MfgSystems ── MfgServer-01 │                     │  Research ── ResearchSvr  │
│  Sensor1 ── SensorServer-01 │                     └───────────────────────────┘
│  Sensor2 ── SensorServer-02 │
│  Sensor3 ── SensorServer-03 │
└─────────────────────────────┘
```

**Private DNS Zone:** `azure.poms.tech` — all VMs auto-register and are reachable by hostname.

## Network Security

An NSG (`ansible-vm-nsg`) is attached to the Ansible VM NIC, allowing inbound SSH (port 22) only from a specific IP address. Update `nsg.tf` with your public IP before deploying. All other VMs have no public IP and are only reachable internally via the hub-and-spoke peering.

## NAT Gateways

Each VNet has its own NAT gateway for outbound internet access (NAT gateways are regional resources):

| VNet | NAT Gateway | Subnets |
|------|-------------|---------|
| CoreServicesVnet (East US) | `core-nat-gateway` | SharedServices, PublicWebService, Database |
| ManufacturingVnet (West Europe) | `mfg-nat-gateway` | ManufacturingSystems, Sensor1, Sensor2, Sensor3 |
| ResearchVnet (Southeast Asia) | `research-nat-gateway` | ResearchSystem |

## Application Gateway

A Standard_v2 Application Gateway (`lab-app-gateway`) sits in its own dedicated subnet (`AppGatewaySubnet` — 10.20.50.0/24) in CoreServicesVnet. It has a static public IP with a stable Azure DNS label.

**Stable DNS:** `lab-appgw.eastus.cloudapp.azure.com`

### Path-Based Routing (by IP)

| URL | Backend |
|-----|---------|
| `http://<ip>/web/` | WebServer-01 (East US) |
| `http://<ip>/mfg/` | MfgServer-01 (West Europe, via VNet peering) |
| `http://<ip>/` | WebServer-01 (default) |

URL rewrite rules strip the `/web` and `/mfg` prefixes before forwarding to the backend, so nginx always receives requests at `/`.

### Host-Based Routing (by DNS)

| Hostname | Backend |
|----------|---------|
| `web.poms.tech` | WebServer-01 |
| `mfg.poms.tech` | MfgServer-01 |

In Hostinger (or any DNS provider), create two CNAME records pointing to `lab-appgw.eastus.cloudapp.azure.com`. The Azure DNS label is stable across redeploys so the CNAMEs never need updating.

## Internal Load Balancer *(optional — lb.tf.off)*

A Standard Internal Load Balancer sits in PublicWebServiceSubnet and distributes HTTP traffic across WebServer-01 and DatabaseServer-01. Registered in private DNS as `loadbalancer.azure.poms.tech`. Enable by renaming `lb.tf.off` → `lb.tf`.

## Traffic Manager + Web Apps *(optional — traffic-manager.tf.off / web-apps.tf.off)*

Performance-based global routing across Linux Web Apps in 3 regions (Central US, West Europe, Southeast Asia). Enable by renaming both `.off` files.

## Prerequisites

- Azure CLI logged in (`az login`)
- Terraform installed
- SSH keypair in `keys/ansible_rsa` and `keys/ansible_rsa.pub`

## Before You Deploy: Update the NSG

Update the NSG rule in `nsg.tf` with your real public IP address:

```hcl
source_address_prefix = "YOUR.PUBLIC.IP/32"
```

Find your public IP with `curl ifconfig.me`.

## Step 1: Deploy the Infrastructure

```bash
terraform init
terraform apply -auto-approve
```

This single command:
1. Creates 3 VNets with hub-and-spoke peering
2. Deploys the Ansible control VM with cloud-init (installs Ansible, az CLI, generates SSH keys, uploads pubkey to Key Vault)
3. Waits for cloud-init to complete before proceeding
4. Reads the SSH public key from Key Vault and deploys compute VMs across all subnets
5. Auto-registers every VM in the Ansible inventory using DNS names
6. Deploys the Application Gateway with path and host-based routing rules

## Step 2: SSH to the Ansible VM

```bash
ssh -i keys/ansible_rsa azure_user@<ansible_vm_public_ip>
```

The SSH command is shown in the Terraform output as `ansible_vm_ssh_command`.

## Step 3: Run the Ansible Playbook

On the Ansible VM:

```bash
cd ~/ansible
ansible-playbook deploy-nginx.yml
```

This installs nginx and net-tools on all compute VMs and deploys a custom web page showing the server name and IP.

## Step 4: Test the Application Gateway

Path-based routing (by IP):
```bash
curl http://<appgw_public_ip>/web/    # → WebServer-01
curl http://<appgw_public_ip>/mfg/    # → MfgServer-01
```

Host-based routing (simulated, before DNS is set):
```bash
curl -H "Host: web.poms.tech" http://<appgw_public_ip>/    # → WebServer-01
curl -H "Host: mfg.poms.tech" http://<appgw_public_ip>/    # → MfgServer-01
```

The App Gateway public IP and FQDN are shown in Terraform outputs as `appgw_public_ip_address` and `appgw_fqdn`.

## Step 5: Test Network Connectivity

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

Each response shows the server hostname and private IP, confirming connectivity across all three regions via VNet peering.

## Step 6: Tear Down

```bash
terraform destroy -auto-approve
```

## A Note on Structure

Having all compute resources in a single `compute.tf` is not best practice for production. In a real environment you would separate resources by function or use Terraform modules. Here it is done deliberately for ease of deployment — the goal is a plug-and-play network to test Azure networking concepts (NVAs, web proxies, firewalls, load balancers, App Gateway, etc.) with minimal setup.

## Technologies

- **Terraform** — Infrastructure as Code
- **Ansible** — Configuration Management
- **Azure Key Vault** — Secure SSH key exchange between VMs
- **Azure Private DNS** — Hostname resolution across VNets
- **Azure NAT Gateway** — Outbound internet for all subnets across 3 regions
- **Azure Application Gateway** — Path-based and host-based HTTP routing with URL rewrite rules
- **Azure Load Balancer** *(optional)* — Internal HTTP load balancing with health probes
- **Azure Traffic Manager** *(optional)* — Global performance-based routing
- **Azure Web Apps** *(optional)* — Multi-region Linux web apps
- **NSG** — Network security group restricting SSH access by source IP
- **Cloud-Init** — VM bootstrapping

---

*Automated DevOps deployment by Adrian Baker* — [aibots.poms.tech](https://aibots.poms.tech)
