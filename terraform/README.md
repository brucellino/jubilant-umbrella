# terraform

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 4.7 |
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | 2.28.1 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.3.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.1 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | 3.16.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 4.7.1 |
| <a name="provider_digitalocean"></a> [digitalocean](#provider\_digitalocean) | 2.28.1 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.1 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | 3.16.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_record.k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [digitalocean_kubernetes_cluster.k](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.1/docs/resources/kubernetes_cluster) | resource |
| [local_file.k8sconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.k_install](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |
| [cloudflare_zone.k](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |
| [digitalocean_kubernetes_versions.this](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.1/docs/data-sources/kubernetes_versions) | data source |
| [digitalocean_loadbalancer.krateo](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.1/docs/data-sources/loadbalancer) | data source |
| [vault_kv_secret_v2.cf](https://registry.terraform.io/providers/hashicorp/vault/3.16.0/docs/data-sources/kv_secret_v2) | data source |
| [vault_kv_secret_v2.do](https://registry.terraform.io/providers/hashicorp/vault/3.16.0/docs/data-sources/kv_secret_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cf_vault_mount"></a> [cf\_vault\_mount](#input\_cf\_vault\_mount) | Vault mount where the CloudFlare API token is stored | `string` | n/a | yes |
| <a name="input_cf_vault_name"></a> [cf\_vault\_name](#input\_cf\_vault\_name) | Name of the secret to read with the CloudFlare API token | `string` | n/a | yes |
| <a name="input_cf_zone"></a> [cf\_zone](#input\_cf\_zone) | Name of the zone in cloudflare which we will create a record for krateo in | `string` | n/a | yes |
| <a name="input_do_vault_mount"></a> [do\_vault\_mount](#input\_do\_vault\_mount) | Path of the Vault mount where we have stored the Digital Ocean secret | `string` | n/a | yes |
| <a name="input_do_vault_secret"></a> [do\_vault\_secret](#input\_do\_vault\_secret) | Name of the secret in the Vault mount | `string` | n/a | yes |
| <a name="input_k8s_cluster_name"></a> [k8s\_cluster\_name](#input\_k8s\_cluster\_name) | Name of the cluster to create | `string` | `"krateo-control-plane"` | no |
| <a name="input_k8s_version_prefix"></a> [k8s\_version\_prefix](#input\_k8s\_version\_prefix) | Version prefix for kubernetes cluster | `string` | `"1.25."` | no |
| <a name="input_krateo_endpoint"></a> [krateo\_endpoint](#input\_krateo\_endpoint) | DNS name to use for the Krateo endpoint | `string` | n/a | yes |
| <a name="input_krateo_version"></a> [krateo\_version](#input\_krateo\_version) | Version of the Krateo release to use | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
