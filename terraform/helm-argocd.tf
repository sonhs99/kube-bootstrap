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
    yamlencode(file("../argocd/infrastructure/argocd/argocd-values.yaml"))
  ]

  lifecycle {
    ignore_changes = all
  }
  
  depends_on = [
    time_sleep.wait_for_kube,
    kubernetes_namespace.argocd
  ]
}