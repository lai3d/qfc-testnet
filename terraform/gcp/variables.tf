# QFC Testnet - GCP Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "testnet"
}

# Network
variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Pods secondary CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "Services secondary CIDR"
  type        = string
  default     = "10.2.0.0/20"
}

# GKE
variable "use_autopilot" {
  description = "Use GKE Autopilot mode"
  type        = bool
  default     = false
}

variable "validator_count" {
  description = "Number of validator nodes"
  type        = number
  default     = 5
}

variable "validator_machine_type" {
  description = "Machine type for validators"
  type        = string
  default     = "e2-standard-4"
}

variable "validator_disk_size" {
  description = "Disk size for validators (GB)"
  type        = number
  default     = 200
}

# Cloud SQL
variable "cloudsql_tier" {
  description = "Cloud SQL tier"
  type        = string
  default     = "db-f1-micro"
}

# Redis
variable "redis_memory_gb" {
  description = "Redis memory (GB)"
  type        = number
  default     = 1
}

# DNS
variable "create_dns_zone" {
  description = "Create Cloud DNS zone"
  type        = bool
  default     = false
}
