env_name    = "prod"
zone        = "ru-central1-a"

# Compute
cores       = 8
memory      = 16
platform_id = "standard-v3"

# Boot disk
boot_disk_size = 50
boot_disk_type = "network-ssd"

# Secondary (attached) disk
disk_size   = 100
disk_type   = "network-ssd"

# OS image — Ubuntu 22.04 LTS (Yandex Cloud public image)
image_id    = "fd8snjpoq85aqde0gqof"

# Network — replace with your actual subnet ID
subnet_id   = "YOUR_SUBNET_ID"

# SSH — replace with your actual public key and preferred OS user
ssh_user       = "ubuntu"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your-key-here"
