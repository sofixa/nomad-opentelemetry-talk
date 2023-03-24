# Nomad Observability with OpenTelemetry Demo

This repository contains the demo code and slides from a talk called *Complete observability with OpenTelemetry on Nomad* presented at HashiTalks: France 2023. 

## Contents

### Presentation 

Slides going over how and why OpenTelemetry came to be, what it is, how to deploy it and use it with Nomad, and diagrams of various deployment patterns. 

Written with [Marp](https://marp.app/).

### Nomad jobs

* OpenTelemetry [demo app](https://opentelemetry.io/ecosystem/demo/)

* OpenTelemetry collector (in two versions)

* Services to receive and visualise data collected by OpenTelemetry - Prometheus, Jaeger, Grafana

All of the jobspecs are based on [Adri Villela](https://adri-v.medium.com/)'s conversion to [Nomad jobs](https://github.com/avillela/nomad-conversions), updated to use Nomad's native Service Discovery instead of Consul's.

## How to

To set up the environment - run the OpenTelemetry collector and all services to store and visualise the data collected, as well as Traefik to make accessing everything easier:

```bash
nomad job run -detach otel-demo-app/jobspec/grafana.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/jaeger.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/prometheus.nomad.hcl

nomad job run -detach otel-demo-app/jobspec/otel-collector.nomad.hcl

nomad job run -detach otel-demo-app/jobspec/traefik.nomad.hcl
```

There is also a version of the OpenTelemetry collector using [Lighstep](https://lightstep.com/) for traces, in [otel-collector-with-LS.nomad.hcl](./nomad-otel-demo-app/otel-collector-with-LS.nomad.hcl) that uses a [Nomad Variable](https://developer.hashicorp.com/nomad/docs/concepts/variables) to store Lighstep's access token.

To run the OpenTelemetry demo app:

```bash
nomad job run -detach otel-demo-app/jobspec/redis.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/ffspostgres.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/adservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/cartservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/currencyservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/emailservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/featureflagservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/paymentservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/productcatalogservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/quoteservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/shippingservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/checkoutservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/recommendationservice.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/frontend.nomad.hcl
nomad job run -detach otel-demo-app/jobspec/frontendproxy.nomad.hcl
```

To run the load generator that will simulate requests to demonstrate how real world telemetry data would look like:

```bash
nomad job run -detach otel-demo-app/jobspec/loadgenerator.nomad.hcl
```

Once all the jobs have been run, you can confirm all are successfully running in Nomad with `nomad job status`. 
To check the data that has been generated and received, you can consult Prometheus, Jaeger, Grafana and/or Lighstep's UIs at their respective addresses. To make that easier we've also deployed a Traefik instance that is connected to Nomad's Service Discovery and will automatically route requests based on the service configuration (found in the tags in the `service` block), with the default configuration being `${servicename}.demo`. To use the default `.demo` TLD, you'd need to add `/etc/hosts` entries pointing to the Nomad client running Traefik, e.g. `echo "127.0.0.1 prometheus.demo" >> /etc/hosts`.

## License

MIT License, cf. [LICENSE](./LICENSE)