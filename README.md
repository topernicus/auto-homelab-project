# Automated Homelab Project

This project is a learning exercise in Infrastructure as Code, aka GitOps, using Proxmox, Packer, and Terraform to deploy a homelab environment with minimal overhead.

Packer is utilized to build both a cloud-init template for deploying virtual machines and CT templates for deploying LXC containers. The [Packer plugin for Proxmox](https://github.com/hashicorp/packer-plugin-proxmox) from Hashicorp is used to build the vm template, while [distrobuilder](https://github.com/lxc/distrobuilder) is used in tandem to create the CT templates.

Once templates are built, Terraform can be used to deploy a live environment in moments via the [Telmate Proxmox provider](https://github.com/Telmate/terraform-provider-proxmox). This environment will include lxc containers running samba to share data and pi-hole to provide dns, and a docker virtual machine to run additional containers.

Various packages are included in the generated images, such as [bat](https://github.com/sharkdp/bat), [btop](https://github.com/aristocratos/btop), [eza](https://github.com/eza-community/eza), [ncdu](https://dev.yorhel.nl/ncdu), [neovim](https://github.com/neovim/neovim), [nnn](https://github.com/jarun/nnn), [starship](https://starship.rs/), [tldr](https://github.com/tldr-pages/tldr), and [lazydocker (vm only)](https://github.com/jesseduffield/lazydocker).

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
    - Update _http/user-data_ with your public ssh key and desired _nonroot_user_ (Default is 'ubuntu')
      - If changing default nonroot user, be sure to update _/distrobuilder/ubuntu.yaml_ as well.
    - Initialize Packer and run `packer build .` to create container and VM templates
  - `/terraform`
    - Copy _template.tfvars_ to _secrets.auto.tfvars_ and populate values
    - Initialize Terraform and run `terraform apply` to deploy to target Proxmox node
    - SSH into the samba container to run `sudo passwd ubuntu` and `sudo smbpasswd -a ubuntu`, completing samba user setup
      - Substitute your own _nonroot_user_ value as needed

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

- [x] Update README.md
- [x] Known issue: Group permissions should be _smb-share_
- [x] Docker integrations (portainer, lazydocker)
- [ ] Add aliases and configuration for installed packages (.bashrc, starship.toml, etc)
- [ ] Add variable descriptions and constraints
- [ ] Explore dynamic values for distrobuilder and packer user-data
- [ ] Investigate adding Ansible to reduce provisioning complexity

## Resources

- [Create VMs on Proxmox in Seconds!](https://www.youtube.com/watch?v=1nf3WOEFq1Y)
- [Proxmox virtual machine _automation_ in Terraform](https://www.youtube.com/watch?v=dvyeoDBUtsU)
- [Running a NAS on Proxmox, Different Methods and What to Know](https://www.youtube.com/watch?v=hJHpVi9LGqc)
- [Automate Homelab deployment with Terraform & Proxmox](https://www.youtube.com/watch?v=ZGWn6xREdDE)
- [The ULTIMATE Home Server Setup - Full Walkthrough Guide Pt.1](https://www.youtube.com/watch?v=qmSizZUbCOA)
