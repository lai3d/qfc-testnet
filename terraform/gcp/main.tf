# QFC Testnet - GCP Terraform Configuration

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "qfc-${var.environment}"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "main" {
  name          = "qfc-${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# GKE Cluster
resource "google_container_cluster" "main" {
  name     = "qfc-${var.environment}"
  location = var.region

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.main.name

  # Enable Autopilot or use standard mode
  enable_autopilot = var.use_autopilot

  dynamic "node_pool" {
    for_each = var.use_autopilot ? [] : [1]
    content {
      name       = "default-pool"
      node_count = var.validator_count

      node_config {
        machine_type = var.validator_machine_type
        disk_size_gb = var.validator_disk_size

        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform"
        ]

        labels = {
          role = "validator"
        }
      }
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }
}

# Cloud SQL (PostgreSQL)
resource "google_sql_database_instance" "main" {
  name             = "qfc-${var.environment}-explorer"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.cloudsql_tier

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = var.environment == "production"
}

resource "google_sql_database" "explorer" {
  name     = "qfc_explorer"
  instance = google_sql_database_instance.main.name
}

# Memorystore (Redis)
resource "google_redis_instance" "main" {
  name           = "qfc-${var.environment}"
  tier           = var.environment == "production" ? "STANDARD_HA" : "BASIC"
  memory_size_gb = var.redis_memory_gb
  region         = var.region

  authorized_network = google_compute_network.main.id
}

# Cloud DNS
resource "google_dns_managed_zone" "main" {
  count = var.create_dns_zone ? 1 : 0

  name     = "qfc-${var.environment}"
  dns_name = "${var.environment}.qfc.network."
}

# Outputs
output "gke_cluster_name" {
  value = google_container_cluster.main.name
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.main.endpoint
}

output "cloudsql_connection_name" {
  value = google_sql_database_instance.main.connection_name
}

output "redis_host" {
  value = google_redis_instance.main.host
}
