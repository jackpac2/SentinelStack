# SentinelStack

SentinelStack is a two-node AWS EC2 observability project built around a demo ecommerce application called CloudStore. It demonstrates how to deploy an application, collect metrics and logs, visualize system behavior, trigger alerts, deliver Discord notifications, and document incidents with reproducible evidence.

The repository is designed as a practical DevOps portfolio project. It includes application code, Docker Compose stacks, GitHub Actions workflows, monitoring configuration, validation scripts, fault simulations, dashboards, screenshots, and incident reports.

## Project Highlights

- React frontend and Express backend deployed with Docker Compose
- PostgreSQL database with persistent storage
- Nginx reverse proxy for frontend and API traffic
- Prometheus metrics from the backend, Node Exporter, and cAdvisor
- Loki log storage with Promtail log shipping
- Grafana datasources and dashboards provisioned from code
- Alertmanager notifications delivered to Discord
- GitHub Actions CI, image publishing, deployment, and teardown workflows
- Reproducible latency, CPU, 5xx-error, traffic, and container-restart tests
- Incident reports backed by dashboards, logs, alerts, and screenshots

## Application Preview

![CloudStore frontend](screenshots/frontend%20app.png)

## Architecture Diagram

<!-- Add your architecture diagram here. -->

<br><br><br><br><br><br>

## Architecture Overview

SentinelStack separates the application workload from the monitoring workload across two Ubuntu EC2 instances.

### App Node

The app node runs:

| Service | Purpose | Port |
|---|---|---:|
| `nginx` | Public reverse proxy for the frontend and `/api/*` routes | `80` |
| `frontend` | React and Vite CloudStore web application | Internal `80` |
| `backend` | Express API with health and Prometheus metrics endpoints | Internal `5000` |
| `postgres` | Persistent PostgreSQL database | Internal `5432` |
| `node-exporter` | EC2 host CPU, memory, disk, and network metrics | `9100` |
| `cadvisor` | Docker container metrics | `8080` |
| `promtail` | Docker log discovery and shipping to Loki | Outbound to `3100` |

The stack is defined in [`infrastructure/app-node/docker-compose.yml`](infrastructure/app-node/docker-compose.yml).

### Monitoring Node

The monitoring node runs:

| Service | Purpose | Port |
|---|---|---:|
| `prometheus` | Metric scraping and alert-rule evaluation | `9090` |
| `alertmanager` | Alert grouping and Discord delivery | `9093` |
| `loki` | Centralized log storage with seven-day retention | `3100` |
| `grafana` | Dashboards for metrics, logs, and alert visibility | `3000` |

The stack is defined in [`infrastructure/monitoring-node/docker-compose.yml`](infrastructure/monitoring-node/docker-compose.yml).

![Monitoring and app-node containers](screenshots/monitoring%20and%20app%20node%20running.png)

## Observability Flow

### Metrics

Prometheus scrapes metrics every 15 seconds:

| Source | Endpoint | What It Measures |
|---|---|---|
| Prometheus | `prometheus:9090` | Prometheus self-monitoring |
| Alertmanager | `alertmanager:9093` | Alertmanager health |
| Loki | `loki:3100` | Loki health |
| Node Exporter | `APP_PRIVATE_IP:9100/metrics` | Host CPU, memory, disk, and network |
| cAdvisor | `APP_PRIVATE_IP:8080/metrics` | Container CPU, memory, network, and lifecycle data |
| Backend API | `APP_PRIVATE_IP:80/api/metrics` | HTTP request count and latency |

The backend uses `prom-client` to expose:

```text
http_requests_total
http_request_duration_seconds
```

Prometheus configuration is generated from [`prometheus.yml.template`](infrastructure/monitoring-node/configs/prometheus/prometheus.yml.template).

![Prometheus scrape targets](screenshots/prometheus%20target.png)

### Logs

Promtail runs on the app node. It discovers Docker containers, reads Docker JSON logs, adds labels, and pushes entries to Loki:

```text
http://MONITORING_PRIVATE_IP:3100/loki/api/v1/push
```

Useful Loki labels include:

```text
job
service
container
host
environment
```

Useful LogQL queries:

```logql
{job="sentinelstack"}
{service="backend"}
{service="nginx"}
{job="sentinelstack"} |~ "(?i)error|exception|failed|fatal"
```

