job "quoteservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "quoteservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 8090
      }
    }

   service {
      provider = "nomad"
      name = "quoteservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "quoteservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-quoteservice"
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
        OTEL_EXPORTER_OTLP_TRACES_PROTOCOL = "http/protobuf"
        OTEL_PHP_TRACES_PROCESSOR = "simple"
        OTEL_SERVICE_NAME = "quoteservice"
        OTEL_TRACES_EXPORTER = "otlp"
        OTEL_TRACES_SAMPLER = "parentbased_always_on"
        QUOTE_SERVICE_PORT = "${NOMAD_PORT_containerport}"
      }

      template {
        data = <<EOF
{{ range nomadService "otelcol-http" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
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