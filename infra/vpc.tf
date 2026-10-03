resource "yandex_vpc_network" "network" {
  name = "sausage-store-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "sausage-store-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = var.v4_cidr_blocks
}

locals {
  # общие правила
  sg_common_rules = {
    ingress = [
      {
        description = "Allow SSH"
        protocol    = "TCP"
        port        = 22
      },
      {
        description = "Allow HTTP on port 8200"
        protocol    = "TCP"
        port        = 8200
      }
    ]
    egress = [
      {
        description = "Allow all outgoing traffic"
        protocol    = "ANY"
        from_port   = 0
        to_port     = 65535
      }
    ]
  }

  # описание окружений
  environments = {
    dev = {
      subnet_name = "dev-subnet"
      v4_cidr     = "192.168.10.0/24"
      sg_name     = "dev-sg"
      labels = {
        environment = "dev"
        project     = "sausage-store"
        managed_by  = "terraform"
      }
    }
    prod = {
      subnet_name = "dev-subnet"
      v4_cidr     = "192.168.20.0/24"
      sg_name     = "prod-sg"
      labels = {
        environment = "prod"
        project     = "sausage-store"
        managed_by  = "terraform"
      }
    }
  }
}

# подсети для окружений
resource "yandex_vpc_subnet" "subnet" {
  for_each       = local.environments
  name           = each.value.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [each.value.v4_cidr]
  labels         = each.value.labels
}

# группы для окружений
resource "yandex_vpc_security_group" "sg" {
  for_each   = local.environments
  name       = each.value.sg_name
  network_id = yandex_vpc_network.network.id

  dynamic "ingress" {
    for_each = local.sg_common_rules.ingress
    content {
      description    = ingress.value.description
      protocol       = ingress.value.protocol
      v4_cidr_blocks = ["0.0.0.0/0"]
      port           = ingress.value.port
    }
  }

  dynamic "egress" {
    for_each = local.sg_common_rules.egress
    content {
      description    = egress.value.description
      protocol       = egress.value.protocol
      v4_cidr_blocks = ["0.0.0.0/0"]
      from_port      = egress.value.from_port
      to_port        = egress.value.to_port
    }
  }

  labels = each.value.labels
}