![Grafana logs overview](screenshots/logs%20overview%20grafana%20dashboard.png)

### Alerts

Prometheus evaluates alert rules from [`app-alerts.yml`](infrastructure/monitoring-node/configs/prometheus/rules/app-alerts.yml).

| Alert | Trigger | Duration |
|---|---|---:|
| `BackendDown` | Backend metrics endpoint cannot be scraped | `1m` |
| `HighCPUUsage` | App-node CPU usage exceeds `70%` | `2m` |
| `HighMemoryUsage` | App-node memory usage exceeds `80%` | `2m` |
| `HighDiskUsage` | App-node disk usage exceeds `85%` | `2m` |
| `HighLatency` | Backend p95 latency exceeds `0.8s` | `1m` |
| `High5xxRate` | Backend 5xx rate exceeds `0.05 req/s` | `1m` |
| `ContainerRestart` | cAdvisor detects a restart within five minutes | `30s` |

Alertmanager groups alerts by alert name. When `DISCORD_WEBHOOK_URL` is configured, the generated Alertmanager receiver sends firing and resolved messages to Discord.

![Discord high-latency alert](screenshots/high%20latency%20discord%20alert.png)

## Grafana Dashboards

Grafana automatically provisions Prometheus, Loki, and Alertmanager datasources and loads dashboards from the repository.

| Dashboard | Purpose |
|---|---|
| `SentinelStack Overview` | Service health, request rate, log rate, and recent logs |
| `SentinelStack - App Node Metrics` | Host CPU, memory, disk, network, and Node Exporter health |
| `SentinelStack - Backend API Observability` | API availability, request rate, errors, and latency |
| `SentinelStack - Docker Container Metrics` | Container resource usage and restart detection |
| `SentinelStack - Logs Overview` | Logs by service and log-rate trends |
| `SentinelStack - Backend/API Logs` | Backend logs and filtered API errors |
| `SentinelStack - Error Logs` | Centralized error, exception, failure, and fatal logs |
| `SentinelStack - Metrics Debug` | Prometheus metric-discovery troubleshooting |

Dashboard colors align with the Prometheus alert thresholds. When CPU, memory, disk, p95 latency, 5xx rate, or container restart metrics cross their configured rule thresholds, the relevant panel turns red.

![SentinelStack overview dashboard](screenshots/sentinelstack%20dashboard.png)

<details>
<summary>View additional Grafana screenshots</summary>

![All Grafana dashboards](screenshots/all%20grafana%20dashboards.png)

![App-node metrics dashboard](screenshots/app%20node%20metrics%20grafana%20dashboard.png)

![Backend API dashboard](screenshots/backend%20api%20grafana%20dashboard.png)

![Container-health dashboard](screenshots/container%20health%20grafana%20dashboards.png)

</details>

## Repository Structure

```text
.
|-- app/
|   |-- backend/                     # Express API, metrics, and health endpoints
|   |-- database/                    # PostgreSQL initialization and seed scripts
|   `-- frontend/                    # React and Vite CloudStore frontend
|-- docs/
|   |-- incident-reports/            # Troubleshooting reports with evidence
|   |-- alert-testing.md             # Alert validation guide
|   `-- log-verification.md          # Promtail, Loki, and Grafana log checks
|-- infrastructure/
|   |-- app-node/                    # Application Docker Compose stack
|   `-- monitoring-node/             # Monitoring stack, rules, and dashboards
|-- scripts/                         # Startup, validation, and simulation scripts
|-- screenshots/                     # Project and incident evidence
`-- .github/workflows/               # CI, deploy, and teardown automation
```

## Prerequisites

### AWS

Provision two Ubuntu EC2 instances:

1. An app node
2. A monitoring node

The installation scripts target Ubuntu `22.04+` and `24.04+`.

Recommended security-group access:

| Node | Port | Source | Purpose |
|---|---:|---|---|
| App | `22` | Trusted administrative source | SSH |
| App | `80` | Users and monitoring node | CloudStore and backend metric scraping |
| App | `9100` | Monitoring node | Node Exporter metrics |
| App | `8080` | Monitoring node | cAdvisor metrics |
| Monitoring | `22` | Trusted administrative source | SSH |
| Monitoring | `3000` | Trusted administrative source | Grafana |
| Monitoring | `9090` | Trusted administrative source | Prometheus |
| Monitoring | `9093` | Trusted administrative source | Alertmanager |
| Monitoring | `3100` | App node | Loki log ingestion |

