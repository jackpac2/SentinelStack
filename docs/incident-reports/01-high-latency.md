# Incident Report 01: High Backend Latency

## Incident Summary

The backend API experienced elevated response times. Requests to the test endpoint took approximately 2-5 seconds, increasing the p95 latency above the service threshold.

## Trigger

The incident was reproduced with:

```bash
./scripts/simulate-latency.sh APP_EC2_PUBLIC_OR_PRIVATE_IP 30
```

The script sends requests to `/api/slow`. This endpoint intentionally waits for 2-5 seconds before returning a successful response.

## Alert Fired

Prometheus fired the `HighLatency` warning after backend p95 request latency remained above `0.8` seconds for one minute.

```promql
histogram_quantile(
  0.95,
  sum(rate(http_request_duration_seconds_bucket{job="sentinelstack-backend"}[2m])) by (le)
) > 0.8
```

Alert delivery was confirmed through Alertmanager and Discord.

## Dashboard Evidence

The `SentinelStack - Backend API Observability` dashboard showed the p95 latency panel crossing the red `0.8s` threshold.

Evidence:

- [Latency test traffic](../../screenshots/high%20app%20latency%20testing.png)
- [Discord firing alert](../../screenshots/high%20latency%20discord%20alert.png)
- [Discord resolved alert](../../screenshots/high%20latency%20resolved.png)

## Log Evidence

The `SentinelStack - Backend/API Logs` dashboard exposed slow backend request logs through Loki:

```logql
{job="sentinelstack", service="backend"}
```

Expected entries include successful `/slow` requests with elapsed times between approximately `2000ms` and `5000ms`.

## Root Cause

The test route intentionally introduced a blocking delay before returning a response. In a production incident, the same symptom could indicate a slow database query, an overloaded dependency, or synchronous work in the request path.

## Fix

Stop sending traffic to `/api/slow`. The alert resolves after the slow requests leave the rolling Prometheus window and p95 latency remains below the threshold.

## Prevention

- Add route-level latency dashboards and alerts for critical endpoints.
- Add database query timing and dependency timing metrics.
- Apply request timeouts and avoid synchronous long-running work in API handlers.
- Define an API latency SLO and track its error budget.
