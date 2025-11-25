### Get Creds for Proxmox VE ###
data "vault_kv_secret_v2" "proxmox_creds_provider" {
  mount = "secret"
  name  = "homelab/proxmox_credentials"
}

locals {
  pve_endpoint = data.vault_kv_secret_v2.proxmox_creds_provider.data["pve_endpoint"]
  pve_api_token = data.vault_kv_secret_v2.proxmox_creds_provider.data["pve_api_token"]
  pve_host_username = data.vault_kv_secret_v2.proxmox_creds_provider.data["pve_host_username"]
  pve_host_password = data.vault_kv_secret_v2.proxmox_creds_provider.data["pve_host_password"]
}
