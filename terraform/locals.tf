locals {
  controlplanes = {
    for k, v in var.nodes : k => v
    if v.role == "controlplane"
  }

  workers = {
    for k, v in var.nodes : k => v
    if v.role == "worker"
  }

  controlplane_ips = [for _, v in local.controlplanes : v.ip]
  worker_ips       = [for _, v in local.workers : v.ip]
  all_node_ips     = [for _, v in var.nodes : v.ip]
}