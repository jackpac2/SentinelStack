# Incident Report 03: High Backend Error Rate

## Incident Summary

The backend returned a sustained stream of HTTP `500` responses. The elevated 5xx rate represented a user-visible API failure and triggered the configured error-rate alert.

## Trigger

The incident was reproduced with:

```bash
./scripts/simulate-errors.sh APP_EC2_PUBLIC_OR_PRIVATE_IP 40
```

The script sends one request per second to `/api/error`. This endpoint intentionally raises an application error and returns HTTP `500`.

## Alert Fired

Prometheus fired the `High5xxRate` warning after the backend 5xx rate remained above `0.05` requests per second for one minute.

```promql
sum(
  rate(http_requests_total{
    job="sentinelstack-backend",
    status_code=~"5.."
  }[2m])
) > 0.05
```

Alert delivery was confirmed through Alertmanager and Discord.

## Dashboard Evidence

The `SentinelStack - Backend API Observability` dashboard showed the `Total 5xx Error Rate` panel crossing the red `0.05 req/s` threshold. The status-code breakdown showed HTTP `500` responses.

Evidence:

- [Error simulation traffic](../../screenshots/high%20error%20rate%20testing.png)
- [Discord firing alert](../../screenshots/high%20error%20rate%20discord%20alert.png)

## Log Evidence

The `SentinelStack - Error Logs` and `SentinelStack - Backend/API Logs` dashboards showed the intentional failures through Loki:

```logql
{job="sentinelstack", service="backend"} |~ "(?i)error|exception|failed|fatal"
```

Expected log message:

```text
GET /error failed: Intentional test error for observability validation.
```

Evidence:

- [HTTP 500 error logs](../../screenshots/error%20500%20testing%20grafana%20logs.png)

## Root Cause

The `/api/error` test route intentionally passed an error to the Express error handler. In production, a similar signal could indicate an unhandled application error, a database failure, invalid dependency responses, or a bad deployment.

## Fix

Stop sending traffic to `/api/error`. The alert resolves after the generated 5xx responses leave the rolling Prometheus window.

For a production incident, inspect the Loki error logs, identify the failing route and exception, deploy a targeted fix, and confirm the 5xx rate returns below the threshold.

## Prevention

- Add structured logs with request IDs and route labels.
- Add tests for failure paths and dependency errors.
- Track 5xx rate by route to isolate the failing endpoint faster.
- Use staged deployments and rollback automation for regressions.