Avoid exposing monitoring ports publicly unless required for a demo. Restrict inbound rules to trusted CIDR ranges or security groups.

### Repository and Images

The GitHub Actions pipeline publishes frontend and backend images to GitHub Container Registry:

```text
ghcr.io/GITHUB_OWNER/sentinelstack-frontend:latest
ghcr.io/GITHUB_OWNER/sentinelstack-backend:latest
```

Ensure the packages are readable by the app node. Public packages work without registry authentication. Private packages require a `docker login ghcr.io` step on the app node before deployment.

### GitHub Actions Secrets

Configure these repository secrets:

| Secret | Purpose |
|---|---|
| `APP_EC2_HOST` | Public hostname or IP used to SSH into the app node |
| `APP_EC2_USER` | Non-root app-node SSH user, commonly `ubuntu` |
| `APP_EC2_SSH_KEY` | Private SSH key for the app node |
| `APP_PRIVATE_IP` | Private app-node IP used by Prometheus |
| `APP_REPO_PATH` | Optional app-node clone path; defaults to `$HOME/sentinelstack` |
| `MONITORING_EC2_HOST` | Public hostname or IP used to SSH into the monitoring node |
| `MONITORING_EC2_USER` | Non-root monitoring-node SSH user, commonly `ubuntu` |
| `MONITORING_EC2_SSH_KEY` | Private SSH key for the monitoring node |
| `MONITORING_PRIVATE_IP` | Private monitoring-node IP used by Promtail |
| `MONITORING_REPO_PATH` | Optional monitoring-node clone path; defaults to `$HOME/sentinelstack` |

## CI/CD Pipeline

The CI workflow runs on pushes and pull requests targeting `main`:

1. Install backend dependencies.
2. Run backend tests when a test script exists.
3. Install frontend dependencies.
4. Build the frontend.
5. Build frontend and backend Docker images after successful non-PR runs.
6. Publish `latest` and commit-SHA image tags to GHCR.

After a successful CI run on `main`, the deploy workflow:

1. SSHs into the monitoring node.
2. Force-syncs the deployment checkout with `origin/main`.
3. Installs missing dependencies.
4. Generates host-specific Prometheus and Alertmanager configuration.
5. Starts and validates the monitoring stack.
6. SSHs into the app node.
7. Force-syncs the deployment checkout with `origin/main`.
8. Pulls application images from GHCR.
9. Generates the Promtail Loki destination.
10. Starts and validates the app stack.

![Monitoring-stack containers](screenshots/running%20services%20on%20docker%20compose%20in%20monitoring%20stack.png)

## Runtime Configuration

The startup scripts create runtime `.env` files from their examples when necessary.

### App Node Environment

Copy and review:

```bash
cp infrastructure/app-node/.env.example infrastructure/app-node/.env
```

Important values:

```dotenv
GHCR_OWNER=your-github-username
IMAGE_TAG=latest
DB_NAME=cloudstore
DB_USER=postgres
DB_PASSWORD=replace-me
NODE_NAME=app-node
ENVIRONMENT=production
```

### Monitoring Node Environment

Copy and review:

```bash
cp infrastructure/monitoring-node/.env.example infrastructure/monitoring-node/.env
```

Important values:

```dotenv
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=replace-me
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
```

Do not commit runtime `.env` files or real webhook secrets.

## Manual Deployment

GitHub Actions is the primary deployment path. To deploy manually, clone the repository on both EC2 instances and run the startup scripts as a non-root user.

### Start the Monitoring Node

On the monitoring EC2 instance:

```bash
git clone YOUR_REPOSITORY_URL sentinelstack
cd sentinelstack
chmod +x scripts/*.sh
./scripts/start-monitoring-node.sh APP_PRIVATE_IP
```

This generates Prometheus scrape targets and the Alertmanager receiver before starting the monitoring stack.

### Start the App Node

On the app EC2 instance:

```bash
git clone YOUR_REPOSITORY_URL sentinelstack
cd sentinelstack
chmod +x scripts/*.sh
./scripts/start-app-node.sh MONITORING_PRIVATE_IP
```

This generates the Promtail Loki push destination, pulls GHCR images, and starts the app stack.

### Access the Services

