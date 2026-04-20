env_name    = "stage"
zone        = "ru-central1-a"

# Compute
cores       = 4
memory      = 8
platform_id = "standard-v2"

# Boot disk
boot_disk_size = 30
boot_disk_type = "network-hdd"

# Secondary (attached) disk
disk_size   = 50
disk_type   = "network-hdd"

# OS image — Ubuntu 22.04 LTS (Yandex Cloud public image)
image_id    = "fd8snjpoq85aqde0gqof"

# Network — replace with your actual subnet ID
subnet_id   = "YOUR_SUBNET_ID"

# SSH — replace with your actual public key and preferred OS user
ssh_user       = "ubuntu"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your-key-here"
