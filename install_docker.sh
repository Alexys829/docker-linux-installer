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

# ── Check iniziale: Docker già installato? ─────────────────
if command -v docker &>/dev/null; then
    log_warning "Docker è già installato: $(docker --version)"
    read -r -p "Vuoi reinstallare/aggiornare? [y/N] " answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && exit 0
fi

log_info "Inizio installazione Docker e Docker Compose"
echo "================================================"

# ── Step 1: Aggiornamento sistema ─────────────────────────
log_info "Step 1: Aggiornamento pacchetti di sistema..."
if sudo apt update && sudo apt upgrade -y; then
    log_info "Aggiornamento sistema completato con successo"
else
    log_error "Impossibile aggiornare il sistema. Verifica connessione internet e permessi sudo."
    exit 1
fi

# ── Step 2: Dipendenze ─────────────────────────────────────
log_info "Step 2: Installazione dipendenze..."
if sudo apt install -y ca-certificates curl gnupg lsb-release; then
    log_info "Installazione dipendenze completata con successo"
else
    log_error "Impossibile installare le dipendenze necessarie"
    exit 1
fi

# ── Step 3: Rilevamento distro base ───────────────────────
log_info "Step 3: Rilevamento distribuzione Linux..."
DISTRO_ID=$(. /etc/os-release && echo "$ID")
DISTRO_CODENAME=$(lsb_release -cs)

case "$DISTRO_ID" in
    linuxmint|kubuntu|ubuntu|pop)
        DOCKER_REPO_DISTRO="ubuntu"
        ;;
    debian)
        DOCKER_REPO_DISTRO="debian"
        ;;
    *)
        log_warning "Distribuzione '$DISTRO_ID' non testata, si tenta con ubuntu."
        DOCKER_REPO_DISTRO="ubuntu"
        ;;
esac
log_info "Distribuzione rilevata: $DISTRO_ID → repo Docker: $DOCKER_REPO_DISTRO"

# ── Step 4: Chiave GPG Docker ─────────────────────────────
log_info "Step 4: Download e installazione chiave GPG Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
if curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO_DISTRO}/gpg" \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    log_info "Chiave GPG installata con successo"
else
    log_error "Impossibile scaricare la chiave GPG di Docker"
    exit 1
fi

# ── Step 5: Aggiunta repository Docker ──────────────────────
log_info "Step 5: Aggiunta repository Docker..."
if echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/${DOCKER_REPO_DISTRO} \
${DISTRO_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
    log_info "Repository Docker aggiunto con successo"
else
    log_error "Impossibile aggiungere il repository Docker"
    exit 1
fi

# ── Step 6: Aggiornamento indice pacchetti ───────────────────
log_info "Step 6: Aggiornamento indice pacchetti..."
if sudo apt update; then
    log_info "Aggiornamento repository completato con successo"
else
    log_error "Impossibile aggiornare l'indice dei pacchetti"
    exit 1
fi

# ── Step 7: Installazione Docker Engine ─────────────────────
log_info "Step 7: Installazione Docker Engine..."
if sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    log_info "Installazione Docker completata con successo"
else
    log_error "Impossibile installare Docker Engine"
    exit 1
fi

# ── Step 8: Aggiunta utente al gruppo docker ────────────────
log_info "Step 8: Aggiunta utente corrente al gruppo docker..."
if sudo usermod -aG docker "$USER"; then
    log_info "Aggiunta utente al gruppo docker completata con successo"
    log_warning "Dovrai effettuare logout e login per usare Docker senza sudo"
else
    log_error "Impossibile aggiungere l'utente al gruppo docker"
    exit 1
fi

# ── Step 9: Abilitazione e avvio servizio Docker ─────────────
log_info "Step 9: Abilitazione servizio Docker all'avvio..."
if sudo systemctl enable docker && sudo systemctl start docker; then
    log_info "Servizio Docker avviato con successo"
else
    log_error "Impossibile avviare il servizio Docker"
    exit 1
fi

# ── Verifica finale ──────────────────────────────────────────
echo ""
echo "================================================"
log_info "Verifica installazione:"
echo ""

if docker --version; then
    log_info "Docker Engine: OK ✅"
else
    log_error "Docker non è stato installato correttamente"
    exit 1
fi

if docker compose version; then
    log_info "Docker Compose (plugin V2): OK ✅"
else
    log_error "Docker Compose non è stato installato correttamente"
    exit 1
fi

echo ""
echo "================================================"
log_info "Installazione completata con successo! 🎉"
log_warning "IMPORTANTE: Effettua logout e login per usare Docker senza sudo"
echo "================================================"
