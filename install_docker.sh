#!/bin/bash

set -e
set -o pipefail

# ── Colori ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_connectivity() {
    log_info "Verifica connettività a download.docker.com..."
    if curl -sf --max-time 10 "https://download.docker.com" > /dev/null; then
        return 0
    else
        log_error "Impossibile raggiungere download.docker.com. Verifica la connessione internet."
        return 1
    fi
}

# ── Check privilegi sudo ─────────────────────────────────
if ! sudo -v; then
    log_error "Questo script richiede privilegi sudo."
    exit 1
fi

# ── Check iniziale: Docker già installato? ─────────────────
if command -v docker &>/dev/null; then
    log_warning "Docker è già installato: $(docker --version)"
    read -r -p "Vuoi reinstallare/aggiornare? [y/N] " answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && exit 0
fi

log_info "Inizio installazione Docker e Docker Compose"
echo "================================================"

check_connectivity || exit 1

# ── Step 1: Rilevamento distro ───────────────────────────
log_info "Step 1: Rilevamento distribuzione Linux..."
. /etc/os-release
DISTRO_ID="$ID"
DISTRO_ID_LIKE="${ID_LIKE:-}"

# Per Linux Mint (e derivate Ubuntu), il codename Docker-compatibile
# è in UBUNTU_CODENAME, non in VERSION_CODENAME.
DISTRO_CODENAME="${UBUNTU_CODENAME:-${DEBIAN_CODENAME:-${VERSION_CODENAME:-}}}"

if [[ -z "$DISTRO_CODENAME" ]]; then
    log_error "Impossibile rilevare il codename della distribuzione."
    exit 1
fi

# Routing del repository Docker basato su ID e ID_LIKE
case "$DISTRO_ID" in
    ubuntu|pop|linuxmint|kubuntu|elementary|zorin)
        DOCKER_REPO_DISTRO="ubuntu"
        ;;
    debian|raspbian)
        DOCKER_REPO_DISTRO="debian"
        ;;
    *)
        if [[ "$DISTRO_ID_LIKE" == *"ubuntu"* ]]; then
            DOCKER_REPO_DISTRO="ubuntu"
            log_warning "Distribuzione '$DISTRO_ID' non testata, usa repo ubuntu (da ID_LIKE)."
        elif [[ "$DISTRO_ID_LIKE" == *"debian"* ]]; then
            DOCKER_REPO_DISTRO="debian"
            log_warning "Distribuzione '$DISTRO_ID' non testata, usa repo debian (da ID_LIKE)."
        else
            log_error "Distribuzione '$DISTRO_ID' non supportata."
            exit 1
        fi
        ;;
esac
log_info "Distribuzione: $DISTRO_ID ($DISTRO_CODENAME) → repo Docker: $DOCKER_REPO_DISTRO"

# ── Step 2: Rimozione pacchetti Docker vecchi ────────────
log_info "Step 2: Rimozione eventuali pacchetti Docker obsoleti..."
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# ── Step 3: Aggiornamento sistema ─────────────────────────
log_info "Step 3: Aggiornamento pacchetti di sistema..."
sudo apt update
sudo apt upgrade -y

# ── Step 4: Dipendenze ─────────────────────────────────────
log_info "Step 4: Installazione dipendenze..."
sudo apt install -y ca-certificates curl gnupg

# ── Step 5: Chiave GPG Docker ─────────────────────────────
log_info "Step 5: Download e installazione chiave GPG Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO_DISTRO}/gpg" \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# ── Step 6: Aggiunta repository Docker ──────────────────────
log_info "Step 6: Aggiunta repository Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_REPO_DISTRO} ${DISTRO_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# ── Step 7: Aggiornamento indice pacchetti ───────────────────
log_info "Step 7: Aggiornamento indice pacchetti..."
sudo apt update

# ── Step 8: Installazione Docker Engine ─────────────────────
log_info "Step 8: Installazione Docker Engine..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ── Step 9: Aggiunta utente al gruppo docker ────────────────
log_info "Step 9: Aggiunta utente corrente al gruppo docker..."
sudo usermod -aG docker "$USER"
log_warning "Dovrai effettuare logout e login per usare Docker senza sudo"

# ── Step 10: Abilitazione e avvio servizio Docker ────────────
log_info "Step 10: Abilitazione e avvio servizio Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# ── Verifica finale ──────────────────────────────────────────
echo ""
echo "================================================"
log_info "Verifica installazione:"
echo ""

if sudo docker info &>/dev/null; then
    log_info "Docker Engine: OK ✅"
else
    log_error "Docker non è stato installato correttamente"
    exit 1
fi

if docker compose version &>/dev/null; then
    log_info "Docker Compose (plugin V2): OK ✅"
else
    log_error "Docker Compose non è stato installato correttamente"
    exit 1
fi

if sudo systemctl is-active --quiet docker; then
    log_info "Servizio Docker: OK ✅"
else
    log_error "Il servizio Docker non è in esecuzione"
    exit 1
fi

echo ""
echo "================================================"
log_info "Installazione completata con successo!"
log_warning "IMPORTANTE: Effettua logout e login per usare Docker senza sudo"
sudo systemctl status docker --no-pager
echo "================================================"
