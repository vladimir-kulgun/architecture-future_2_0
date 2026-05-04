resource "yandex_compute_disk" "data" {
  name = "disk-${var.env_name}"
  type = var.disk_type
  zone = var.zone
  size = var.disk_size
}

resource "yandex_compute_instance" "vm" {
  name        = "vm-${var.env_name}"
  platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores  = var.cores
    memory = var.memory
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.boot_disk_size
      type     = var.boot_disk_type
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.data.id
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    user-data = <<-EOT
    #cloud-config
    users:
      - name: ${var.ssh_user}
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    EOT
  }
}
