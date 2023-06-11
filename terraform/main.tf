terraform {
  backend "consul" {
    path = "terraform/personal"
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.28.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.16.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
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
  type = string
  description = "Version of the Krateo release to use"
  validation {
    condition = can(regexall("^(?P<major>0|[1-9]\\d*)\\.(?P<minor>0|[1-9]\\d*)\\.(?P<patch>0|[1-9]\\d*)(?:-(?P<prerelease>(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"), var.krateo_version)
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
  token = data.vault_kv_secret_v2.cf.data["token"]
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

data "cloudflare_zones" "k" {
  name = var.cf_zone
}

resource "digitalocean_kubernetes_cluster" "k" {
  name         = var.k8s_cluster_name
  region       = "ams3"
  auto_upgrade = true
  version      = data.digitalocean_kubernetes_versions.this.latest_version
  ha           = false
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

resource "local_file" "k8config" {
  content  = digitalocean_kubernetes_cluster.k.kube_config.0.raw_config
  filename = "${path.module}/kubeconfig-${var.k8s_cluster_name}"
}

# Get the krateo release asset by tag name.
data "http" "krateo" {
  url = "https://api.github.com/repos/krateoplatformops/krateo/releases/tags/${krateo_release_version}"
  lifecycle {
    postcondition {
      condition     = contains([201, 204], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

locals {
  release_url
}

data "http" "krateo_asset" {
  
}

# resource "null_resource" "k_install" {
#   triggers = {
#     k8s_endpoint = digitalocean_kubernetes_cluster.k.urn
#   }

#   provisioner "local_exec" 
# }

# resource "cloudflare_record" "k" {
#   zone_id = data.cloudflare_zones.k.id
#   name    = var.krateo_endpoint
#   # value  = # LB created by krateo.

# }
