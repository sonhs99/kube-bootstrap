resource "helm_release" "cilium" {
  name             = "cilium"
  namespace        = "kube-system"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = "1.18.0"
  create_namespace = false

  values = [
    yamlencode({
      ipam = {
        mode = "kubernetes"
      }

      kubeProxyReplacement = true
      gatewayAPI = {
        enabled = true
      }
      l2announcements = {
        enabled = true
      }

      k8sServiceHost = "localhost"
      k8sServicePort = 7445

      externalIPs = {
        enabled = true
      }

      securityContext = {
        capabilities = {
          ciliumAgent = [
            "CHOWN",
            "KILL",
            "NET_ADMIN",
            "NET_RAW",
            "IPC_LOCK",
            "SYS_ADMIN",
            "SYS_RESOURCE",
            "DAC_OVERRIDE",
            "FOWNER",
            "SETGID",
            "SETUID"
          ]

          cleanCiliumState = [
            "NET_ADMIN",
            "SYS_ADMIN",
            "SYS_RESOURCE"
          ]
        }
      }

      cgroup = {
        autoMount = {
          enabled = false
        }
        hostRoot = "/sys/fs/cgroup"
      }

      operator = {
        replicas = 1
        prometheus = {
            enabled = true
        }
      }

      hubble = {
        enabled = true
        relay = {
          enabled = true
        }
        ui = {
          enabled = true
          service = {
            type = "NodePort"
            nodePort = 30000
          }
        }
        metrics = {
            enableOpenMetrics=true
            enabled = [
                "dns",
                "drop",
                "tcp",
                "flow",
                "port-distribution",
                "icmp",
                "httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload"
            ]
        }
      }
    })
  ]

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [time_sleep.wait_for_kube]
}