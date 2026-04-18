# 🐳 Docker Linux Installer

> One-shot Bash script to install **Docker Engine** and **Docker Compose V2** on Debian/Ubuntu-based Linux distributions. No manual steps, no copy-pasting commands from docs.

---

## ✨ Features

- ✅ Auto-detects your distro (Ubuntu, Kubuntu, Debian, Linux Mint, Pop!_OS)
- ✅ Installs Docker Engine from the **official Docker repository** (not the distro's outdated package)
- ✅ Installs **Docker Compose V2** as a plugin (`docker compose`, no hyphen)
- ✅ Handles GPG key setup in the modern `/etc/apt/keyrings/` path
- ✅ Adds your user to the `docker` group (no more `sudo docker`)
- ✅ Enables and starts the Docker systemd service
- ✅ Skips reinstallation if Docker is already present (with prompt)
- ✅ Color-coded log output for easy reading

---

## 📋 Requirements

- Debian/Ubuntu-based distro (Ubuntu, Kubuntu, Linux Mint, Pop!_OS, Debian)
- `sudo` privileges
- Internet connection

---

## 🚀 Installation

```bash
git clone https://github.com/Alexys829/docker-linux-installer.git
cd docker-linux-installer
chmod +x install_docker.sh
./install_docker.sh
```

Or run it directly (one-liner):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Alexys829/docker-linux-installer/main/install_docker.sh)
```

---

## ⚙️ What the script does

| Step | Action |
|------|--------|
| 0 | Checks if Docker is already installed (asks before overwriting) |
| 1 | Updates system packages (`apt update && apt upgrade`) |
| 2 | Installs dependencies: `ca-certificates`, `curl`, `gnupg`, `lsb-release` |
| 3 | Auto-detects distro and selects the correct Docker repository |
| 4 | Downloads and installs Docker's official GPG key to `/etc/apt/keyrings/` |
| 5 | Adds the Docker apt repository |
| 6 | Updates the package index |
| 7 | Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` |
| 8 | Adds `$USER` to the `docker` group |
| 9 | Enables and starts the Docker systemd service |
| ✔️ | Verifies installation with `docker --version` and `docker compose version` |

---

## 🧪 Tested on

| Distro | Status |
|--------|--------|
| Ubuntu 22.04 / 24.04 | ✅ |
| Kubuntu 22.04 / 24.04 | ✅ |
| Linux Mint 21.x | ✅ |
| Debian 12 (Bookworm) | ✅ |
| Pop!_OS 22.04 | ✅ |

---

## ⚠️ After installation

You need to **log out and log back in** for the `docker` group membership to take effect. After that, you can run Docker without `sudo`:

```bash
docker run hello-world
docker compose version
```

---

## 🗑️ Uninstall

```bash
sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.gpg
```

---

## 📄 License

MIT — do whatever you want with it.
