output "vm_id" {
  description = "Virtual machine ID"
  value       = yandex_compute_instance.vm.id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = yandex_compute_instance.vm.name
}

output "internal_ip" {
  description = "Internal IP address of the VM"
  value       = yandex_compute_instance.vm.network_interface[0].ip_address
}

output "external_ip" {
  description = "External NAT IP address of the VM"
  value       = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}

output "disk_id" {
  description = "ID of the attached secondary disk"
  value       = yandex_compute_disk.data.id
}
