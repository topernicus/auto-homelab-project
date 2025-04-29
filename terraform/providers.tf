terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      # LINK https://github.com/Telmate/terraform-provider-proxmox
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}