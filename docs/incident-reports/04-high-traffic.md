# Incident Report 04: High Traffic Volume

## Incident Summary

The application received an elevated volume of normal API traffic. The system remained available, but the request-rate increase was visible in Prometheus and Grafana and should be treated as a capacity signal.

## Trigger

The incident was reproduced with:

```bash
./scripts/generate-traffic.sh APP_EC2_PUBLIC_OR_PRIVATE_IP 50
```

The script repeatedly calls:

```text
/api/health
/api/products
/api/orders
```

## Alert Fired

No dedicated `HighTraffic` Prometheus alert currently exists. This incident is dashboard-detected rather than alert-driven.

The absence of an alert is an observability gap: a sudden traffic increase can create CPU pressure or latency before the current downstream alerts fire.

## Dashboard Evidence

The following dashboards expose the traffic increase:

- `SentinelStack Overview`: `Request Rate`
- `SentinelStack - Backend API Observability`: `Total Request Rate`
- `SentinelStack - Backend API Observability`: `Request Rate by Method`
- `SentinelStack - Backend API Observability`: `Request Rate by Route`

Evidence:

- [High traffic test](../../screenshots/high%20traffic%20testing.png)
- [Backend API dashboard](../../screenshots/backend%20api%20grafana%20dashboard.png)

## Log Evidence

Backend request logs increased for the health, products, and orders endpoints:

```logql
{job="sentinelstack", service="backend"}
```

The `SentinelStack - Logs Overview` dashboard can also show the resulting log-rate increase:

```logql
sum(rate({job="sentinelstack"}[5m]))
```

## Root Cause

The traffic generator intentionally sent repeated normal requests to the application. In production, a similar pattern could come from organic growth, a marketing event, an aggressive client, a retry storm, or abusive traffic.

## Fix

Stop the traffic generator and confirm that request rate, CPU usage, latency, and error rate return to their normal ranges.

For a production incident, identify the affected routes and clients, then scale capacity or apply rate limiting based on whether the traffic is legitimate.

## Prevention

- Add a `HighTraffic` Prometheus rule based on an observed normal baseline.
- Add rate limiting at Nginx or an upstream load balancer.
- Add route-level traffic dashboards and client-level visibility where appropriate.
- Define expected capacity and load-test the application before traffic events.
