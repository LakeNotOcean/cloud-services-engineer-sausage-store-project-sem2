terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.89.0"
    }
  }
}

provider "yandex" {
  zone                     = var.zone
  folder_id                = var.folder_id
  service_account_key_file = "authorized_key.json"
}
