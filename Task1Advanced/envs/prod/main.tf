terraform {
  required_version = ">= 1.3"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.90"
    }
  }
}

provider "yandex" {
  zone = var.zone
}

module "vm" {
  source = "../../modules/vm"

  env_name       = var.env_name
  cores          = var.cores
  memory         = var.memory
  disk_size      = var.disk_size
  disk_type      = var.disk_type
  image_id       = var.image_id
  platform_id    = var.platform_id
  subnet_id      = var.subnet_id
  ssh_public_key = var.ssh_public_key
  ssh_user       = var.ssh_user
  zone           = var.zone
  boot_disk_size = var.boot_disk_size
  boot_disk_type = var.boot_disk_type
}

output "vm_id" {
  description = "Virtual machine ID"
  value       = module.vm.vm_id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = module.vm.vm_name
}

output "internal_ip" {
  description = "Internal IP address"
  value       = module.vm.internal_ip
}

output "external_ip" {
  description = "External NAT IP address"
  value       = module.vm.external_ip
}

output "disk_id" {
  description = "Attached secondary disk ID"
  value       = module.vm.disk_id
}
