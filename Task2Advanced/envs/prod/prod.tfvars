# Non-sensitive environment configuration for prod.
# Sensitive values (subnet_id, ssh_public_key) are injected via TF_VAR_* in CI/CD,
# or exported locally: export TF_VAR_subnet_id=<id>

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

# OS image — Ubuntu 22.04 LTS (Yandex Cloud public image ID)
image_id    = "fd8snjpoq85aqde0gqof"
