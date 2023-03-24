job "featureflagservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "featureflagservice" {
    count = 1

    network {
      mode = "host"

      port "http" {
        to = 8081
      }
      port "grpc" {
        to = 50053
      }
    }

   service {
      provider = "nomad"
      name = "featureflagservice-http"
      port = "http"
      tags = [
        "traefik.http.routers.featureflagservice.rule=Host(`feature.demo`)",
        "traefik.http.routers.featureflagservice.entrypoints=web",
        "traefik.http.routers.featureflagservice.tls=false",
        "traefik.enable=true",
      ]

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

   service {
      provider = "nomad"
      name = "featureflagservice-grpc"
      port = "grpc"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "featureflagservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-featureflagservice"
        image_pull_timeout = "10m"
        ports = ["http", "grpc"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      env {
        FEATURE_FLAG_GRPC_SERVICE_PORT = "${NOMAD_PORT_grpc}"
        FEATURE_FLAG_SERVICE_PATH_ROOT = "\"/feature\""
        FEATURE_FLAG_SERVICE_PORT = "${NOMAD_PORT_http}"
        OTEL_EXPORTER_OTLP_TRACES_PROTOCOL = "grpc"
        OTEL_SERVICE_NAME = "featureflagservice"
      }

      template {
        data = <<EOF
{{ range nomadService "ffspostgres-service" }}
DATABASE_URL = "ecto://ffs:ffs@{{ .Address }}:{{ .Port }}/ffs"
{{ end }}

{{ range nomadService "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 250
      }

    }
  }
}