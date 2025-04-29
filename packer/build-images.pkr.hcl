source "proxmox-iso" "ubuntu-server-source" {
  proxmox_url              = "https://${var.proxmox_api.host}:${var.proxmox_api.port}/api2/json"
  username                 = var.proxmox_api_token.id
  token                    = var.proxmox_api_token.secret
  insecure_skip_tls_verify = true

  node                 = var.vm_template.target_node
  vm_name              = var.vm_template.vm_name
  vm_id                = var.vm_template.vm_id
  template_description = "Ubuntu Server template generated on ${timestamp()} with ${var.vm_template.iso_file}"

  boot_iso {
    type     = "scsi"
    iso_file = var.vm_template.iso_file
    unmount  = true
  }

  qemu_agent              = var.vm_template.qemu_agent
  cores                   = var.vm_template.cores
  memory                  = var.vm_template.memory
  cloud_init              = true
  cloud_init_storage_pool = var.lvm_storage
  scsi_controller         = "virtio-scsi-single"

  disks {
    disk_size    = "20G"
    format       = "raw"
    storage_pool = var.lvm_storage
    type         = "virtio"
  }

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }

  boot_command = var.vm_template.use_alt_boot_cmd ? [
    "c<wait>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}' ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
    ] : [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]

  boot         = "c"
  boot_wait    = "10s"
  communicator = "ssh"

  http_directory    = "http"
  http_bind_address = var.vm_template.http_bind_address
  # http_port_min           = 8802
  # http_port_max           = 8802

  ssh_username         = var.nonroot_user
  ssh_private_key_file = var.ssh.private_key_file
  # ssh_password        = "your-password"
  ssh_timeout = "30m"
  ssh_pty     = true
}

build {
  name    = "ubuntu-server-build"
  sources = ["source.proxmox-iso.ubuntu-server-source"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  # Provisioning files for Proxmox Cloud-Init Integration
  provisioner "shell" {
    inline = [
      "echo \"${file("files/99-pve.cfg")}\" > /tmp/99-pve.cfg",
      "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"
    ]
  }

  # Provisioning the VM Template for additional packages
  provisioner "shell" {
    inline = [
      "cargo install starship@1.20.1 --locked",
      "sudo snap install tldr",
      "sudo snap install distrobuilder --classic",
      "mkdir -p ~/.local/bin",
      "sudo ln -s /usr/bin/batcat /usr/local/bin/bat"
    ]
  }

  # Provisioning configuration for container images
  provisioner "file" {
    source      = "../distrobuilder/ubuntu.yaml"
    destination = "/tmp/ubuntu.yaml"
  }

  # Provisioning the SSH key for uploading to host storage
  provisioner "file" {
    source      = var.ssh.private_key_file
    destination = "/tmp/ssh_key"
  }

  # Configure ssh and transfer artifacts to host
  provisioner "shell" {
    inline = [
      "chmod 600 /tmp/ssh_key",
      "eval $(ssh-agent -s)",
      "ssh-add /tmp/ssh_key",
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
      "echo \"StrictHostKeyChecking no\" > ~/.ssh/config",
      "chmod 644 ~/.ssh/config",
      "sudo distrobuilder build-lxc -o image.architecture=amd64 -o image.release=${var.lxc_template_release} -o image.variant=default /tmp/ubuntu.yaml",
      "echo Renaming rootfs... && mv ./rootfs.tar.xz ./ubuntu-container-${var.lxc_template_release}-amd64-default.tar.xz",
      "echo Transferring... && scp ./ubuntu-container-${var.lxc_template_release}-amd64-default.tar.xz root@${var.proxmox_api.host}:/var/lib/vz/template/cache/ubuntu-container-${var.lxc_template_release}-amd64-default-${timestamp()}.tar.xz",
      "sudo distrobuilder build-lxc -o image.architecture=amd64 -o image.release=${var.lxc_template_release} -o image.variant=samba /tmp/ubuntu.yaml",
      "echo Renaming rootfs... && mv ./rootfs.tar.xz ./ubuntu-container-${var.lxc_template_release}-amd64-samba.tar.xz",
      "echo Transferring... && scp ./ubuntu-container-${var.lxc_template_release}-amd64-samba.tar.xz root@${var.proxmox_api.host}:/var/lib/vz/template/cache/ubuntu-container-${var.lxc_template_release}-amd64-samba-${timestamp()}.tar.xz",
      "echo Cleaning up... && sudo rm ./*.tar.xz",
      "ssh-add -d /tmp/ssh_key",
      "rm /tmp/ssh_key"
    ]
  }

  # Add additional provisioning scripts here
  # ...
}