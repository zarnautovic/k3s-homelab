locals {
  vms = {
    cp1 = { name = "k3s-cp1", node = "zeus", vmid = 110, ip = "192.168.1.110", gw = "192.168.1.1", template_name = "ubuntu-cloud-zeus"}
    cp2 = { name = "k3s-cp2", node = "hades", vmid = 111, ip = "192.168.1.111", gw = "192.168.1.1", template_name = "ubuntu-cloud-hades" }
    cp3 = { name = "k3s-cp3", node = "poseidon", vmid = 112, ip = "192.168.1.112", gw = "192.168.1.1", template_name = "ubuntu-cloud-poseidon" }
    w1  = { name = "k3s-w1", node = "zeus", vmid = 120, ip = "192.168.1.120", gw = "192.168.1.1", template_name = "ubuntu-cloud-zeus" }
    w2  = { name = "k3s-w2", node = "hades", vmid = 121, ip = "192.168.1.121", gw = "192.168.1.1", template_name = "ubuntu-cloud-hades" }
    w3  = { name = "k3s-w3", node = "poseidon", vmid = 122, ip = "192.168.1.122", gw = "192.168.1.1", template_name = "ubuntu-cloud-poseidon" }
  }
}

resource "proxmox_vm_qemu" "vm" {
  for_each    = local.vms

  name        = each.value.name
  target_node = each.value.node
  vmid        = each.value.vmid
  clone       = each.value.template_name

  onboot      = true
  agent       = 1
  scsihw      = "virtio-scsi-pci"

  cpu {
    cores     = var.cores
    # (optional) type = "host" or leave for default
  }

  memory      = var.memory
  
  # Main OS disk
  disk {
    slot        = "scsi0" # bus+index defines it's SCSI disk
    type        = "disk" # valid values: disk|cdrom|cloudinit|ignore
    size        = var.disk_size
    storage     = var.storage_name
    emulatessd  = true
    replicate   = true
  }

  # Cloud-Init drive on ide2
  disk {
    slot      = "ide2"
    type      = "cloudinit"
    storage   = var.storage_name
  }

  network {
    id        = 0
    model     = "virtio"
    bridge    = var.bridge
  }

  ciuser      = var.ci_user
  sshkeys     = file(var.ssh_key_file) # use an ABSOLUTE path here

  # Use ipconfig0..N, and include CIDR!
  ipconfig0   = "ip=${each.value.ip}/24,gw=${each.value.gw}"

  # Boot order
  boot        = "order=scsi0"
}
