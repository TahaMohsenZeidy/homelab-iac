##### Terraform variables for VM configuration #####
vms_list = {
    150 = "master1"
    151 = "worker1" 
    152 = "worker2" 
}
google_dns_server = "8.8.8.8"
vm_hostname_base = "k8s-"
vm_domain   = "homelab.local"
vm_cpu_cores = 2
vm_cpu_type = "host"
vm_memory   = 2
vm_disk_size = 32
vm_bridge  = "vmbr0"

use_static_ip = true
##### Terraform variables for VM configuration #####



