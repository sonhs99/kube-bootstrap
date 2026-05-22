resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [
    helm_release.cilium
  ]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.16"

  values = [
    yamlencode({
      global = {
        domain = "argocd.internal.lazydog.work"
      }

      configs = {
        params = {
          "server.insecure" = true
        }
      }

      server = {
        service = {
          type = "NodePort"
        }
      }

      controller = {
        replicas = 1
      }

      repoServer = {
        replicas = 1
      }

      applicationSet = {
        replicas = 1
      }
    })
  ]

  lifecycle {
    ignore_changes = [
      values,
      version,
      chart,
      repository,
    ]
  }
  
  depends_on = [
    time_sleep.wait_for_kube,
    kubernetes_namespace.argocd
  ]
}