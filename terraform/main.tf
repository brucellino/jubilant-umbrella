terraform {
  backend "consul" {
    path = "terraform/personal"
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.34.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.25.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.7"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

variable "do_vault_mount" {
  type        = string
  description = "Path of the Vault mount where we have stored the Digital Ocean secret"
}

variable "do_vault_secret" {
  type        = string
  description = "Name of the secret in the Vault mount"
}

variable "cf_vault_mount" {
  type        = string
  description = "Vault mount where the CloudFlare API token is stored"
}

variable "cf_vault_name" {
  type        = string
  description = "Name of the secret to read with the CloudFlare API token"
}

variable "cf_zone" {
  type        = string
  description = "Name of the zone in cloudflare which we will create a record for krateo in"
}

variable "krateo_version" {
  type        = string
  description = "Version of the Krateo release to use"
  validation {
    condition     = can(regexall("^(?P<major>0|[1-9]\\d*)\\.(?P<minor>0|[1-9]\\d*)\\.(?P<patch>0|[1-9]\\d*)(?:-(?P<prerelease>(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", var.krateo_version))
    error_message = "Version is not a semantic version."
  }

}

variable "krateo_endpoint" {
  type        = string
  description = "DNS name to use for the Krateo endpoint"
}

variable "k8s_cluster_name" {
  type        = string
  description = "Name of the cluster to create"
  default     = "krateo-control-plane"
}

variable "k8s_version_prefix" {
  type        = string
  description = "Version prefix for kubernetes cluster"
  default     = "1.25."
}

data "vault_kv_secret_v2" "do" {
  mount = var.do_vault_mount
  name  = var.do_vault_secret
}

data "vault_kv_secret_v2" "cf" {
  mount = var.cf_vault_mount
  name  = var.cf_vault_name
}

provider "digitalocean" {
  token = data.vault_kv_secret_v2.do.data["terraform"]
}

provider "cloudflare" {
  api_token = data.vault_kv_secret_v2.cf.data["token"]
}
data "digitalocean_kubernetes_versions" "this" {
  version_prefix = var.k8s_version_prefix
  lifecycle {
    postcondition {
      condition     = length(self.valid_versions) > 0
      error_message = "No latest version has been found for this version"
    }
  }
}

data "cloudflare_zone" "k" {
  name = var.cf_zone
}

resource "digitalocean_kubernetes_cluster" "k" {
  name          = var.k8s_cluster_name
  region        = "ams3"
  auto_upgrade  = true
  version       = data.digitalocean_kubernetes_versions.this.latest_version
  ha            = false
  surge_upgrade = true
  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }

  node_pool {
    name       = "default"
    size       = "s-2vcpu-4gb"
    node_count = 3
  }
}

resource "local_file" "k8sconfig" {
  content  = digitalocean_kubernetes_cluster.k.kube_config.0.raw_config
  filename = "${path.module}/kubeconfig-${var.k8s_cluster_name}"
}

locals {
  krateo_release_url = join("/", [
    "https://github.com/krateoplatformops/krateo",
    "releases/download",
    "v${var.krateo_version}",
    "krateo_${var.krateo_version}_linux_amd64.tar.gz"
  ])
}

resource "null_resource" "k_install" {
  triggers = {
    kube_config = local_file.k8sconfig.filename
  }
  provisioner "local-exec" {
    when        = create
    command     = "curl -fSL ${local.krateo_release_url} | tar xz krateo >krateo"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = create
    command     = "echo '${var.cf_zone}' | ./krateo init --kubeconfig ${local_file.k8sconfig.filename}"
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "./krateo uninstall --kubeconfig kubeconfig-krateo-control-plane"
    interpreter = ["/bin/bash", "-c"]
  }
}

# LB created by krateo.
data "digitalocean_loadbalancer" "krateo" {
  depends_on = [null_resource.k_install]
  # id         = "d72d4916-9023-4616-b292-33032dda4799" # <- obtained from the console
  name = "a6434671d1dde4647804e9cd6261d5d6" # <- obtained from the console.
}

resource "cloudflare_record" "k" {
  zone_id = data.cloudflare_zone.k.id
  type    = "A"
  proxied = true
  name    = join(".", ["app", var.cf_zone])
  value   = data.digitalocean_loadbalancer.krateo.ip
}
