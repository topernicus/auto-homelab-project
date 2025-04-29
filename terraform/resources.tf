resource "proxmox_lxc" "samba_container_1" {
  target_node  = var.samba_container_1.target_node
  hostname     = var.samba_container_1.hostname
  vmid         = var.samba_container_1.vmid
  ostemplate   = var.samba_container_1.ostemplate
  unprivileged = var.samba_container_1.unprivileged
  ostype       = var.samba_container_1.ostype
  cores        = var.samba_container_1.cores
  memory       = var.samba_container_1.memory
  start        = var.samba_container_1.start
  onboot       = var.samba_container_1.onboot

  features {
    nesting = true
  }

  rootfs {
    storage = var.locations.lvm_storage
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.network.prefix}.${var.samba_container_1.hostid}/${var.network.cidr}"
    gw     = var.network.gateway
  }

  lifecycle {
    ignore_changes = [features]
  }

  # Provision container features and storage, then boot the container
  # Changing feature flags or bind mounting is only allowed for root@pam without token auth
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh.private_key_file)
      host        = var.proxmox_api.host
    }
    inline = [
      "pct set ${var.samba_container_1.vmid} -features nesting=1,fuse=1",
      "pct set ${var.samba_container_1.vmid} -mp0 ${var.locations.host_root}/${var.locations.container_subdir},mp=/mnt/${var.locations.container_subdir}",
      "chown -R 101001:101001 ${var.locations.host_root}/${var.locations.container_subdir}/",
      "chmod -R 744 ${var.locations.host_root}/${var.locations.container_subdir}/",
      "pct set ${var.samba_container_1.vmid} -mp1 ${var.locations.host_root}/${var.locations.samba_subdir},mp=/mnt/${var.locations.samba_subdir}",
      "chown -R 101001:101001 ${var.locations.host_root}/${var.locations.samba_subdir}/",
      "chmod -R 774 ${var.locations.host_root}/${var.locations.samba_subdir}/",
      "pct start ${var.samba_container_1.vmid} && sleep 20"
    ]
  }

  # Configure default connection
  connection {
    type        = "ssh"
    user        = var.nonroot_user
    private_key = file(var.ssh.private_key_file)
    host        = var.samba_container_1.hostname
  }

  # Provision management applications
  provisioner "remote-exec" {
    inline = [
      "sudo apt update && apt upgrade -y",
      "sudo apt install -y --no-install-recommends cockpit",
      # Statements below are temporarily commented out
      # due to https://repo.45drives.com/repofiles/ubuntu missing a list for noble release
      # "curl -sSL https://repo.45drives.com/setup | sudo bash",
      # "sudo apt update",
      # "sudo apt install -y cockpit-identities cockpit-file-sharing cockpit-navigator"
    ]
  }

  # Provision samba shares
  provisioner "remote-exec" {
    inline = [
      "sudo net conf addshare ${var.locations.samba_share} /mnt/${var.locations.samba_subdir}/ writeable=y",
      "sudo net conf setparm ${var.locations.samba_share} browseable yes",
      "sudo net conf setparm ${var.locations.samba_share} \"inherit permissions\" yes",
      "sudo net conf setparm ${var.locations.samba_share} \"map acl inherit\" yes",
      "sudo net conf setparm ${var.locations.samba_share} \"vfs objects\" acl_xattr",
      "sudo net conf addshare ${var.locations.container_share} /mnt/${var.locations.container_subdir}/ writeable=y",
      "sudo net conf setparm ${var.locations.container_share} browseable yes",
      "sudo net conf setparm ${var.locations.container_share} \"inherit permissions\" yes",
      "sudo net conf setparm ${var.locations.container_share} \"map acl inherit\" yes",
      "sudo net conf setparm ${var.locations.container_share} \"vfs objects\" acl_xattr",
      "sudo net conf setparm global fruit:encoding native",
      "sudo net conf setparm global fruit:nfs_aces no",
      "sudo net conf setparm global fruit:metadata stream",
      "sudo net conf setparm global fruit:zero_file_id yes",
      "sudo net conf setparm global \"vfs objects\" \"catia fruit streams_xattr\""
    ]
  }

  # Configure service account
  provisioner "remote-exec" {
    inline = [
      "(echo ${var.service_user_passwd}; echo ${var.service_user_passwd}) | sudo smbpasswd -s -a service",
    ]
  }

  # Attach samba share as host storage
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh.private_key_file)
      host        = var.proxmox_api.host
    }
    inline = [
      "pvesm add cifs ${var.locations.samba_share} --server ${var.network.prefix}.${var.samba_container_1.hostid} --share ${var.locations.samba_share} --username service --password ${var.service_user_passwd}",
      "pvesm set ${var.locations.samba_share} --content backup,images,rootdir"
    ]
  }
}

