#!/usr/bin/env bash
# setup.sh — First-time setup for household-ai
# Run once before 'podman-compose up -d'
set -euo pipefail

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════╗${RESET}"
echo -e "${CYAN}║      household-ai  setup         ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════╝${RESET}"
echo ""

# ── 1. Check prerequisites ────────────────────────────────────────────────────
info "Checking prerequisites..."

command -v podman &>/dev/null        || error "Podman not found. Install it: https://podman.io/docs/installation"
command -v podman-compose &>/dev/null || error "podman-compose not found. Install: pip install podman-compose"
success "Podman and podman-compose found."

# ── 2. Check Ollama is reachable ──────────────────────────────────────────────
info "Checking Ollama at localhost:11434 ..."
if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
    success "Ollama is running."
    echo ""
    info "Available models:"
    curl -s http://localhost:11434/api/tags | python3 -c \
        "import sys,json; [print('  •', m['name']) for m in json.load(sys.stdin).get('models', [])]" 2>/dev/null \
        || echo "  (could not parse model list)"
else
    warn "Ollama not reachable at localhost:11434."
    warn "Start Ollama before running 'podman-compose up', or the container will retry automatically."
fi

echo ""

# ── 3. Create secrets directory ───────────────────────────────────────────────
info "Setting up secrets..."
mkdir -p secrets
chmod 700 secrets

SECRET_FILE="secrets/webui_secret.txt"
if [[ -f "$SECRET_FILE" ]]; then
    warn "Secret already exists at $SECRET_FILE — skipping generation."
else
    # Generate a 32-byte hex secret
    python3 -c "import secrets; print(secrets.token_hex(32))" > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"
    success "Generated secret at $SECRET_FILE"
fi

# ── 4. Create config stub if missing ─────────────────────────────────────────
mkdir -p config
if [[ ! -f config/webui_config.json ]]; then
    cat > config/webui_config.json <<'EOF'
{}
EOF
    info "Created empty config/webui_config.json (edit to pre-seed settings)."
fi

# ── 5. Create .gitignore ──────────────────────────────────────────────────────
cat > .gitignore <<'EOF'
# Never commit secrets or user data
secrets/
*.env
.env*

# Podman/container artifacts
*.pid

# Editor
.DS_Store
.vscode/
EOF
success "Created .gitignore (secrets/ is excluded from git)."

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║  Setup complete! Next steps:                 ║${RESET}"
echo -e "${GREEN}║                                              ║${RESET}"
echo -e "${GREEN}║  1.  podman-compose up -d                    ║${RESET}"
echo -e "${GREEN}║  2.  Open http://localhost:3000              ║${RESET}"
echo -e "${GREEN}║  3.  Register the first account (→ admin)    ║${RESET}"
echo -e "${GREEN}║  4.  Invite your roommate to register        ║${RESET}"
echo -e "${GREEN}║  5.  Set ENABLE_SIGNUP=false when done       ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
