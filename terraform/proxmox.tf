resource "proxmox_download_file" "talos_image" {
  for_each = toset(var.proxmox_nodes)

  depends_on = [
    talos_image_factory_schematic.this
  ]

  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = each.value
  url          = data.talos_image_factory_urls.this.urls.iso
  file_name    = "${var.cluster_name}-talos_linux-${data.talos_image_factory_urls.this.schematic_id}-${var.talos_version}-${var.talos_arch}.iso"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "talos" {
  for_each = var.nodes

  depends_on = [
    proxmox_download_file.talos_image
  ]

  name      = each.key
  node_name = each.value.proxmox_node
  vm_id     = each.value.vm_id

  started  = true
  on_boot  = true
  bios     = "ovmf"
  machine  = "q35"
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
    floating  = 0
  }

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = each.value.disk_gb
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  cdrom {
    file_id     = "${var.iso_datastore}:iso/${proxmox_download_file.talos_image[each.value.proxmox_node].file_name}"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
    mac_address = each.value.mac_address
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["scsi0", "ide3"]
}