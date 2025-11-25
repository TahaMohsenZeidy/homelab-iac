variable "pve_endpoint" {
  type = string
  description = "The endpoint of the virtual environment"
  sensitive = true
  default = ""
}

variable "pve_host_username" {
  type = string
  description = "The username for Proxmox VE host"
  sensitive = true
  default = ""
}

variable "pve_host_password" {
  type = string
  description = "The password for Proxmox VE host"
  sensitive = true
  default = ""
}

variable "pve_api_token" {
  type = string
  description = "The API token for Proxmox VE"
  sensitive = true
  default = ""
}


variable "pve_hostname" {
  type = string
  description = "The hostname of the Proxmox VE host"
  default = ""
}

variable "vm_hostname_base" {
  type = string
  description = "The base of the hostname for the VM"
}

variable "vm_cpu_cores" {
  type = number
  description = "The number of CPU cores for the VM"
}

variable "vm_domain" {
  type = string
  description = "The domain for the VM"
}

variable "vm_cpu_type" {
  type = string
  description = "The CPU type for the VM"
}

variable "vm_memory" {
  type = number
  description = "The memory size for the VM"
}

variable "vm_disk_size" {
  type = number
  description = "The disk size for the VM"
}

variable "vm_bridge" {
  type = string
  description = "The bridge for the VM"
}

variable "vm_username" {
  type = string
  description = "The username for the VM"
  default = ""
}

variable "vm_password" {
  type = string
  description = "The password for the VM"
  sensitive = true
  default = ""
}

variable "vm_password_root" {
  type = string
  description = "The root password for the VM"
  sensitive = true
  default = ""
}

variable "homelab_dns_server" {
  type = string
  description = "The DNS server for the homelab"
  default = ""
}

variable "google_dns_server" {
  type = string
  description = "The Google DNS server"
}

variable "use_static_ip" {
  type = bool
  description = "Whether to use a static IP address for the VM"
}

variable "vm_ip_addresses" {
  type = string
  description = "The static IP addresses for the VM (if use_static_ip is true)"
  default = ""
  sensitive = true
}

variable "vm_gateway" {
  type = string
  description = "The gateway for the VM (if use_static_ip is true)"
  default = ""
}

variable "vm_tags" {
  type = list(string)
  description = "The tags for the VM"
  default = []
}

# list of strings of VMs to be created
variable "vms_list" {
  type = map(string)
  description = "List of VMs to be created"
}

variable "vault_addr" {
  type = string
  description = "The address of the Vault server"
  sensitive = true
}

variable "vault_role_id" {
  type = string
  description = "The role ID for the Vault AppRole"
  sensitive = true
}

variable "vault_secret_id" {
  type = string
  description = "The secret ID for the Vault AppRole"
  sensitive = true
}