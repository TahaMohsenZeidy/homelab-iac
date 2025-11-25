output "vm_ip_addresses" {
  value = { for vm_id, vm_name in var.vms_list : vm_name => proxmox_virtual_environment_vm.alma_vm[vm_id].ipv4_addresses[1][0] }
  #value = proxmox_virtual_environment_vm.alma_vm.ipv4_addresses[1][0]
}

output "vm_id" {
  value = { for vm_id, vm_name in var.vms_list : vm_name => proxmox_virtual_environment_vm.alma_vm[vm_id].vm_id }
  #value = proxmox_virtual_environment_vm.alma_vm.vm_id
}
