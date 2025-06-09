
---

## 📦 Docker Registry Cache for Offline Hosts

This project enables you to **cache Docker images** in a private Docker registry (running as a pull-through cache), allowing offline machines to pull images even without internet access once cached.

---

### 🖥️ Architecture

```text
               (Internet)
                   |
             [Host 1: Online]
           docker-proxy.local:5000
                   |
         -------------------------
         |                       |
 [Host 1: Internet]      [Host 2: Offline]
 preload_to_cache.sh      docker-pull.sh
```

---

## 🚀 Setup

### ✅ Host 1 (Online) — Docker Registry Cache

1. Start the Docker registry in proxy cache mode:

   ```bash
   docker-compose up -d
   ```

2. Confirm it works:

   ```bash
   curl http://localhost:5000/v2/
   ```

---

### 🧭 Configure `/etc/hosts` on Both Hosts

Edit the `/etc/hosts` file on **both Host 1 and Host 2** to resolve the registry hostname:

```bash
sudo nano /etc/hosts
```

Add:

```text
192.168.1.100 docker-proxy.local
```

Replace `192.168.1.100` with the actual IP address of Host 1.

---

## ⚙️ Docker Daemon Setup (Host 2)

1. Configure Docker to allow HTTP access to the proxy:

   Edit `/etc/docker/daemon.json`:

   ```json
   {
     "insecure-registries": ["docker-proxy.local:5000"]
   }
   ```

2. Restart Docker:

   ```bash
   sudo systemctl restart docker
   ```

---

## 🔄 Image Caching Behavior

When you use `docker-pull.sh` on Host 2:

```bash
./docker-pull.sh nginx:alpine
```

The proxy registry will:

* **Download the image from Docker Hub**
* **Cache it automatically**
* **Return it to the offline host**

> ✅ The image is cached **on-demand** — no need to preload it manually.

---

## 🔧 When to Use `preload_to_cache.sh`

You only need to run this on **Host 1** if:

* You’re preparing for a fully offline scenario
* You want to pre-warm the cache before clients request it
* You have restricted or firewalled client environments

Example:

```bash
./preload_to_cache.sh nginx:alpine
```

---

## 📜 Scripts

### 🔹 `docker-pull.sh` (Host 2)

* Pulls from proxy registry
* Re-tags image to match `docker-compose.yml`

### 🔹 `preload_to_cache.sh` (Host 1)

* Pulls image from Docker Hub
* Pushes it to the proxy to cache it manually (optional)

---


## ✅ Example Workflow

1. On Host 2 (offline):

   ```bash
   ./docker-pull.sh nginx:alpine
   docker run --rm nginx:alpine uname -a
   ```

2. Optional on Host 1 (online):

   ```bash
   ./preload_to_cache.sh alpine
   ```

---

## 🔐 Notes

* Registry only works with **Docker Hub** (not GitLab/GitHub registries)
* Proxy registry must be HTTP unless you configure TLS
* Caching only works for **public images** — for private images, you need a separate writable registry
