locals {
  dev_cloud_init = templatefile("${path.module}/templates/cloud-init.yml", {
    vm_user        = var.vm_user
    ssh_public_key = var.ssh_public_key
  })
}

resource "yandex_compute_instance" "vm_dev" {
  name                      = "vm-dev"
  platform_id               = var.platform_id
  zone                      = var.zone
  allow_stopping_for_update = true

  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      type     = var.disk_type
      size     = var.disk_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet["dev"].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg["dev"].id]
  }

  metadata = {
    user-data = local.dev_cloud_init
  }

  labels = {
    environment = "dev"
    project     = "sausage-store"
    managed_by  = "terraform"
  }
}
