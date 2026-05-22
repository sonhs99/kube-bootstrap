terraform {
  required_version = ">= 1.7.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.8"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}