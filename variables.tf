# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------
variable "vault_addr" {
  default = "http://127.0.0.1:8200"
}

variable "vault_token" {}

variable "gcp_secret_engine_path" {
  default = "kubex-app/ABCOrg_prod"
}

variable "gcp_admin_roleset" {
    default="gke_admin"
}

variable "project" {
  description = "The project ID where all resources will be launched."
  default     = "active-cove-279318"
}

variable "region" {
  description = "The region for the network. If the cluster is regional, this must be the same region. Otherwise, it should be the region of the zone."
  default     = "asia-southeast1"
}

variable "zone" {
  description = "The location (region or zone) of the GKE cluster."
  default     = "asia-southeast1-a"
}


# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
  default     = "prod-cluster"
}

variable "cluster_description" {
  description = "The description of the Kubernetes cluster."
  type        = string
  default     = "prod"
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to. Available options include logging.googleapis.com/kubernetes, logging.googleapis.com (legacy), and none"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Stackdriver Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting. Available options include monitoring.googleapis.com/kubernetes, monitoring.googleapis.com (legacy), and none"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "horizontal_pod_autoscaling" {
  description = "Whether to enable the horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "http_load_balancing" {
  description = "Whether to enable the http (L7) load balancing addon"
  type        = bool
  default     = true
}

variable "maintenance_start_time" {
  description = "Time window specified for daily maintenance operations in RFC3339 format"
  type        = string
  default     = "05:00"
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable vertical pod autoscaling"
  type        = string
  default     = true
}

# variable "min_auto_scaling_nodes" {
#   description = "The minimum number of nodes for autoscaling"
#   type        = string
#   default     = "1"
# }

# variable "max_auto_scaling_nodes" {
#   description = "The maximum number of nodes for autoscaling"
#   type        = string
#   default     = "5"
# }

# variable "machine_type" {
#   description = "The type of machine to be used in node pool"
#   type        = string
#   default     = "n1-standard-1"
# }

# variable "node_disk_size_gb" {
#   description = "The szie of disk to be given to node in node pool"
#   type        = string
#   default     = "30"
# }

# variable "node_disk_type" {
#   description = "The type of disk to be given to node in node pool"
#   type        = string
#   default     = "pd-standard"
# }

variable "node_image_type" {
  description = "The type of image to be used in node in node pool"
  type        = string
  default     = "COS"
}

variable "cluster_service_account_name" {
  description = "The name of the custom service account used for the GKE cluster. This parameter is limited to a maximum of 28 characters."
  type        = string
  default     = "prod-cluster-cluster-sa"
}

variable "cluster_service_account_description" {
  description = "A description of the custom service account used for the GKE cluster."
  type        = string
  default     = "prod-cluster GKE Cluster Service Account managed by KubeX"
}

# For the example, we recommend a /16 network for the VPC. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.6.0.0/16"
}

# For the example, we recommend a /16 network for the secondary range. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_secondary_cidr_block" {
  description = "The IP address range of the VPC's secondary address range in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.7.0.0/16"
}

# ---------------------------------------------------------------------------------------------------------------------
# TEST PARAMETERS
# These parameters are only used during testing and should not be touched.
# ---------------------------------------------------------------------------------------------------------------------

variable "override_default_node_pool_service_account" {
  description = "When true, this will use the service account that is created for use with the default node pool that comes with all GKE clusters"
  type        = bool
  default     = false
}
