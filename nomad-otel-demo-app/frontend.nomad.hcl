job "frontend" {
  type        = "service"
  datacenters = ["dc1"]

  group "frontend" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 8080
      }
    }

   service {
      provider = "nomad"
      name = "frontend"
      tags = [
        "traefik.http.routers.frontend.rule=Host(`frontend.demo`)",
        "traefik.http.routers.frontend.entrypoints=web",
        "traefik.http.routers.frontend.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "frontend" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-frontend"
        image_pull_timeout = "10m"
        ports = ["containerport"]
      }

      restart {
        attempts = 10
        delay    = "5s"
        interval = "5s"
        mode = "delay"
      }

      env {
        ENV_PLATFORM = "local"
        FRONTEND_ADDR = "frontend.demo"
        OTEL_RESOURCE_ATTRIBUTES = "service.name=frontend"
        OTEL_SERVICE_NAME = "frontend"
        PORT = "${NOMAD_PORT_containerport}"
      }

      template {
        data = <<EOF
{{ range nomadService "adservice" }}
AD_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "cartservice" }}
CART_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "checkoutservice" }}
CHECKOUT_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "currencyservice" }}
CURRENCY_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "productcatalogservice" }}
PRODUCT_CATALOG_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "recommendationservice" }}
RECOMMENDATION_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "shippingservice" }}
SHIPPING_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "otelcol-http" }}
PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}/v1/traces"
{{ end }}

EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 1024
        memory_max = 2048
      }

    }
  }
}