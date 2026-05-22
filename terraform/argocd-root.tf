resource "kubectl_manifest" "argocd_root_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "root"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_target_revision
        path           = var.gitops_root_path
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
        directory = {
            recurse = true
        }
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [
    helm_release.argocd,
    helm_release.sealed_secrets
  ]
}