resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  
  lifecycle {
    ignore_changes = all
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
  version    = "10.10.2"

  values = [
    yamlencode({
      global = {
        domain = "argocd.internal.lazydog.work"
      }

      configs = {
        params = {
          "server.insecure" = true
        }
        cm = {
          "resource.exclusions" = yamlencode([
            {
              apiGroups = ["coordination.k8s.io"]
              kinds     = ["Lease"]
            },
            {
              apiGroups = [
                "authentication.k8s.io",
                "authorization.k8s.io"
              ]
              kinds = [
                "SelfSubjectReview",
                "TokenReview",
                "LocalSubjectAccessReview",
                "SelfSubjectAccessReview",
                "SelfSubjectRulesReview",
                "SubjectAccessReview"
              ]
            },
            {
              apiGroups = ["certificates.k8s.io"]
              kinds     = ["CertificateSigningRequest"]
            },
            {
              apiGroups = ["cert-manager.io"]
              kinds     = ["CertificateRequest"]
            },
            {
              apiGroups = ["cilium.io"]
              kinds = [
                "CiliumIdentity",
                "CiliumEndpoint",
                "CiliumEndpointSlice"
              ]
            },
            {
              apiGroups = [
                "kyverno.io",
                "reports.kyverno.io",
                "wgpolicyk8s.io"
              ]
              kinds = [
                "PolicyReport",
                "ClusterPolicyReport",
                "EphemeralReport",
                "ClusterEphemeralReport",
                "AdmissionReport",
                "ClusterAdmissionReport",
                "BackgroundScanReport",
                "ClusterBackgroundScanReport",
                "UpdateRequest"
              ]
            }
          ])
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
  
  depends_on = [
    time_sleep.wait_for_kube,
    kubernetes_namespace.argocd,
    helm_release.sealed_secrets
  ]
}