# Production Monitoring & Observability Stack

## 📊 **Complete Monitoring Setup**

### **Architecture Overview**

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   Applications  │───▶│  Prometheus  │───▶│   Grafana   │
│   (Metrics)     │    │   (Collect)  │    │ (Visualize) │
└─────────────────┘    └──────────────┘    └─────────────┘
                              │
┌─────────────────┐           │            ┌─────────────┐
│    Jaeger       │           │            │   Alertmanager │
│   (Tracing)     │           │            │   (Alerts)  │
└─────────────────┘           │            └─────────────┘
                              │
┌─────────────────┐           │            ┌─────────────┐
│   Loki/ELK      │───────────┘            │  PagerDuty  │
│   (Logging)     │                        │ (Incidents) │
└─────────────────┘                        └─────────────┘
```

## 🔧 **Implementation Steps**

### **Step 1: Deploy Monitoring Namespace**

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update
```

### **Step 2: Install Prometheus Stack**

```bash
# Install Prometheus with Grafana
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml
```

### **Step 3: Install Jaeger for Distributed Tracing**

```bash
# Install Jaeger
helm install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --values jaeger-values.yaml
```

### **Step 4: Install Loki for Centralized Logging**

```bash
# Install Loki
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml
```

## 📝 **Configuration Files**

### **Prometheus Configuration (prometheus-values.yaml)**

```yaml
# Prometheus monitoring configuration
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    additionalScrapeConfigs: |
      - job_name: 'todo-app-metrics'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)

grafana:
  adminPassword: "admin123" # CHANGE IN PRODUCTION
  persistence:
    enabled: true
    size: 10Gi
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-stack-prometheus:9090
          isDefault: true
        - name: Loki
          type: loki
          url: http://loki:3100
        - name: Jaeger
          type: jaeger
          url: http://jaeger-query:16686

alertmanager:
  config:
    global:
      smtp_smarthost: "localhost:587"
      smtp_from: "alertmanager@todoapp.com"
    route:
      group_by: ["alertname"]
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: "web.hook"
    receivers:
      - name: "web.hook"
        webhook_configs:
          - url: "http://your-webhook-url"
```

### **Application Metrics Integration**

#### Add to your services (example: api-gateway)

```typescript
// Add to api-gateway/src/index.ts
import promClient from "prom-client";

// Create metrics
const register = new promClient.Registry();
const httpRequestDuration = new promClient.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status"],
  buckets: [0.1, 0.5, 1, 2, 5],
});

const httpRequestTotal = new promClient.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"],
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();

  res.on("finish", () => {
    const duration = (Date.now() - start) / 1000;
    const labels = {
      method: req.method,
      route: req.path,
      status: res.statusCode.toString(),
    };

    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
  });

  next();
});

// Metrics endpoint
app.get("/metrics", (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(register.metrics());
});
```

### **Custom Dashboards**

#### Todo App Overview Dashboard (JSON)

```json
{
  "dashboard": {
    "title": "Todo App Overview",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "95th percentile - {{service}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service) * 100",
            "legendFormat": "Error Rate % - {{service}}"
          }
        ]
      },
      {
        "title": "Database Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "pg_stat_database_numbackends",
            "legendFormat": "Active Connections"
          }
        ]
      }
    ]
  }
}
```

### **Alerting Rules**

#### Critical Alerts (alerts.yaml)

```yaml
groups:
  - name: todo-app-alerts
    rules:
      - alert: HighErrorRate
        expr: sum(rate(http_requests_total{status=~"5.."}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "{{ $labels.service }} has error rate above 10%"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "{{ $labels.service }} 95th percentile response time is {{ $value }}s"

      - alert: DatabaseDown
        expr: up{job="postgres"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Database is down"
          description: "PostgreSQL database is not responding"

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is above 80%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is above 85%"
```

### **Distributed Tracing Setup**

#### Jaeger Configuration (jaeger-values.yaml)

```yaml
provisionDataStore:
  cassandra: false
  elasticsearch: true

elasticsearch:
  replicas: 1
  minimumMasterNodes: 1

allInOne:
  enabled: true
  image:
    tag: latest
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
    hosts:
      - jaeger.your-domain.com

agent:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "14271"

collector:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "14268"
```

#### Add Tracing to Applications

```typescript
// Add to your services
import { initTracer } from "jaeger-client";

const config = {
  serviceName: "api-gateway",
  sampler: {
    type: "const",
    param: 1,
  },
  reporter: {
    agentHost: process.env.JAEGER_AGENT_HOST || "jaeger-agent",
    agentPort: process.env.JAEGER_AGENT_PORT || 6832,
  },
};

const tracer = initTracer(config);

// Tracing middleware
app.use((req, res, next) => {
  const span = tracer.startSpan(`${req.method} ${req.path}`);
  span.setTag("http.method", req.method);
  span.setTag("http.url", req.url);

  req.span = span;

  res.on("finish", () => {
    span.setTag("http.status_code", res.statusCode);
    span.finish();
  });

  next();
});
```

## 🚀 **Deployment Commands**

### **Deploy Monitoring Stack**

```bash
# Deploy all monitoring components
kubectl apply -f monitoring/

# Verify deployment
kubectl get pods -n monitoring

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-prometheus 9090:9090

# Access Jaeger
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686
```

### **Configure Ingress for External Access**

```yaml
# monitoring-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - grafana.your-domain.com
        - prometheus.your-domain.com
        - jaeger.your-domain.com
      secretName: monitoring-tls
  rules:
    - host: grafana.your-domain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-stack-grafana
                port:
                  number: 80
    - host: prometheus.your-domain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-stack-prometheus
                port:
                  number: 9090
    - host: jaeger.your-domain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: jaeger-query
                port:
                  number: 16686
```

## 📊 **Key Metrics to Monitor**

### **Application Metrics**

- Request rate (requests/second)
- Response time (95th percentile)
- Error rate (5xx responses)
- Active users
- Database connections
- Cache hit ratio

### **Infrastructure Metrics**

- CPU usage per pod/node
- Memory usage per pod/node
- Disk usage and I/O
- Network throughput
- Pod restart count
- Node availability

### **Business Metrics**

- User registrations
- Todo items created/completed
- API endpoint usage
- Feature adoption rates

## 🎯 **Monitoring Best Practices**

1. **Start with the Four Golden Signals**: Latency, Traffic, Errors, Saturation
2. **Implement SLI/SLO**: Service Level Indicators and Objectives
3. **Create Runbooks**: Document response procedures for each alert
4. **Test Alerting**: Verify alerts trigger correctly
5. **Monitor the Monitors**: Ensure monitoring infrastructure is reliable

**Estimated Setup Time: 1-2 days**
**Estimated Learning Curve: 1 week**