resource "terraform_data" "destroy" {
  # Destroy time provisioning to disconnect storage cleanly
  input = {
    proxmox_api_host = var.proxmox_api.host
    private_key_file = var.ssh.private_key_file
    samba_share      = var.locations.samba_share
  }
  provisioner "remote-exec" {
    when = destroy
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(self.input.private_key_file)
      host        = self.input.proxmox_api_host
    }
    inline = [
      # Comment out below lines if destroying without having storage mounted
      # TODO Handle mount failures
      "pvesm remove ${self.input.samba_share}",
      "umount /mnt/pve/${self.input.samba_share}"
    ]
  }
}

resource "proxmox_lxc" "pihole_container_1" {
  depends_on   = [proxmox_lxc.samba_container_1]
  target_node  = var.pihole_container_1.target_node
  hostname     = var.pihole_container_1.hostname
  vmid         = var.pihole_container_1.vmid
  ostemplate   = var.pihole_container_1.ostemplate
  unprivileged = var.pihole_container_1.unprivileged
  ostype       = var.pihole_container_1.ostype
  cores        = var.pihole_container_1.cores
  memory       = var.pihole_container_1.memory
  start        = var.pihole_container_1.start
  onboot       = var.pihole_container_1.onboot

  features {
    nesting = true
  }

  rootfs {
    storage = var.locations.lvm_storage
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.network.prefix}.${var.pihole_container_1.hostid}/${var.network.cidr}"
    gw     = var.network.gateway
  }

  # Provision container storage, then boot the container
  # Bind mounting is only allowed for root@pam without token authentication
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh.private_key_file)
      host        = var.proxmox_api.host
    }
    inline = [
      "pct set ${var.pihole_container_1.vmid} -mp0 ${var.locations.host_root}/${var.locations.container_subdir}/pihole,mp=/etc/pihole",
      "pct start ${var.pihole_container_1.vmid} && sleep 20"
    ]
  }

  # Configure default connection
  connection {
    type        = "ssh"
    user        = var.nonroot_user
    private_key = file(var.ssh.private_key_file)
    host        = var.pihole_container_1.hostname
  }

  # Provision pi-hole application
  provisioner "remote-exec" {
    inline = [
      "sudo apt update && apt upgrade -y",
      "wget -O basic-install.sh https://install.pi-hole.net",
      "sudo bash basic-install.sh --unattended",
      "sudo pihole -g"
    ]
  }
}

resource "proxmox_vm_qemu" "docker_vm_1" {
  depends_on       = [proxmox_lxc.samba_container_1]
  target_node      = var.docker_vm_1.target_node
  name             = var.docker_vm_1.hostname
  desc             = "Docker Host"
  vmid             = var.docker_vm_1.vmid
  clone            = var.docker_vm_1.ostemplate
  full_clone       = var.docker_vm_1.full_clone
  agent            = var.docker_vm_1.agent ? 1 : 0
  sockets          = 1
  cores            = var.docker_vm_1.cores
  memory           = var.docker_vm_1.memory
  balloon          = 2048
  vm_state         = var.docker_vm_1.start ? "running" : "stopped"
  onboot           = var.docker_vm_1.onboot
  boot             = "order=virtio0"
  startup          = ""
  automatic_reboot = false
  qemu_os          = "l26"
  bios             = "seabios"
  scsihw           = "virtio-scsi-single"
  ipconfig0        = "ip=${var.network.prefix}.${var.docker_vm_1.hostid}/${var.network.cidr},gw=${var.network.gateway}"
  sshkeys          = var.ssh.public_key

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    ide {
      ide0 {
        cloudinit {
          storage = var.locations.lvm_storage
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          storage  = var.locations.lvm_storage
          size     = "20G"
          iothread = true
          discard  = true
        }
      }
    }
  }

  # Configure default connection
  connection {
    type        = "ssh"
    user        = var.nonroot_user
    private_key = file(var.ssh.private_key_file)
    host        = var.docker_vm_1.hostname
  }

  # Provision docker-compose configuration
  provisioner "file" {
    source      = "../docker/compose.yml"
    destination = "/tmp/compose.yml"
  }

  # Provision container storage
  provisioner "remote-exec" {
    inline = [
      "sudo echo -e 'username=service\npassword=${var.service_user_passwd}\ndomain=WORKGROUP' >> /home/${var.nonroot_user}/.smbcredentials",
      "sudo chmod 0600 /home/${var.nonroot_user}/.smbcredentials",
      "sudo mkdir /mnt/${var.locations.container_share}",
      "echo '//${var.network.prefix}.${var.samba_container_1.hostid}/${var.locations.container_share} /mnt/${var.locations.container_share} cifs credentials=/home/${var.nonroot_user}/.smbcredentials,uid=1000,gid=1000 0 0' | sudo tee -a /etc/fstab",
      "sudo systemctl daemon-reload",
      "sudo mount -a"
    ]
  }

  # Provision docker application
  provisioner "remote-exec" {
    inline = [
      "sudo apt install -y ca-certificates lsb_release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt update",
      "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    ]
  }
}

