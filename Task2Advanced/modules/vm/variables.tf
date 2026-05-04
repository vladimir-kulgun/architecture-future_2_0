variable "env_name" {
  description = "Environment name (dev, stage, prod) — used in resource naming"
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
  default     = "network-hdd"

  validation {
    condition     = contains(["network-hdd", "network-ssd", "network-ssd-nonreplicated"], var.disk_type)
    error_message = "disk_type must be one of: network-hdd, network-ssd, network-ssd-nonreplicated."
  }
}

variable "image_id" {
  description = "Boot disk OS image ID"
  type        = string
}

variable "platform_id" {
  description = "VM platform: standard-v2 or standard-v3"
  type        = string
  default     = "standard-v2"

  validation {
    condition     = contains(["standard-v1", "standard-v2", "standard-v3"], var.platform_id)
    error_message = "platform_id must be one of: standard-v1, standard-v2, standard-v3."
  }
}

variable "subnet_id" {
  description = "Subnet ID to attach the VM's network interface"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content (the full key string, e.g. 'ssh-rsa AAAA...')"
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Availability zone (e.g. ru-central1-a)"
  type        = string
  default     = "ru-central1-a"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "network-hdd"
}

variable "ssh_user" {
  description = "OS user that will receive the SSH key via cloud-init"
  type        = string
  default     = "ubuntu"
}
