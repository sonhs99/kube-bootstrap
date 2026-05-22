output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "controlplane_ips" {
  value = local.controlplane_ips
}

output "worker_ips" {
  value = local.worker_ips
}

# output "argocd_namespace" {
#   value = kubernetes_namespace.argocd.metadata[0].name
# }