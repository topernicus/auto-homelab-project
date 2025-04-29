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
  sensitive = true
}

variable "lvm_storage" {
  type = string
}

variable "lxc_template_release" {
  type = string
}

variable "vm_template" {
  type = object({
    target_node       = string
    vm_name           = string
    vm_id             = number
    iso_file          = string
    qemu_agent        = bool
    cores             = number
    memory            = number
    use_alt_boot_cmd  = bool
    http_bind_address = string
  })
}

