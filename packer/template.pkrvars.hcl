proxmox_api = {
  host = "<your host>"
  port = "8006"
}
proxmox_api_token = {
  id     = "<your token id>"
  secret = "<your token secret>"
}
ssh = {
  public_key       = "<your ssh public key>"
  private_key_file = "/path/to/your/ssh/private_key_file"
}
nonroot_user         = "ubuntu"
service_user_passwd  = "changeme"
lvm_storage          = "local-lvm"
lxc_template_release = "noble"
vm_template = {
  target_node       = "<your node>"
  vm_name           = "ubuntu-server-template"
  vm_id             = 1000
  iso_file          = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
  qemu_agent        = true
  cores             = 4
  memory            = 8196
  use_alt_boot_cmd  = false
  http_bind_address = ""
}