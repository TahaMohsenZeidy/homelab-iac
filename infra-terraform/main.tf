data "vault_kv_secret_v2" "vm_creds" {
  mount = "secret"
  name  = "homelab/vm_credentials"
}

data "vault_kv_secret_v2" "proxmox_creds" {
  mount = "secret"
  name  = "homelab/proxmox_credentials"
}

# ssh public key to be injected into VMs
data "local_file" "ssh_public_key" {
  filename = "${path.module}/ssh/id_rsa.pub"
}

# Change VM IP addresses from string to a map: ID => IP
locals {
  vm_ips = split(",", data.vault_kv_secret_v2.vm_creds.data["vm_ip_addresses"])
  vm_ip_map = {
    for idx, vm_id in keys(var.vms_list) : vm_id => local.vm_ips[idx]
  }
}

# Cloud-init config file for VM initialization
resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  for_each  = var.vms_list
  content_type = "snippets"
  datastore_id = "local"
  node_name    = data.vault_kv_secret_v2.proxmox_creds.data["pve_hostname"]

  # Get cloud-init config from a template file
  source_raw {
    file_name = "user-data-${each.key}.yaml"
    data = templatefile("${path.module}/templates/user_data.tftpl", {
      ssh_public_key = data.local_file.ssh_public_key.content
      hostname       = "${var.vm_hostname_base}${each.value}"
      domain        = var.vm_domain
      username      = data.vault_kv_secret_v2.vm_creds.data["vm_username"]
      password_hash = data.vault_kv_secret_v2.vm_creds.data["vm_password"]
#      root_password_hash = data.vault_kv_secret_v2.vm_creds.data["vm_root_password"]
    })
  }
}
# VM Definition
resource "proxmox_virtual_environment_vm" "alma_vm" {
  for_each = var.vms_list
  name        = "${var.vm_hostname_base}${each.value}"
  description = "VM Managed by Terraform"
  tags        = var.vm_tags
  node_name = data.vault_kv_secret_v2.proxmox_creds.data["pve_hostname"]
  vm_id     = each.key
  agent {
    enabled = true
    timeout = "120s"
    trim = true
  }
  stop_on_destroy = true
  clone {
    vm_id = 200  # ID of the template VM to clone from
    full  = true # clone the full VM, including disks and network interfaces
  }
  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }
  cpu {
    cores        = var.vm_cpu_cores
    type         = var.vm_cpu_type
  }
  # change value from mib to gib
  memory {
    dedicated = ( strcontains(each.value, "master") ? var.vm_memory + 2 : var.vm_memory) * 1024
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.vm_disk_size
  }
  initialization {
    datastore_id = "local-lvm"
    ip_config {
      # get ips from ${data.vault_kv_secret_v2.vm_creds.data["vm_ip_addresses"]} 
      ipv4 {
        address = var.use_static_ip ? "${local.vm_ip_map[each.key]}/24" : "dhcp"
        gateway = var.use_static_ip ? "${data.vault_kv_secret_v2.vm_creds.data["vm_gateway"]}" : ""
      }
    }
    dns {
      servers = ["${data.vault_kv_secret_v2.vm_creds.data["homelab_dns_server"]}", "${var.google_dns_server}"]
    }
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config[each.key].id
  }
  network_device {
    bridge = var.vm_bridge
  }
  serial_device {}
}

# # Fill DNS records for VMs
# resource "local_file" "dns_records" {
#   content = join("\n", [
#     for vm_key, vm_name in var.vms_list :
#     "${proxmox_virtual_environment_vm.alma_vm[vm_key].ipv4_addresses[1][0]}    ${var.vm_hostname_base}${vm_name}.${var.vm_domain} ${var.vm_hostname_base}${vm_name}"
#   ])
#   filename = "${path.module}/infra-data/dns_records"
#   depends_on = [proxmox_virtual_environment_vm.alma_vm]
# }

# # Fill inventory file for Ansible
# resource "local_file" "ansible_inventory" {
#   content = templatefile("${path.module}/templates/inventory.tftpl", {
#     masters = [
#       for vm_key, vm_name in var.vms_list :
#       "${var.vm_hostname_base}${vm_name} ansible_host=${proxmox_virtual_environment_vm.alma_vm[vm_key].ipv4_addresses[1][0]}"
#       if startswith(vm_name, "master")
#     ]
#     workers = [
#       for vm_key, vm_name in var.vms_list :
#       "${var.vm_hostname_base}${vm_name} ansible_host=${proxmox_virtual_environment_vm.alma_vm[vm_key].ipv4_addresses[1][0]}"
#       if startswith(vm_name, "worker")
#     ]
#   })
#   filename = "${path.module}/infra-data/inventory.ini"
#   depends_on = [proxmox_virtual_environment_vm.alma_vm]
# }


# Store DNS records in Minio
resource "aws_s3_object" "dns_records" {
  bucket = "ansible-bucket"
  key    = "dns-records/dns-records.txt"
  content = join("\n", [
    for vm_key, vm_name in var.vms_list :
    "${proxmox_virtual_environment_vm.alma_vm[vm_key].ipv4_addresses[1][0]}    ${var.vm_hostname_base}${vm_name}.${var.vm_domain} ${var.vm_hostname_base}${vm_name}"
  ])
  depends_on = [proxmox_virtual_environment_vm.alma_vm]
}

# Store Ansible inventory in Minio
resource "aws_s3_object" "ansible_inventory" {
  bucket = "ansible-bucket"
  key    = "inventory/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    masters = [
      for vm_key, vm_name in var.vms_list :
      "${var.vm_hostname_base}${vm_name} ansible_host=${proxmox_virtual_environment_vm.alma_vm[vm_key].ipv4_addresses[1][0]}"
      if startswith(vm_name, "master")
    ]
    workers = [
      for vm_key, vm_name in var.vms_list :
      "${var.vm_hostname_base}${vm_name} ansible_host=${proxmox_virtual_environment_vm.alma_vm[vm_key].ipv4_addresses[1][0]}"
      if startswith(vm_name, "worker")
    ]
  })
  depends_on = [proxmox_virtual_environment_vm.alma_vm]
}

