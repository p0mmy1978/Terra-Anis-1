# Terra-Anis-1 - Azure Automation Showcase

## Project Overview
Terraform + Ansible automation project for YouTube/CV showcase. Deploys a multi-region Azure network with an Ansible control VM that configures web servers.

## Architecture
- **Ansible VM** (Ansible-VM-01): Control node in SharedServicesSubnet (10.20.10.0/24), has public IP for SSH access
- **Web Server VMs**: Target nodes in PublicWebServiceSubnet (10.20.30.0/24), no public IP, accessed via private DNS
- **3 VNets**: CoreServicesVnet (hub), ManufacturingVnet, ResearchVnet — peered hub-and-spoke
- **Private DNS Zone**: azure.poms.tech with auto-registration enabled on all VNets
- **Key Vault**: Stores Ansible SSH public key, accessed via managed identity

## Key Files
- `ansible-vm.tf` - Ansible control VM with public IP, managed identity, cloud-init
- `compute.tf` - Web server VMs (enable by renaming from `compute.off`)
- `cloud-init/ansible-init.yaml` - Bootstraps Ansible VM (installs Ansible, az CLI, generates SSH keys, uploads pubkey to Key Vault)
- `networks.tf` - VNets and subnets
- `peering.tf` - Hub-spoke VNet peering
- `dns.tf` - Private DNS zone and VNet links
- `key-vault.tf` - Key Vault with access policies
- `nsg.tf` - Network security groups
- `keys/` - SSH keypair for accessing Ansible VM from local machine

## Deploy Flow
1. `terraform apply` deploys networking, Key Vault, Ansible VM
2. Cloud-init on Ansible VM installs tools, generates SSH keypair, uploads pubkey to Key Vault
3. `null_resource.wait_for_cloud_init` waits for cloud-init to finish via `cloud-init status --wait`
4. Terraform reads pubkey from Key Vault, creates web server VMs with it
5. `null_resource.register_web_vm` SSHes into Ansible VM and adds web server DNS name to inventory
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

## Conventions
- All fixes go in Terraform or Ansible files, never manual patches on live VMs
- Web server packages (like net-tools) go in the Ansible playbook, not cloud-init
- Inventory uses DNS names (e.g. webserver-01.azure.poms.tech), not IPs
- Compute VMs disabled by renaming `.tf` to `.off`
