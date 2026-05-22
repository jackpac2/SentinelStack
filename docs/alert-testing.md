# SentinelStack Alert Testing

This guide explains how to validate SentinelStack alerts in a demo EC2 environment.

Confirm alerts in these places:

- Prometheus: `http://MONITORING_EC2_PUBLIC_IP:9090/alerts`
- Alertmanager: `http://MONITORING_EC2_PUBLIC_IP:9093`
- Grafana: `http://MONITORING_EC2_PUBLIC_IP:3000`
- Discord: configured webhook channel

Before testing, confirm the monitoring stack is running:

```bash
./scripts/check-monitoring-node.sh
```

Generate normal traffic first:

```bash
./scripts/generate-traffic.sh APP_EC2_PUBLIC_OR_PRIVATE_IP 50
```

## BackendDown

Purpose: proves Prometheus detects when the backend metrics endpoint is unavailable.

On the app node:

```bash
docker stop sentinelstack-backend
```

Wait about 1-2 minutes, then check Prometheus Alerts, Alertmanager, and Discord.

Cleanup:

```bash
docker start sentinelstack-backend
```

## HighCPUUsage

Purpose: proves node-exporter host metrics can trigger infrastructure alerts.

Run on the app node:

```bash
./scripts/simulate-cpu-spike.sh 180 2
```

On very small EC2 instances this should push CPU over the demo threshold. If it does not fire, increase workers:

```bash
./scripts/simulate-cpu-spike.sh 180 4
```

Cleanup is automatic when the script exits. Manual cleanup:

```bash
docker rm -f sentinelstack-cpu-spike
```

## HighMemoryUsage

Purpose: proves node-exporter memory metrics can trigger infrastructure alerts.

This alert is intentionally not simulated by default because memory pressure can destabilize a small EC2 instance. To test it safely, temporarily lower the `HighMemoryUsage` threshold in `infrastructure/monitoring-node/configs/prometheus/rules/app-alerts.yml`, restart Prometheus, then restore the threshold.

```bash
docker compose \
  --env-file infrastructure/monitoring-node/.env \
  -f infrastructure/monitoring-node/docker-compose.yml \
  restart prometheus
```

## HighDiskUsage

Purpose: proves node-exporter filesystem metrics can trigger disk alerts.

This alert is intentionally not simulated with a disk-filling script because filling EC2 disks can break Docker and the OS. To test it safely, temporarily lower the `HighDiskUsage` threshold, restart Prometheus, then restore the threshold.

## HighLatency

Purpose: proves backend request duration histograms are alertable.

Run from any node that can reach the app node:

```bash
./scripts/simulate-latency.sh APP_EC2_PUBLIC_OR_PRIVATE_IP 30
```

Then check:

- Prometheus Alerts
- Alertmanager UI
- Discord
- Grafana dashboard: `SentinelStack - Backend API Observability`

## High5xxRate

Purpose: proves backend 5xx responses are alertable.

Run from any node that can reach the app node:

```bash
./scripts/simulate-errors.sh APP_EC2_PUBLIC_OR_PRIVATE_IP 40
```

Then check:

- Prometheus Alerts
- Alertmanager UI
- Discord
- Grafana dashboard: `SentinelStack - Backend API Observability`
- Grafana dashboard: `SentinelStack - Error Logs`

## ContainerRestart

Purpose: proves cAdvisor detects container restarts.

Run on the app node:

```bash
./scripts/simulate-container-crash.sh sentinelstack-backend
```

This performs a safe `docker restart` of the backend container. It does not delete data or images.

Then check:

- Prometheus Alerts
- Alertmanager UI
- Discord
- Grafana dashboard: `SentinelStack - Docker Container Metrics`

## Alertmanager Discord Setup

Set the webhook only in the monitoring node runtime env file:

```bash
nano infrastructure/monitoring-node/.env
```

Set:

```bash
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
```

Regenerate config and restart monitoring:

```bash
./scripts/start-monitoring-node.sh APP_PRIVATE_IP
```

Do not commit the real webhook URL.

## Useful Validation Commands

Prometheus rules:

```bash
curl http://localhost:9090/api/v1/rules
```

Prometheus active alerts:

```bash
curl http://localhost:9090/api/v1/alerts
```

Alertmanager readiness:

```bash
curl http://localhost:9093/-/ready
curl http://localhost:9093/api/v2/status
```

Alertmanager logs:

```bash
docker logs sentinelstack-alertmanager --tail=100
```
