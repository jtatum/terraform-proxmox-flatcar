output "vm_id" {
  description = "The ID of the created VM"
  value       = module.flatcar_vm.vm_id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = module.flatcar_vm.vm_name
}

output "vm_ipv4_addresses" {
  description = "IPv4 addresses assigned to the VM (available after the VM starts and the agent reports)"
  value       = module.flatcar_vm.vm_ipv4_addresses
}
