job "recommendationservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "recommendationservice" {
    count = 1

    // update {
    //   healthy_deadline  = "20m"
    //   progress_deadline = "25m"
    // }

    network {
      mode = "host"

      port "containerport" {
        to = 9001
        static = 9001
      }
    }

   service {
      provider = "nomad"
      name = "recommendationservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "recommendationservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-recommendationservice"
        // https://developer.hashicorp.com/nomad/docs/drivers/docker#image_pull_timeout
        image_pull_timeout = "15m"
        ports = ["containerport"]
      }

      // https://developer.hashicorp.com/nomad/docs/job-specification/restart#restart-parameters
      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }
      env {
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        OTEL_METRICS_EXPORTER = "otlp"
        OTEL_PYTHON_LOG_CORRELATION = "true"
        OTEL_SERVICE_NAME = "recommendationservice"
        OTEL_TRACES_EXPORTER = "otlp"
        PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python"
        RECOMMENDATION_SERVICE_PORT = "${NOMAD_PORT_containerport}"
      }

      template {
        data = <<EOF
{{ range nomadService "featureflagservice-grpc" }}
FEATURE_FLAG_GRPC_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "productcatalogservice" }}
PRODUCT_CATALOG_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range nomadService "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 300
        memory_max = 500
      }

    }
  }
}