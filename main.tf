terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# 1. Stiahni Image (ako 'docker pull nginx')
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# 2. Spusti Kontajner (ako 'docker run ...')
resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "moj-tofu-server"

  ports {
    internal = 80
    external = 8080
  }
}

# 1. Vytvoríme spoločnú sieť, aby sa kontajnery videli
resource "docker_network" "monitoring_net" {
  name = "monitoring_network"
}

# 2. Stiahneme Image pre Prometheus
resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
  keep_locally = false
}

# 3. Spustíme Prometheus
resource "docker_container" "prometheus" {
  name  = "prometheus_server"
  image = docker_image.prometheus.image_id
  
  # Pripojíme našu sieť
  networks_advanced {
    name = docker_network.monitoring_net.name
  }

  # Otvoríme port 9090 (štandard pre Prometheus)
  ports {
    internal = 9090
    external = 9090
  }

  # Tu "namapujeme" náš lokálny konfiguračný súbor do vnútra kontajnera
  volumes {
    host_path      = "${abspath(path.cwd)}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

# 4. Stiahneme Image pre Grafanu
resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
  keep_locally = false
}

# 5. Spustíme Grafanu
resource "docker_container" "grafana" {
  name  = "grafana_server"
  image = docker_image.grafana.image_id

  networks_advanced {
    name = docker_network.monitoring_net.name
  }

  # Grafana beží na porte 3000
  ports {
    internal = 3000
    external = 3000
  }
  
  # Grafana potrebuje chvíľu na štart, závisí od siete
  depends_on = [
    docker_network.monitoring_net
  ]
}
