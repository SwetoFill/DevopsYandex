terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.105.0"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Создаем сеть
resource "yandex_vpc_network" "network" {
  name = "network"
}

# Создаем подсеть
resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Создаем три виртуальные машины
resource "yandex_compute_instance" "vm" {
  count = 3
  name  = "vm${count.index + 1}"
  zone  = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd865v46cboopthn7u0k"  # Ubuntu 20.04 LTS
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

# Выводим внешние IP-адреса созданных машин
output "external_ip_addresses" {
  value = yandex_compute_instance.vm[*].network_interface.0.nat_ip_address
} 