output "folder_id" {
  description = "ID каталога в Yandex Cloud"
  value       = var.folder_id
}

output "vm_dev_name" {
  description = "Имя dev виртуальной машины"
  value       = yandex_compute_instance.vm_dev.name
}

output "vm_prod_name" {
  description = "Имя prod виртуальной машины"
  value       = yandex_compute_instance.vm_prod.name
}

output "vm_dev_address" {
  description = "Внешний IP-адрес dev виртуальной машины"
  value       = yandex_compute_instance.vm_dev.network_interface[0].nat_ip_address
}

output "vm_prod_address" {
  description = "Внешний IP-адрес prod виртуальной машины"
  value       = yandex_compute_instance.vm_prod.network_interface[0].nat_ip_address
}

output "dev_sg_name" {
  description = "Имя SG для dev"
  value       = yandex_vpc_security_group.sg["dev"].name
}

output "dev_sg_id" {
  description = "ID SG для dev"
  value       = yandex_vpc_security_group.sg["dev"].id
}

output "prod_sg_name" {
  description = "Имя SG для prod"
  value       = yandex_vpc_security_group.sg["prod"].name
}

output "prod_sg_id" {
  description = "ID SG для prod"
  value       = yandex_vpc_security_group.sg["prod"].id
}
