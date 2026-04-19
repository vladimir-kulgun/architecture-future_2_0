# S3 backend configuration for prod environment.
# Credentials are NOT stored here — they are passed via environment variables:
#   AWS_ACCESS_KEY_ID     = Yandex Cloud static key ID
#   AWS_SECRET_ACCESS_KEY = Yandex Cloud static secret key

endpoint = "https://storage.yandexcloud.net"
bucket   = "tfstate-future20"
key      = "envs/prod/terraform.tfstate"
region   = "ru-central1"

skip_region_validation      = true
skip_credentials_validation = true
skip_requesting_account_id  = true
skip_s3_checksum            = true
