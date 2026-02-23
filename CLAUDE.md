# Terra-Anis-1 - Azure Automation Showcase

## Project Overview
Terraform + Ansible automation project for YouTube/CV showcase. Deploys a multi-region Azure network with an Ansible control VM that configures web servers, an Application Gateway for path and host-based routing, and optionally an internal load balancer, Traffic Manager, and Web Apps.

## Architecture
- **Ansible VM** (Ansible-VM-01): Control node in SharedServicesSubnet (10.20.10.0/24), has public IP for SSH access
- **Web Server VMs**: Target nodes across all subnets, no public IP, accessed via private DNS
- **3 VNets**: CoreServicesVnet (hub), ManufacturingVnet, ResearchVnet — peered hub-and-spoke
- **Private DNS Zone**: azure.poms.tech with auto-registration enabled on all VNets
- **Key Vault**: Stores Ansible SSH public key, accessed via managed identity
- **NAT Gateways**: One per VNet/region — core-nat-gateway (East US), mfg-nat-gateway (West Europe), research-nat-gateway (Southeast Asia). All subnets associated.
- **Application Gateway**: Standard_v2 in AppGatewaySubnet (10.20.50.0/24). Public IP: `lab-appgw-pip` with DNS label `lab-appgw.eastus.cloudapp.azure.com`. Supports path-based routing (/web, /mfg) and host-based routing (web.poms.tech, mfg.poms.tech).
- **Internal LB** *(lb.tf.off — enable for full deploy)*: Standard SKU in PublicWebServiceSubnet, backends: WebServer-01 + DatabaseServer-01. DNS: loadbalancer.azure.poms.tech
- **Traffic Manager** *(traffic-manager.tf.off — enable for full deploy)*: Performance routing across 3 Web App regions
- **Web Apps** *(web-apps.tf.off — enable for full deploy)*: Linux Web Apps in Central US, West Europe, Southeast Asia
- **NSG**: ansible-vm-nsg on Ansible VM NIC, allows SSH from a specific IP only

## Key Files
- `ansible-vm.tf` - Ansible control VM with public IP, managed identity, cloud-init
- `compute.tf` - All VMs across all subnets (full deploy). Rename to `compute.tf.appgw.off` to use minimal AppGW-only set
- `compute.tf.appgw.off` - Minimal compute: WebServer-01 + MfgServer-01 only (for AppGW testing)
- `app-gateway.tf` - Application Gateway with path-based and host-based routing rules, URL rewrite rules, SSL policy
- `cloud-init/ansible-init.yaml` - Bootstraps Ansible VM (installs Ansible, az CLI, generates SSH keys, uploads pubkey to Key Vault)
- `networks.tf` - VNets and subnets (includes AppGatewaySubnet 10.20.50.0/24)
- `peering.tf` - Hub-spoke VNet peering
- `dns.tf` - Private DNS zone and VNet links
- `key-vault.tf` - Key Vault with access policies
- `nsg.tf` - Network security group (SSH access restriction for Ansible VM)
- `nat-gateway.tf` - NAT gateways for all 3 VNets (outbound internet)
- `lb.tf.off` - Internal load balancer — rename to `lb.tf` for full YouTube deploy
- `traffic-manager.tf.off` - Traffic Manager — rename to `traffic-manager.tf` for full YouTube deploy
- `web-apps.tf.off` - Web Apps in 3 regions — rename to `web-apps.tf` for full YouTube deploy

## .off Files — YouTube Full Deploy
Files with `.off` extension are disabled (Terraform ignores them). To enable for the full YouTube deploy:
```bash
mv lb.tf.off lb.tf
mv traffic-manager.tf.off traffic-manager.tf
mv web-apps.tf.off web-apps.tf
```

## Application Gateway Routing
- `http://<ip>/web/` → WebServer-01 (path-based, prefix stripped by rewrite rule)
- `http://<ip>/mfg/` → MfgServer-01 (path-based, prefix stripped by rewrite rule)
- `http://web.poms.tech/` → WebServer-01 (host-based listener)
- `http://mfg.poms.tech/` → MfgServer-01 (host-based listener)
- Default → WebServer-01

**Important:** Host-based routing rules must have lower priority numbers than the catch-all listener, otherwise the catch-all wins. Current priorities: web-host-rule=100, mfg-host-rule=200, path-based=300.

**SSL Policy:** Azure deprecated TLS 1.0/1.1 — must explicitly set `AppGwSslPolicy20220101` or apply will fail with `ApplicationGatewayDeprecatedTlsVersionUsedInSslPolicy`.

## DNS (Hostinger)
CNAME both `web.poms.tech` and `mfg.poms.tech` to `lab-appgw.eastus.cloudapp.azure.com`. The Azure DNS label is stable across redeploys — the CNAME never needs updating.

## Deploy Flow
1. `terraform apply` deploys networking, Key Vault, NAT gateways, App Gateway, NSG, Ansible VM
2. Cloud-init on Ansible VM installs tools, generates SSH keypair, uploads pubkey to Key Vault
3. `null_resource.wait_for_cloud_init` waits for cloud-init to finish
4. Terraform reads pubkey from Key Vault, creates compute VMs
5. `null_resource.register_*` SSHes into Ansible VM and adds each VM's DNS name to inventory
6. User SSHes to Ansible VM and runs `ansible-playbook -i inventory.ini deploy-nginx.yml`

## Cloud-Init Gotchas
- `write_files` runs before Azure user provisioning — do NOT set `owner: azure_user` on write_files entries
- Home directory `/home/azure_user` can end up owned by root — fix with `chown` as first runcmd
- `.bashrc` may not exist — copy from `/etc/skel/.bashrc` in runcmd
- `az login --identity` needs `--allow-no-subscriptions` flag (managed identity has Key Vault access but no subscription role)

## Commands
- Deploy: `terraform apply -auto-approve`
- Destroy: `terraform destroy -auto-approve`
- SSH to Ansible VM: `ssh -i keys/ansible_rsa azure_user@<public_ip>`
- Run playbook: `cd ~/ansible && ansible-playbook -i inventory.ini deploy-nginx.yml`
- Test AppGW path routing: `curl http://<appgw_ip>/web/` and `curl http://<appgw_ip>/mfg/`
- Test AppGW host routing: `curl -H "Host: mfg.poms.tech" http://<appgw_ip>/`

## Conventions
- All fixes go in Terraform or Ansible files, never manual patches on live VMs
- Web server packages (like net-tools) go in the Ansible playbook, not cloud-init
- Inventory uses DNS names (e.g. webserver-01.azure.poms.tech), not IPs
- Compute VMs and optional components disabled by renaming `.tf` to `.off`
