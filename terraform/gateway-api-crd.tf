data "http" "gateway_api_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml"
}

data "kubectl_file_documents" "gateway_api_docs" {
  content = data.http.gateway_api_crds.response_body
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each  = data.kubectl_file_documents.gateway_api_docs.manifests
  yaml_body = each.value

  depends_on = [ time_sleep.wait_for_kube ]
}