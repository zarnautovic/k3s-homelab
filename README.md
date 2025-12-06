# Homelab: K3s on Proxmox with Terraform + Ansible

Spin up a highly-available K3s cluster on Proxmox using Terraform (to create VMs) and Ansible (to configure them and install K3s, Cilium, and Kube-VIP). The setup creates 6 Ubuntu VMs via cloud-init clones: 3 control-plane nodes and 3 worker nodes. Ansible then installs K3s, deploys Cilium (CNI + L2 LB), deploys Kube-VIP for a virtual API endpoint, and configures your local kubeconfig.

## What this repo does

- Terraform:
  - Clones Ubuntu cloud-init templates into 6 VMs with static IPs and your SSH key.
  - Uses `terraform/vms.tf` to define VM names, VMIDs, IPs, nodes, and templates.
- Ansible:
  - Prepares nodes (timezone, disables swap, sysctl, eBPF mount).
  - Installs K3s on control-plane and worker nodes.
  - Configures your local `~/.kube/config` from the first control-plane, and later switches it to the VIP.
  - Installs Cilium (with a `CiliumLoadBalancerIPPool` and L2 announcements).
  - Installs Kube-VIP to provide a virtual IP for the Kubernetes API.

## Prerequisites

- Proxmox VE with an API token and Ubuntu cloud-init templates. Ensure template names and Proxmox node names match those in `terraform/vms.tf`, or adjust that file.
- Terraform and Ansible installed on your control machine.
- kubectl on your control machine (Cilium/Kube-VIP steps run locally and kubeconfig is written to `~/.kube/config`).
- Ansible collection `kubernetes.core` (installation instruction below).
- SSH keypair available (public key for Terraform, private key for Ansible).

## Terraform: create VMs

1. Create `terraform/terraform.tfvars` from the example and set all required variables:

```bash
cd terraform
cp terraform.example.tfvars terraform.tfvars
```

Set these 4 variables in `terraform.tfvars`:

- `proxmox_token_id`: Proxmox API token ID.
- `proxmox_token_secret`: Proxmox API token secret.
- `proxmox_host`: Proxmox API URL (e.g. `https://<proxmox-host>:8006/api2/json`).
- `ssh_key_file`: Absolute path to your SSH PUBLIC key (e.g. `/home/you/.ssh/id_rsa.pub`).

Optional variables with sensible defaults are defined in `terraform/variables.tf` (e.g. `storage_name`, `bridge`, `cores`, `memory`, `disk_size`, `ci_user`).

1. Run Terraform:

```bash
terraform init
terraform plan
terraform apply
```

### Notes

- If you need to change IPs, VMIDs, Proxmox node names, or template names, edit `terraform/vms.tf`.
- Ensure the specified cloud-init templates exist on the corresponding Proxmox nodes.

## Ansible: configure and install K3s

1. Prepare inventory and group vars:

```bash
cd ../ansible
cp group_vars/all.example.yml group_vars/all.yml
cp inventory.example.ini inventory.ini
```

1. Populate `group_vars/all.yml` with your values:

- `cluster_name`: Arbitrary cluster name.
- `k3s_version`: K3s version to install (e.g. `v1.34.2+k3s1`).
- `k3s_token`: Generate a strong random secret; keep it private.
- `k3s_vip`: The virtual IP for the Kubernetes API (free address on your LAN).
- `k3s_cluster_cidr` / `k3s_service_cidr`: Pod and service CIDRs.
- `cilium_version`: Cilium Helm chart version.
- `cilium_lb_pool_cidr`: CIDR block used for LoadBalancer IPs (e.g. `192.168.1.200/29`).
- `cilium_iface`: Interface on nodes used for L2 announcements (e.g. `eth0`).
- `kube_vip_version`: Kube-VIP version.
- `timezone`: System timezone to set on nodes.

1. Fill `inventory.ini`:

- Under `[cp]` and `[workers]`, set `ansible_host` to the VM IPs you created with Terraform.
- In `[all:vars]`:
  - `ansible_user`: SSH username matching the cloud-init user (defaults to `ubuntu` unless you changed `ci_user`).
  - `ansible_ssh_private_key_file`: Absolute path to your SSH PRIVATE key (e.g. `/home/you/.ssh/id_rsa`).
  - `ansible_python_interpreter`: Leave default (`/usr/bin/python3`) or adjust if needed.

1. Install required Ansible collection and run the playbook:

```bash
ansible-galaxy collection install kubernetes.core
ansible-playbook -i inventory.ini site.yml
```

When it finishes:

- Your local kubeconfig at `~/.kube/config` will be created from `cp1` and then updated to use `k3s_vip` once kube-vip is ready.
- Cilium will be installed with an LB IP pool and L2 announcements enabled on the interface you specified.

## Reset (uninstall K3s and clean node state)

```bash
ansible-playbook -i inventory.ini reset.yml
```

This removes K3s services, binaries, data directories, and systemd units across all nodes.

## Troubleshooting tips

- Verify your Proxmox token values and API URL in `terraform.tfvars`.
- Ensure `template_name` values in `terraform/vms.tf` match existing cloud-init templates per node.
- Confirm you can SSH to the VMs with the user and key configured in `inventory.ini`.
- Make sure `kubectl` is installed locally before running the Ansible playbook (Cilium/Kube-VIP steps run from localhost).
