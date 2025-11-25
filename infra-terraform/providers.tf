### Vault Provider Configuration ###
provider "vault" {
  address         = var.vault_addr
  skip_tls_verify = true 
  skip_child_token = true   
  auth_login {
    path = "auth/approle/login"
    parameters = {
      role_id   = var.vault_role_id   
      secret_id = var.vault_secret_id
    }
  }
}

### Proxmox Provider Configuration ###
provider "proxmox" {
  endpoint  = local.pve_endpoint
  api_token = local.pve_api_token
  insecure  = true
  ssh {
    agent    = true
    username = local.pve_host_username
    password = local.pve_host_password
  }
}

### AWS Provider Configuration ###
provider "aws" {
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
}