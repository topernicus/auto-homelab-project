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
nonroot_user        = "ubuntu"
service_user_passwd = "changeme"
locations = {
  host_root        = "/data-pool"
  samba_subdir     = "share-data"
  samba_share      = "shared"
  container_subdir = "container-data"
  container_share  = "container-data"
  lvm_storage      = "local-lvm"
}
network = {
  prefix  = "192.168.0"
  cidr    = "16"
  gateway = "192.168.0.1"
}
samba_container_1 = {
  target_node  = "<your node>"
  hostname     = "lxc-samba-1"
  vmid         = 108
  ostemplate   = "local:vztmpl/ubuntu-container-noble-amd64-samba-<your template>.tar.xz"
  unprivileged = true
  ostype       = "ubuntu"
  cores        = 2
  memory       = 2048
  start        = false
  onboot       = true
  hostid       = "8"
}
pihole_container_1 = {
  target_node  = "proxmox"
  hostname     = "lxc-pihole-1"
  vmid         = 102
  ostemplate   = "local:vztmpl/ubuntu-container-noble-amd64-default-<your template>.tar.xz"
  unprivileged = true
  ostype       = "ubuntu"
  cores        = 2
  memory       = 2048
  start        = false
  onboot       = true
  hostid       = "2"
}
docker_vm_1 = {
  target_node = "proxmox"
  hostname    = "vm-docker-1"
  vmid        = 111
  ostemplate  = "ubuntu-server-template"
  full_clone  = false
  agent       = true
  cores       = 2
  memory      = 4096
  start       = true
  onboot      = true
  hostid      = "11"
}