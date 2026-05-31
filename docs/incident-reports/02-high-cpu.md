# Incident Report 02: High App-Node CPU Usage

## Incident Summary

CPU usage on the application EC2 node exceeded the infrastructure warning threshold. Sustained host CPU pressure can increase API latency and reduce the node's ability to handle new requests.

## Trigger

The incident was reproduced on the app node with:

```bash
./scripts/simulate-cpu-spike.sh 180 2
```

The script starts a disposable Alpine container with two CPU-intensive workers for 180 seconds. The worker count can be increased on larger EC2 instances.

## Alert Fired

Prometheus fired the `HighCPUUsage` warning after average host CPU usage remained above `70%` for two minutes.

```promql
100 - (
  avg by(instance) (
    rate(node_cpu_seconds_total{job="sentinelstack-node-exporter",mode="idle"}[2m])
  ) * 100
) > 70
```

Alert delivery was confirmed through Alertmanager and Discord.

## Dashboard Evidence

The `SentinelStack - App Node Metrics` dashboard showed the `CPU Usage %` panel crossing the red `70%` threshold.

Evidence:

- [CPU spike script running](../../screenshots/high%20CPU%20usage%20script%20running.png)
- [CPU usage above threshold](../../screenshots/CPU%20usage%20above%20warning%20threshold.png)
- [Prometheus alert firing](../../screenshots/high%20CPU%20Usage%20alert%20rule%20firing%20in%20prometheus.png)
- [Discord firing alert](../../screenshots/High%20CPU%20usage%20discord%20alert.png)
- [Discord resolved alert](../../screenshots/High%20CPU%20usage%20resolved%20discord.png)

## Log Evidence

This was an infrastructure saturation incident rather than an application exception. Loki logs did not need to contain an error for the alert to be valid.

The following query can be used to correlate increased traffic, errors, or slow requests during the CPU spike:

```logql
{job="sentinelstack"}
```

## Root Cause

A disposable container intentionally consumed CPU on the app node. In production, similar pressure could come from traffic growth, inefficient application code, a runaway process, or insufficient EC2 capacity.

## Fix

The simulation script automatically removes `sentinelstack-cpu-spike` when it exits. Manual cleanup is:

```bash
docker rm -f sentinelstack-cpu-spike
```

CPU usage returns below `70%`, and the alert resolves after the evaluation window clears.

## Prevention

- Track CPU trends and capacity headroom over time.
- Add per-container CPU dashboards to identify the workload causing host pressure.
- Apply container CPU limits where appropriate.
- Scale vertically or horizontally before sustained utilization approaches the alert threshold.
