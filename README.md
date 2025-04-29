# Automated Homelab Project

This project is a learning exercise in Infrastructure as Code, aka GitOps, using Proxmox, Packer, and Terraform to deploy a homelab environment with minimal overhead.

Packer is utilized to build both a cloud-init template for deploying virtual machines and CT templates for deploying LXC containers. The [packer plugin for proxmox](https://github.com/hashicorp/packer-plugin-proxmox) from Hashicorp is used to build the vm template, while [distrobuilder](https://github.com/lxc/distrobuilder) is used in tandem to create the CT templates.

Once templates are built, Terraform can be used to deploy a live environment in moments. This environment will include a samba lxc container to host data, a pi-hole lxc container to provide dns, and a docker virtual machine to run additional containers.

## Quickstart

- **Host**
  - Install [ProxmoxVE](https://www.proxmox.com/en/downloads/proxmox-virtual-environment)
  - Run [Proxmox VE Post Install script](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install)
  - Create an API token with appropriate access
  - Add SSH public key(s) to authorized_keys
  - [Configure storage](#storage-configuration)
- **Local**
  - Ensure local environment has [Packer](https://developer.hashicorp.com/packer) and [Terraform](https://developer.hashicorp.com/terraform) installed
  - `/packer`
    - Copy _template.pkrvars.hcl_ to _secrets.auto.pkrvars.hcl_ and populate values
    - Update _http/user-data_ with your public ssh key
    - Initialize Packer and run `packer build .` to create container and VM templates
  - `/terraform`
    - Copy _template.tfvars_ to _secrets.auto.tfvars_ and populate values
    - Initialize Terraform and run `terraform apply` to deploy to target Proxmox node
    - SSH into the samba container to run `sudo passwd ubuntu` and `sudo smbpasswd -a ubuntu`, completing samba user setup

## Storage Configuration

As configured, the project expects the following folder structure on the host:

- `/data-pool`

  - `/container-data`
    - This folder will be used for lxc and docker data
    - `/pihole/setupVars.conf`
      - This file is used for automated pi-hole setup
  - `/share-data`
    - This folder will be shared to the network

## To Do List

- [x] Create Repo
- [x] Update README.md
- [ ] Known issue: Group permissions should be _smb-share_
- [ ] Finish docker integrations (portainer, lazydocker, compose)
- [ ] Add variable descriptions and constraints
- [ ] Explore dynamic values for distrobuilder and packer user-data

## Resources

- [Create VMs on Proxmox in Seconds!](https://www.youtube.com/watch?v=1nf3WOEFq1Y)
- [Proxmox virtual machine _automation_ in Terraform](https://www.youtube.com/watch?v=dvyeoDBUtsU)
- [Running a NAS on Proxmox, Different Methods and What to Know](https://www.youtube.com/watch?v=hJHpVi9LGqc)
- [Automate Homelab deployment with Terraform & Proxmox](https://www.youtube.com/watch?v=ZGWn6xREdDE)
- [The ULTIMATE Home Server Setup - Full Walkthrough Guide Pt.1](https://www.youtube.com/watch?v=qmSizZUbCOA)
