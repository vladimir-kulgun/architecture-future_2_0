variable "env_name" {
  description = "Environment name — used in resource naming (dev, stage, prod)"
  type        = string
}

variable "cores" {
  description = "Number of vCPU cores"
  type        = number
}

variable "memory" {
  description = "RAM size in GB"
  type        = number
}

variable "disk_size" {
  description = "Secondary (attached) disk size in GB"
  type        = number
}

variable "disk_type" {
  description = "Secondary disk type: network-hdd or network-ssd"
  type        = string
}

variable "image_id" {
  description = "Boot disk OS image ID (Yandex Cloud)"
  type        = string
}

variable "platform_id" {
  description = "VM platform ID: standard-v2 or standard-v3"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to attach the network interface. Passed via TF_VAR_subnet_id in CI."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content passed to cloud-init. Passed via TF_VAR_ssh_public_key in CI."
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "OS user that receives the SSH key"
  type        = string
  default     = "ubuntu"
}

variable "zone" {
  description = "Yandex Cloud availability zone"
  type        = string
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
}

variable "boot_disk_type" {
  description = "Boot disk type: network-hdd or network-ssd"
  type        = string
}
