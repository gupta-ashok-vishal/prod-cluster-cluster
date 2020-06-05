# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PUBLIC CLUSTER IN GOOGLE CLOUD PLATFORM
# This is gke-cluster module to deploy a public Kubernetes cluster in GCP.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # The modules used in this example have been updated with 0.12 syntax, additionally we depend on a bug fixed in
  # version 0.12.7.
  required_version = ">= 0.12.7"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE VAULT
# ---------------------------------------------------------------------------------------------------------------------

provider "vault" {
  address = "${var.vault_addr}"
  token   = "${var.vault_token}"
}

data "vault_generic_secret" "gcp_jwt" {
  path = "${var.gcp_secret_engine_path}/token/${var.gcp_admin_roleset}"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  version = "~> 2.9.0"
  project = "${var.project}"
  region  = "${var.region}"
  access_token = "${data.vault_generic_secret.gcp_jwt.data["token"]}"
}

provider "google-beta" {
  version = "~> 2.9.0"
  project = "${var.project}"
  region  = "${var.region}"
  access_token = "${data.vault_generic_secret.gcp_jwt.data["token"]}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PUBLIC CLUSTER IN GOOGLE CLOUD PLATFORM
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  # source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.2.0"
  source = "./modules/gke-cluster"

  project                             = var.project
  location                            = local.location
  name                                = var.cluster_name
  description                         = var.cluster_description
  logging_service                     = var.logging_service
  monitoring_service                  = var.monitoring_service
  horizontal_pod_autoscaling          = var.horizontal_pod_autoscaling
  http_load_balancing                 = var.http_load_balancing
  maintenance_start_time              = var.maintenance_start_time
  network                             = module.vpc_network.network
  subnetwork                          = module.vpc_network.public_subnetwork
  cluster_secondary_range_name        = module.vpc_network.public_subnetwork_secondary_range_name
  alternative_default_service_account = module.gke_service_account.email
  enable_vertical_pod_autoscaling     = var.enable_vertical_pod_autoscaling
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NODE POOL
# ---------------------------------------------------------------------------------------------------------------------



resource "google_container_node_pool" "node_pool_0" {
  provider = google-beta

  name     = "node-pool-1"
  project  = var.project
  location = local.location
  cluster  = module.gke_cluster.name

  initial_node_count = "1"

  autoscaling {
    min_node_count = 3
    max_node_count = 5
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    labels = {
      all-pools-example = "true"
    }

    # Add a public tag to the instances. See the network access tier table for full details:
    # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
    tags = [
      module.vpc_network.public,
      "public-pool",
    ]

    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}



# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CUSTOM SERVICE ACCOUNT TO USE WITH THE GKE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "gke_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-service-account?ref=v0.2.0"
  source = "./modules/gke-service-account"

  name        = var.cluster_service_account_name
  project     = var.project
  description = var.cluster_service_account_description
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NETWORK TO DEPLOY THE CLUSTER TO
# ---------------------------------------------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "vpc_network" {
  source = "github.com/gruntwork-io/terraform-google-network.git//modules/vpc-network?ref=v0.2.1"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
}

# ---------------------------------------------------------------------------------------------------------------------
# Prepare Kubernetes Provider
# ---------------------------------------------------------------------------------------------------------------------

provider "kubernetes" {
  load_config_file = false

  host                   = "https://${module.gke_cluster.endpoint}"
  token                  = "${data.vault_generic_secret.gcp_jwt.data["token"]}"
  cluster_ca_certificate = module.gke_cluster.cluster_ca_certificate
}

resource "kubernetes_service_account" "cluster_admin_sa" {
  metadata {
    name = "cluster-admin-sa"
  }
}

resource "kubernetes_cluster_role_binding" "cluster_admin_sa_cluster_rb" {
  metadata {
    name = "cluster-admin-sa-clusterRoleBinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-admin-sa"
    namespace = "default"
  }
}

data "kubernetes_secret" "cluster_admin_sa_secret" {
  metadata {
    name = "${kubernetes_service_account.cluster_admin_sa.default_secret_name}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Prepare locals to keep the code cleaner
# ---------------------------------------------------------------------------------------------------------------------

locals {
  location     = var.zone != null ? var.zone : var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_endpoint" {
  description = "The IP address of the cluster master."
  sensitive   = true
  value       = module.gke_cluster.endpoint
}

output "cluster_ca_certificate" {
  description = "The public certificate that is the root of trust for the cluster."
  sensitive   = true
  value       = module.gke_cluster.cluster_ca_certificate
}

output "gcp_service_account" {
  description = "The GCP Service Account used to create the cluster."
  sensitive   = true
  value       = module.gke_service_account.email
}

output "cluster_admin_sa_name" {
  description = "The name of admin service account in k8s cluster."
  sensitive   = true
  value       = kubernetes_service_account.cluster_admin_sa.metadata.0.name
}

output "cluster_admin_sa_secret_token" {
  description = "The token of k8s cluster admin service account."
  sensitive   = true
  value       = data.kubernetes_secret.cluster_admin_sa_secret.data.token
}