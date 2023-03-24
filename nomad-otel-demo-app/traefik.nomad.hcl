job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "svc" {
    count = 1

    network {
      mode = "host"

      port "http" {
        static = 80
      }

      port "api" {
        static = 8080
      }

      port "metrics" {
        static = 8082
      }

      port "grpc" {
        static = 7233
      }

    }

   service {
      provider = "nomad"
      name = "traefik-entrypoint-grpc"
      port = "grpc"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

   service {
      provider = "nomad"
      name = "traefik-dashboard"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.dashboard.rule=Host(`traefik.demo:8080`)",
        "traefik.http.routers.dashboard.service=api@internal",
        "traefik.http.routers.dashboard.entrypoints=web",
      ]

      port = "http"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "loadbalancer" {
      driver = "docker"

      config {
        network_mode = "host"
        image        = "traefik:v2.9.8"
        ports        = ["http", "api", "metrics", "grpc"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.web]
    address = ":80"
    [entryPoints.metrics]
    address = ":8082"
    [entryPoints.grpc]
    address = ":7233"


[api]
    dashboard = true
    insecure  = true

[log]
    level = "DEBUG"
# Enable Consul Catalog configuration backend.
[providers.nomad]
    prefix           = "traefik"
    exposedByDefault = false

    [providers.consulCatalog.endpoint]
      address = "http://localhost:4646"
      scheme  = "http"
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 50
        memory = 75
      }
    }
  }
}
