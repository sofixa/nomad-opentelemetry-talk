# This version of the OTel Collector alson includes configs
# for sending traces to Lightstep
job "otel-collector" {
  region = "global"

  datacenters = ["dc1"]
  namespace   = "default"

  type = "service"

  group "otel-collector" {
    count = 1
    network {
      mode = "host"
      port "healthcheck" {
        to = 13133
      }
      port "jaeger-compact" {
        to = 6831
      }
      port "jaeger-grpc" {
        to = 14250
      }
      port "jaeger-thrift" {
        to = 14268
      }
      port "metrics" {
        to = 8888
      }
      port "otlp" {
        to = 4317
      }
      port "otlp-http" {
        to = 4318
      }
      port "prometheus" {
        to = 9464
      }
      port "zipkin" {
        to = 9411
      }
    }
    
    task "otel-collector" {
      driver = "docker"

      config {
        image = "otel/opentelemetry-collector-contrib:0.64.1"
        image_pull_timeout = "25m"
        entrypoint = [
          "/otelcol-contrib",
          "--config=local/config/otel-collector-config.yaml",
        ]
        ports = [
          "otlp-http",
          "zipkin",
          "healthcheck",
          "jaeger-compact",
          "jaeger-grpc",
          "jaeger-thrift",
          "prometheus",
          "metrics",
          "otlp"
        ]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      env {
        HOST_DEV = "/hostfs/dev"
        HOST_ETC = "/hostfs/etc"
        HOST_PROC = "/hostfs/proc"
        HOST_RUN = "/hostfs/run"
        HOST_SYS = "/hostfs/sys"
        HOST_VAR = "/hostfs/var"
    }

      template {
        data = <<EOH
receivers:
  otlp:
    protocols:
      grpc:
      http:
        endpoint: "0.0.0.0:4318"

processors:
  batch:
    timeout: 10s
  spanmetrics:
    metrics_exporter: prometheus

  memory_limiter:
    # 75% of maximum memory up to 4G
    limit_mib: 1536
    # 25% of limit up to 2G
    spike_limit_mib: 512
    check_interval: 5s
  attributes/nomad:
    actions:
      - key: "nomad.region"
        action: "insert"
        value: "{{ env "NOMAD_REGION" }}"
      - key: "nomad.dc"
        action: "insert"
        value: "{{ env "NOMAD_DC" }}"

exporters:
  logging:
    verbosity: detailed

  prometheus:
    endpoint: "0.0.0.0:{{ env "NOMAD_PORT_prometheus" }}"

  otlp/jaeger:
    endpoint: '{{ range nomadService "jaeger-collector" }}{{ .Address }}:{{ .Port }}{{ end }}'
    tls:
      insecure: true

  otlp/ls:
    endpoint: ingest.lightstep.com:443
    headers: 
      "lightstep-access-token": "{{ with nomadVar "nomad/jobs/otel-collector" }}{{ .lighstep_access_token }}{{ end }}"

extensions:
  health_check:
    endpoint: 0.0.0.0:{{ env "NOMAD_PORT_healthcheck" }}

service:
  extensions: [health_check]
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [attributes/nomad, batch]
      exporters: [prometheus, logging, otlp/ls]
    traces:
      receivers: [otlp]
      processors: [attributes/nomad, spanmetrics, batch]
      exporters: [logging, otlp/jaeger, otlp/ls]

EOH

        change_mode   = "restart"
        destination = "local/config/otel-collector-config.yaml"
      }

      resources {
        cpu    = 55
        memory = 150
      }

     service {
      provider = "nomad"
        name = "otelcol-metrics"
        port = "metrics"
        tags = ["metrics"]
      }
     service {
      provider = "nomad"
        name = "otelcol-prometheus"
        port = "prometheus"
        tags = ["prometheus"]
      }      
     service {
      provider = "nomad"
        // name = "opentelemetry-collector"
        port = "zipkin"
        tags = ["zipkin"]
      }
     service {
      provider = "nomad"
        // name = "opentelemetry-collector"
        port = "jaeger-compact"
        tags = ["jaeger-compact"]
      }
     service {
      provider = "nomad"
        // name = "opentelemetry-collector"
        port = "jaeger-grpc"
        tags = ["jaeger-grpc"]
      }
     service {
      provider = "nomad"
        // name = "opentelemetry-collector"
        port = "jaeger-thrift"
        tags = ["jaeger-thrift"]
      }
     service {
      provider = "nomad"
        name = "otelcol-grpc"
        tags = [
          "traefik.tcp.routers.otel-collector-grpc.rule=HostSNI(`*`)",
          "traefik.tcp.routers.otel-collector-grpc.entrypoints=grpc",
          "traefik.enable=true",
        ]        
        port = "otlp"
      }

     service {
      provider = "nomad"
        name = "otelcol-http"
        tags = [
          "traefik.http.routers.otel-collector-http.rule=Host(`otel-collector-http.demo`)",
          "traefik.http.routers.otel-collector-http.entrypoints=web",
          "traefik.http.routers.otel-collector-http.tls=false",
          "traefik.enable=true",
        ]
        port = "otlp-http"
      }

     service {
      provider = "nomad"
        name = "otelcol-health"
        port = "healthcheck"
                                
        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "5s"
        }
      }
    }
  }
}
