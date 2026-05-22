variable "cluster_name" {
  type    = string
  default = "homelab"
}

variable "talos_version" {
  type    = string
  default = "v1.9.5"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.31.4"
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint. 보통 LB/VIP/FQDN 사용"
  type        = string
  default     = "https://k8s-api.internal.example.com:6443"
}

variable "cluster_endpoint_ip" {
  description = "Kubernetes API endpoint IP. 보통 LB/VIP/FQDN 사용"
  type        = string
  default     = "10.0.0.1"
}

variable "gateway" {
  type = string
}

variable "cidr_prefix" {
  type    = number
  default = 24
}

variable "dns_servers" {
  type    = list(string)
  default = ["1.1.1.1", "8.8.8.8"]
}

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

# variable "proxmox_api_token" {
#   type      = string
#   sensitive = true
# }

variable "proxmox_insecure" {
  type    = bool
  default = true
}

variable "proxmox_nodes" {
  type    = list(string)
}

variable "talos_arch" {
  type        = string
}

variable "vm_datastore" {
  type    = string
  default = "local-lvm"
}

variable "iso_datastore" {
  type    = string
  default = "local"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "nodes" {
  description = "클러스터 노드 정의"
  type = map(object({
    role         = string # controlplane | worker
    proxmox_node = string
    vm_id        = number
    ip           = string
    cpu          = number
    memory_mb    = number
    disk_gb      = number
    mac_address  = string
  }))
}

variable gitops_repo_url {
  type    = string
}

variable gitops_target_revision {
  type    = string
}

variable gitops_root_path {
  type    = string
}