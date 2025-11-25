terraform {

  # Configure remote state in S3
  backend "s3" {
    bucket = "terraform-bucket"
    key    = "k8s-cluster/terraform.tfstate"
    region = "us-east-1"
    skip_region_validation       = true
    skip_credentials_validation  = true
    skip_metadata_api_check      = true
    skip_requesting_account_id   = true
    use_path_style               = true
  }

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.85.1"
    }
    vault = {
      source = "hashicorp/vault"
      version = "5.3.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}