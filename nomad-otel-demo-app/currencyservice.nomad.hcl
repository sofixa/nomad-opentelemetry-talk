job "currencyservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "currencyservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 7001
      }
    }

   service {
      provider = "nomad"
      name = "currencyservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "currencyservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-currencyservice"
        image_pull_timeout = "10m"
        ports = ["containerport"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      env {
        CURRENCY_SERVICE_PORT = "${NOMAD_PORT_containerport}"
        OTEL_RESOURCE_ATTRIBUTES = "service.name=currencyservice"
      }

      template {
        data = <<EOF
{{ range nomadService "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 100
      }

    }
  }
}