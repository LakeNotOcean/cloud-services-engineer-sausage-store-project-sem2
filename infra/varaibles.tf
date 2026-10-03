variable "folder_id" {
  description = "ID каталога в Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}

variable "catalog_name" {
  description = "Наименование каталога"
  type        = string
  default     = "default"
}

variable "image_id" {
  description = "ID образа для загрузочного диска"
  type        = string
  default     = "d8fpk9lkplfjrc5s2gg"
}

variable "ssh_public_key" {
  description = "Публичный SSH-ключ для доступа к виртуальной машине"
  type        = string
  sensitive   = true
}

variable "vm_user" {
  description = "Имя пользователя виртуальной машины"
  type        = string
  sensitive   = true
}

variable "cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Объём RAM в ГБ"
  type        = number
  default     = 1
}

variable "core_fraction" {
  description = "Доля производительности CPU (%)"
  type        = number
  default     = 5
}

variable "platform_id" {
  description = "Платформа виртуальной машины"
  type        = string
  default     = "standard-v3"
}

variable "disk_type" {
  description = "Тип диска"
  type        = string
  default     = "network-hdd"
}

variable "disk_size" {
  description = "Размер диска в ГБ"
  type        = number
  default     = 20
}
