resource "talos_machine_secrets" "this" {}

resource "talos_image_factory_schematic" "this" {
    schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/i915",
          "siderolabs/intel-ice-firmware",
          "siderolabs/intel-ucode",
          "siderolabs/iscsi-tools",
          "siderolabs/mei",
          "siderolabs/nfs-utils",
          "siderolabs/qemu-guest-agent",
          "siderolabs/util-linux-tools",
        ]
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
  architecture  = var.talos_arch
}

data "talos_machine_configuration" "controlplane" {
  for_each = local.controlplanes
  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.this.urls.installer
          disk = "/dev/sda"
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = false
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
      }
    }),
    yamlencode({
      machine = {
        network = {
          interfaces = [{
            deviceSelector = [{
              hardwareAddr = each.value.mac_address
            }]
            vip = {
              ip = var.cluster_endpoint_ip
            }
          }]
        }
      }
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.this.urls.installer
          disk = "/dev/sda"
        }
      }
    }),
    yamlencode({
      machine = {
        disks = [{
          device = "/dev/sdb"
          partition = [{
            mountpoint = "/var/mnt/longhorn"
            size = 0
          }]
        }] 
      }
    }),
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = local.controlplanes

  depends_on = [
    proxmox_virtual_environment_vm.talos
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[each.key].machine_configuration

  node     = each.value.ip
  endpoint = each.value.ip

  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = each.key
          interfaces = [{
            deviceSelector = [{
              hardwareAddr = each.value.mac_address
            }]
            addresses = [each.value.ip]
            routes = [{
              network = "192.168.88.0/24"
              gateway = var.gateway
            }]
          }]
        }
      }
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = local.workers

  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration

  node     = each.value.ip

  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = each.key
          interfaces = [{
            deviceSelector = [{
              hardwareAddr = each.value.mac_address
            }]
            addresses = [each.value.ip]
            routes = [{
              network = "192.168.88.0/24"
              gateway = var.gateway
            }]
          }]
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]

  node                 = local.controlplane_ips[0]
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "time_sleep" "wait_for_kube" {
  depends_on = [talos_machine_bootstrap.this]

  create_duration = "60s"
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_configuration_apply.worker
  ]

  node                 = local.controlplane_ips[0]
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.controlplane_ips
  nodes                = local.controlplane_ips
}