# QFC Testnet - AWS Terraform Configuration

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend
  # backend "s3" {
  #   bucket = "qfc-terraform-state"
  #   key    = "testnet/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "QFC"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# VPC
module "vpc" {
  source = "../modules/vpc"

  name               = "qfc-${var.environment}"
  cidr               = var.vpc_cidr
  availability_zones = var.availability_zones

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "production"
}

# EKS Cluster
module "eks" {
  source = "../modules/eks"

  cluster_name    = "qfc-${var.environment}"
  cluster_version = var.eks_cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  node_groups = {
    validators = {
      desired_size = var.validator_count
      min_size     = var.validator_count
      max_size     = var.validator_count + 2
      instance_types = var.validator_instance_types
      disk_size    = var.validator_disk_size
      labels = {
        role = "validator"
      }
    }
    services = {
      desired_size = 2
      min_size     = 1
      max_size     = 4
      instance_types = ["t3.medium"]
      disk_size    = 50
      labels = {
        role = "services"
      }
    }
  }
}

# RDS PostgreSQL for Explorer
module "rds" {
  source = "../modules/rds"

  identifier     = "qfc-${var.environment}-explorer"
  instance_class = var.rds_instance_class

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.eks.cluster_security_group_id]

  database_name = "qfc_explorer"
  username      = "qfc"

  # Enable in production
  multi_az               = var.environment == "production"
  backup_retention_period = var.environment == "production" ? 7 : 1
}

# ElastiCache Redis
module "elasticache" {
  source = "../modules/elasticache"

  cluster_id      = "qfc-${var.environment}"
  node_type       = var.elasticache_node_type
  num_cache_nodes = var.environment == "production" ? 2 : 1

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.eks.cluster_security_group_id]
}

# Application Load Balancer
module "alb" {
  source = "../modules/alb"

  name       = "qfc-${var.environment}"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  # ACM certificate ARN (create manually or via ACM module)
  certificate_arn = var.acm_certificate_arn
}

# Route 53 DNS
resource "aws_route53_record" "rpc" {
  count = var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "rpc.${var.environment}.qfc.network"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "explorer" {
  count = var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "explorer.${var.environment}.qfc.network"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

# Outputs
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "redis_endpoint" {
  value = module.elasticache.endpoint
}

output "alb_dns_name" {
  value = module.alb.dns_name
}
