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
