

```yaml
groups:
  - name: Blackbox 监控告警
    rules:
    - alert: BlackboxSlowProbe
      expr: avg_over_time(probe_duration_seconds[1m]) > 2
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: telnet (instance {{ $labels.instance }}) 超时1秒
        description: "VALUE = {{ $value }}n  LABELS = {{ $labels }}"
    - alert: BlackboxProbeHttpFailure
      expr: probe_http_status_code <= 199 OR probe_http_status_code >= 500
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: HTTP 状态码 (instance {{ $labels.instance }})
        description: "HTTP status code is not 200-499n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
    - alert: BlackboxSslCertificateWillExpireSoon
      expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 30
      for: 30m
      labels:
        severity: warning
      annotations:
        summary:  域名证书即将过期 (instance {{ $labels.instance }})
        description: "域名证书30天后过期n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
    - alert: BlackboxSslCertificateWillExpireSoon
      expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 7
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: 域名证书即将过期 (instance {{ $labels.instance }})
        description: "域名证书7天后过期n VALUE = {{ $value }}n  LABELS = {{ $labels }}"
    - alert: BlackboxSslCertificateExpired
      expr: probe_ssl_earliest_cert_expiry - time() <= 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: 域名证书已过期 (instance {{ $labels.instance }})
        description: "域名证书已过期n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
    - alert: BlackboxProbeSlowHttp
      expr: avg_over_time(probe_http_duration_seconds[1m]) > 10
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: HTTP请求超时 (instance {{ $labels.instance }})
        description: "HTTP请求超时超过10秒n  VALUE = {{ $value }}n  LABELS = {{ $labels }}"
```

