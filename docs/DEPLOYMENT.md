# 🚀 FedChat Federated Learning Server Deployment Guide

This guide describes how to deploy the **FedChat FL Server infrastructure** using Docker Compose or Kubernetes.

---

## Prerequisites

- **Docker** 24.0+ & **Docker Compose** 2.20+
- **Python** 3.12+ (for local CLI / testing)
- Minimum 4 GB RAM & 20 GB Disk Space for MinIO checkpoints

---

## 1. Environment Configuration

Copy `.env.example` into `.env`:

```bash
cd server
cp .env.example .env
```

Edit `.env` variables:

```env
# Database
DATABASE_URL=postgresql+asyncpg://fedchat:fedchat_pass@postgres:5432/fedchat_db

# Redis
REDIS_URL=redis://redis:6379/0

# MinIO S3 Object Storage
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# Federated Learning Parameters
FL_MIN_CLIENTS=3
FL_ROUNDS=10
FL_LEARNING_RATE=0.001

# Differential Privacy
DP_EPSILON=1.0
DP_DELTA=1e-5
DP_CLIP_NORM=1.0
```

---

## 2. Docker Compose Deployment

Start all services (FastAPI Gateway, Postgres DB, Redis Queue, MinIO Storage):

```bash
cd server
docker compose up -d --build
```

Verify service health:

```bash
# Check container status
docker compose ps

# Check FastAPI health endpoint
curl http://localhost:8000/health
```

Expected Output:
```json
{"status": "healthy", "service": "FedChat FL Server"}
```

---

## 3. Running FL Simulation

Validate the server strategy and differential privacy aggregation pipeline:

```bash
cd server
python simulation/run_simulation.py
```

---

## 4. Production Hardening Checklist

- Enable HTTPS with Let's Encrypt / NGINX reverse proxy.
- Change default MinIO root credentials (`MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`).
- Restrict PostgreSQL port 5432 to internal Docker network.
