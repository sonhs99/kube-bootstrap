resource "kubernetes_namespace" "sealed_secrets" {
  metadata {
    name = "sealed-secrets"
  }

  depends_on = [
    time_sleep.wait_for_kube,
  ]
}

resource "kubernetes_secret" "sealed_secrets_cert" {
  metadata {
    name      = "sealed-secrets-key"
    namespace = "sealed-secrets"
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = file("../cert/sealed-secrets-key.pub")
    "tls.key" = file("../cert/sealed-secrets-key.pem")
  }
  depends_on = [kubernetes_namespace.sealed_secrets]
}

resource "helm_release" "sealed_secrets" {
  name             = "sealed-secrets-controller"
  namespace        = "sealed-secrets"
  repository       = "https://bitnami-labs.github.io/sealed-secrets"
  chart            = "sealed-secrets"
  version          = "2.18.5"
  create_namespace = false

  values = [yamlencode({
    secretName = "sealed-secrets-key"
    keyrenewperiod = "0"
  })]

  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    kubernetes_secret.sealed_secrets_cert,
    kubernetes_namespace.sealed_secrets,
    helm_release.cilium
  ]
}