| Service | URL |
|---|---|
| CloudStore | `http://APP_EC2_PUBLIC_IP` |
| Grafana | `http://MONITORING_EC2_PUBLIC_IP:3000` |
| Prometheus | `http://MONITORING_EC2_PUBLIC_IP:9090` |
| Alertmanager | `http://MONITORING_EC2_PUBLIC_IP:9093` |

## Validation

Run these checks after deployment.

On the monitoring node:

```bash
./scripts/check-monitoring-node.sh
```

On the app node:

```bash
./scripts/check-app-node.sh MONITORING_PRIVATE_IP
```

Useful backend endpoints:

```text
GET /api/health
GET /api/products
GET /api/orders
GET /api/metrics
GET /api/slow
GET /api/error
```

`/api/slow` and `/api/error` exist specifically for observability validation. Do not expose test endpoints in a production application without access controls.

## Incident Simulations

Use the scripts below to exercise the monitoring stack.

| Scenario | Command | Expected Signal |
|---|---|---|
| Normal traffic | `./scripts/generate-traffic.sh APP_HOST 50` | Increased request and log rates |
| High latency | `./scripts/simulate-latency.sh APP_HOST 30` | `HighLatency` alert |
| High CPU | `./scripts/simulate-cpu-spike.sh 180 2` | `HighCPUUsage` alert |
| High 5xx rate | `./scripts/simulate-errors.sh APP_HOST 40` | `High5xxRate` alert |
| Container restart | `./scripts/simulate-container-crash.sh sentinelstack-backend` | `ContainerRestart` alert |

![High CPU alert firing in Prometheus](screenshots/high%20CPU%20Usage%20alert%20rule%20firing%20in%20prometheus.png)

<details>
<summary>View incident evidence screenshots</summary>

![High CPU threshold crossed](screenshots/CPU%20usage%20above%20warning%20threshold.png)

![High CPU Discord notification](screenshots/High%20CPU%20usage%20discord%20alert.png)

![High error-rate test](screenshots/high%20error%20rate%20testing.png)

![High error-rate Discord notification](screenshots/high%20error%20rate%20discord%20alert.png)

![HTTP 500 logs in Grafana](screenshots/error%20500%20testing%20grafana%20logs.png)

![High-traffic test](screenshots/high%20traffic%20testing.png)

</details>

## Incident Reports

The repository includes troubleshooting reports that connect symptoms to alerts, dashboards, logs, root causes, fixes, and prevention steps:

- [`01-high-latency.md`](docs/incident-reports/01-high-latency.md)
- [`02-high-cpu.md`](docs/incident-reports/02-high-cpu.md)
- [`03-high-error-rate.md`](docs/incident-reports/03-high-error-rate.md)
- [`04-high-traffic.md`](docs/incident-reports/04-high-traffic.md)

Additional operational guides:

- [`docs/alert-testing.md`](docs/alert-testing.md)
- [`docs/log-verification.md`](docs/log-verification.md)

## Teardown

Run the `Manual Teardown` GitHub Actions workflow and choose:

```text
app
monitoring
both
```

The workflow stops the selected Docker Compose stacks and removes their volumes:

```bash
docker compose down -v
```

This deletes persisted PostgreSQL, Prometheus, Loki, Grafana, Alertmanager, and Promtail-position data for the selected stack. It does not remove repository files or Docker images.

## Key Design Decisions

- **Two-node separation:** application workloads and monitoring workloads do not compete within one Docker Compose stack.
- **Private-IP telemetry:** Prometheus scraping and Loki ingestion use private EC2 networking.
- **Generated configuration:** templates remain reusable while startup scripts inject host-specific addresses and optional Discord configuration.
- **Provisioned dashboards:** Grafana datasources and dashboards are version-controlled instead of configured manually.
- **Persistent volumes:** application and monitoring data survive container restarts.
- **Safe simulations:** load generators are bounded and cleanup behavior is documented.
- **Evidence-driven operations:** screenshots and incident reports demonstrate the troubleshooting path, not just the final dashboard state.

## Current Limitations

- The project does not implement distributed tracing.
- Prometheus and Loki store data on local Docker volumes rather than external durable storage.
- The deployment uses a single app node and a single monitoring node without high availability.
- High traffic is visible in Grafana, but there is not yet a dedicated `HighTraffic` Prometheus alert.
- The backend package currently does not define an automated test script, so CI skips backend tests until one is added.
