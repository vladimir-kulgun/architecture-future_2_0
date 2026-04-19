# Non-sensitive environment configuration for stage.
# Sensitive values (subnet_id, ssh_public_key) are injected via TF_VAR_* in CI/CD,
# or exported locally: export TF_VAR_subnet_id=<id>

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

# OS image — Ubuntu 22.04 LTS (Yandex Cloud public image ID)
image_id    = "fd8snjpoq85aqde0gqof"
