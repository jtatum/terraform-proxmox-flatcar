output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.flatcar_vm.vm_id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_virtual_environment_vm.flatcar_vm.name
}

output "vm_status" {
  description = "The status of the VM"
  value       = proxmox_virtual_environment_vm.flatcar_vm.started ? "running" : "stopped"
}

output "proxmox_node" {
  description = "The Proxmox node where the VM is located"
  value       = proxmox_virtual_environment_vm.flatcar_vm.node_name
}

output "vm_ipv4_addresses" {
  description = "IPv4 addresses assigned to the VM (available after VM starts and agent reports)"
  value       = try(proxmox_virtual_environment_vm.flatcar_vm.ipv4_addresses, [])
}

output "ignition_config" {
  description = "The generated Ignition configuration"
  value       = data.ct_config.ignition.rendered
  sensitive   = true
}
