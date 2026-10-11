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
        network = {
          interfaces = [{
            deviceSelector = {
              hardwareAddr = each.value.mac_address
            }
            addresses = [each.value.ip]
            routes = [{
              network = "0.0.0.0/0"
              gateway = var.gateway
            }]
          }]
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UnattendedInstallConfig"

      installer = {
        image = data.talos_image_factory_urls.this.urls.installer
      }
      provisioning = {
        diskSelector = {
          match = "disk.dev_path == \"/dev/sda\"" 
        }
        wipe = false 
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "KubeProxyConfig"

      enabled = false
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "KubeFlannelCNIConfig"

      "$patch" = "delete"
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"

      hostname   = each.key
      auto       = "off"
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  for_each = local.workers

  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = [
    yamlencode({
      machine = {
        network = {
          interfaces = [{
            deviceSelector = {
              hardwareAddr = each.value.mac_address
            }
            addresses = [each.value.ip]
            routes = [{
              network = "0.0.0.0/0"
              gateway = var.gateway
            }]
          }]
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UnattendedInstallConfig"
      installer = {
        image = data.talos_image_factory_urls.this.urls.installer
      }
      provisioning = {
        diskSelector = {
          match = "disk.dev_path == \"/dev/sda\"" 
        }
        wipe = false 
      }
    }),
    yamlencode({
      apiVersion  = "v1alpha1"
      kind        = "UserVolumeConfig"
      name        = "longhorn"
      volumeType  = "disk"

      provisioning = {
        diskSelector = {
          match = "disk.dev_path == \"/dev/sdb\""
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      hostname   = each.key
      auto       = "off"
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

  config_patches = []
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = local.workers

  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration

  node     = each.value.ip

  config_patches = []
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]

  node                 = var.cluster_endpoint_ip
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

  node                 = var.cluster_endpoint_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.controlplane_ips
  nodes                = local.controlplane_ips
}