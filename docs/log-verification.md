# SentinelStack Log Verification

Use this guide after deploying the app node and monitoring node to confirm Promtail is sending Docker logs to Loki and Grafana can query them.

## App Node Checks

Confirm Promtail generated config points to the monitoring node Loki endpoint:

```bash
grep -n "loki/api/v1/push" infrastructure/app-node/configs/promtail/config.yml
grep -n "target_label: service" infrastructure/app-node/configs/promtail/config.yml
grep -n "target_label: container" infrastructure/app-node/configs/promtail/config.yml
grep -n "target_label: environment" infrastructure/app-node/configs/promtail/config.yml
grep -n "target_label: __path__" infrastructure/app-node/configs/promtail/config.yml
```

Check Promtail logs:

```bash
docker logs sentinelstack-promtail --tail=100
```

Confirm the app node can reach Loki on the monitoring node:

```bash
curl http://MONITORING_PRIVATE_IP:3100/ready
curl http://MONITORING_PRIVATE_IP:3100/loki/api/v1/labels
```

Generate app traffic so there are fresh logs:

```bash
curl http://localhost/api/health
curl http://localhost/api/products
curl http://localhost/api/error
```

## Monitoring Node Checks

Confirm Loki is ready:

```bash
curl http://localhost:3100/ready
```

Check labels received by Loki:

```bash
curl http://localhost:3100/loki/api/v1/labels
```

Query recent SentinelStack logs:

```bash
curl -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="sentinelstack"}'

curl -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={service="backend"}'

curl -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="sentinelstack"} |~ "(?i)error|exception|failed|fatal"'
```

## Grafana Explore

Open Grafana, then go to Explore and choose the `Loki` datasource.

Useful LogQL queries:

```logql
{job="sentinelstack"}
{service="backend"}
{service="nginx"}
{job="sentinelstack"} |~ "(?i)error|exception|failed|fatal"
```

The label browser should show labels such as `job`, `service`, `container`, `host`, and `environment`.

## If Logs Are Missing

Check these in order:

1. App node security group allows outbound traffic to the monitoring node on port `3100`.
2. Monitoring node security group allows inbound traffic from the app node on port `3100`.
3. `sentinelstack-promtail` is running.
4. Promtail logs do not show connection errors.
5. `infrastructure/app-node/configs/promtail/config.yml` contains the correct Loki push URL.
6. Docker socket and container log mounts exist in `infrastructure/app-node/docker-compose.yml`.
7. App containers have SentinelStack labels in Docker Compose.
8. Fresh application traffic has been generated after Promtail started.
