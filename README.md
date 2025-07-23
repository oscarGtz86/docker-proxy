# 🐳 Docker Proxy Registry

This repository provides a writable Docker registry started with Docker Compose and running on port `5000`. It stores and serves Docker images for hosts that do not have internet access.

## 📋 Overview

This setup consists of two servers:
- **Host 1 (Internet-connected)**: Downloads images from Docker Hub and stores them in a local registry
- **Host 2 (Air-gapped/No internet)**: Pulls cached images from the Docker Proxy (Server 1)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────────────────────┐    ┌──────────────────────┐
│                 │    │          Host 1                 │    │       Host 2         │
│   Docker Hub    │◄───┤    (Internet-connected)         │◄───┤   (Air-gapped)       │
│                 │    │                                 │    │                      │
│  registry-1.    │    │  ┌─────────────────────────────┐│    │  ┌─────────────────┐ │
│  docker.io      │    │  │     Docker Registry         ││    │  │   Docker Client │ │
│                 │    │  │   docker-proxy.local:5000   ││    │  │                 │ │
└─────────────────┘    │  │                             ││    │  └─────────────────┘ │
                       │  │  - Writable registry        ││    │                      │
                       │  │  - Manual push/pull         ││    │                      │
                       │  │  - Persistent storage       ││    │                      │
                       │  └─────────────────────────────┘│    │                      │
                       └─────────────────────────────────┘    └──────────────────────┘
```

**Data Flow:**
1. **Host 1** pulls images from Docker Hub
2. **Host 1** pushes images to local registry
3. **Host 2** pulls cached images from Host 1's registry

---

## 🚀 Features

* ✅ Push your private or public (pre-pulled) images to the registry
* ✅ Pull those images from offline hosts
* ✅ Convenience scripts for caching and pulling images

---

## 🧩 Setup

### 🔷 On Host 1 (with internet)

#### 1️⃣ Clone the repository

```bash
git clone https://github.com/oscarGtz86/docker-proxy.git
cd docker-proxy
```

#### 2️⃣ Start the writable registry

```bash
docker compose up -d
```

✅ This runs `registry:2` as a writable registry on port `5000`.
All registry data is stored in the `registry-data/` directory next to the
compose file, so your images persist across restarts.


#### 3️⃣ Pull the image you need from Docker Hub

For example:

```bash
docker pull nginx:alpine
```

#### 4️⃣ Tag the image for your registry

```bash
docker tag nginx:alpine docker-proxy.local:5000/library/nginx:alpine
```

#### 5️⃣ Push the image into the writable registry

```bash
docker push docker-proxy.local:5000/library/nginx:alpine
```

---

## 🖥️ On Host 2 (offline)

### 🔷 Prerequisites

✅ Add Host 1’s IP and hostname to `/etc/hosts`:

```
<Host 1>    docker-proxy.local
```

✅ Add `insecure-registries` to `/etc/docker/daemon.json`:

```json
{
  "insecure-registries": [
    "docker-proxy.local:5000"
  ]
}
```

✅ Restart Docker:

```bash
sudo systemctl daemon-reexec
sudo systemctl restart docker
```

---

### 🔷 Pull the image from the registry

```bash
docker pull docker-proxy.local:5000/library/nginx:alpine
```

Optionally, re-tag it:

```bash
docker tag docker-proxy.local:5000/library/nginx:alpine nginx:alpine
```

---

## 📊 Notes

✅ This registry is writable and does not proxy Docker Hub — all needed public images must be **manually pulled on Host 1 and pushed into the registry**.

✅ If you need on-demand caching of public images, you can also deploy a second registry in proxy mode on a different port.

---

## 📂 Files

* `docker-compose.yml` — single writable registry setup
* `registry-data/` — persistent data volume for the registry

## 🛠️ Scripts

Two helper scripts are included in the `bin/` directory:

* `cache_image.sh` — pulls an image from Docker Hub, tags it for the local registry and pushes it.
* `pull_image.sh` — pulls an image from the local registry and optionally retags it to the original name.

Use these scripts on Host 1 and Host 2 respectively to simplify caching and pulling images.
Both scripts honor the `REGISTRY_HOST` environment variable if you use a
different hostname or port for the registry.

---

## 🌟 Example Workflow

```bash
# On Host 1
./bin/cache_image.sh nginx:alpine

# On Host 2
./bin/pull_image.sh nginx:alpine --retag
```
