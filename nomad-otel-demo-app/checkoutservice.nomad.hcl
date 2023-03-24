job "checkoutservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "checkoutservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 5050
      }
    }

   service {
      provider = "nomad"
      name = "checkoutservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "checkoutservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-checkoutservice"
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
        CHECKOUT_SERVICE_PORT = "${NOMAD_PORT_containerport}"
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        OTEL_SERVICE_NAME = "checkoutservice"
      }

      template {
        data = <<EOF
{{ range nomadService "cartservice" }}
CART_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "currencyservice" }}
CURRENCY_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "emailservice" }}
EMAIL_SERVICE_ADDR = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "paymentservice" }}
PAYMENT_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "productcatalogservice" }}
PRODUCT_CATALOG_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "shippingservice" }}
SHIPPING_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }


      resources {
        cpu    = 55
        memory = 450
        memory_max = 600
      }
    }
  }
}