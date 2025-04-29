variable "proxmox_api" {
  type = object({
    host = string
    port = string
  })
}

variable "proxmox_api_token" {
  type = object({
    id     = string
    secret = string
  })
  sensitive = true
}

variable "ssh" {
  type = object({
    public_key       = string
    private_key_file = string
  })
}

variable "nonroot_user" {
  type = string
}

variable "service_user_passwd" {
  type      = string
  # sensitive = true
}

variable "locations" {
  type = object({
    host_root        = string
    samba_subdir     = string
    samba_share      = string
    container_subdir = string
    container_share  = string
    lvm_storage      = string
  })
}

variable "network" {
  type = object({
    prefix  = string
    cidr    = string
    gateway = string
  })
}

variable "samba_container_1" {
  type = object({
    target_node  = string
    hostname     = string
    vmid         = number
    ostemplate   = string
    unprivileged = bool
    ostype       = string
    cores        = number
    memory       = number
    start        = bool
    onboot       = bool
    hostid       = string
  })
}

variable "pihole_container_1" {
  type = object({
    target_node  = string
    hostname     = string
    vmid         = number
    ostemplate   = string
    unprivileged = bool
    ostype       = string
    cores        = number
    memory       = number
    start        = bool
    onboot       = bool
    hostid       = string
  })
}

variable "docker_vm_1" {
  type = object({
    target_node = string
    hostname    = string
    vmid        = number
    ostemplate  = string
    full_clone  = bool
    agent       = bool
    cores       = number
    memory      = number
    start       = bool
    onboot      = bool
    hostid      = string
  })
}

provider "proxmox" {
  pm_api_url          = "https://${var.proxmox_api.host}:${var.proxmox_api.port}/api2/json"
  pm_api_token_id     = var.proxmox_api_token.id
  pm_api_token_secret = var.proxmox_api_token.secret

  # NOTE Optional, but recommended to set to true if you are using self-signed certificates.
  pm_tls_insecure = true
}