resource "helm_release" "cilium" {
  name             = "cilium"
  namespace        = "kube-system"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = "1.18.0"
  create_namespace = false

  values = [
    yamlencode(file("../argocd/infrastructure/cilium-lb/cilium-values.yaml"))
  ]

  depends_on = [time_sleep.wait_for_kube]
}