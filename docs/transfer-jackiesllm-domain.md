# Transfer Prompt — jackiesllm.com → household-ai HTTPS setup

Use this as the opening message when starting a new session to set up public HTTPS access.

---

## Session starter prompt

I'm setting up HTTPS access for a household AI project. I need `https://jackiesllm.com` to resolve to an open-webui instance running on my Windows 11 machine at `192.168.0.156`, port `7070`. Here's the full context:

### Current state
- open-webui is running in a rootless Podman container on Windows 11 (WSL2 backend)
- It listens on `0.0.0.0:7070` on the host machine
- LAN access works at `http://192.168.0.156:7070`
- There is already a Caddy container in Podman (`caddy`, currently stopped/exited)
- The domain `jackiesllm.com` is registered and I control its DNS

### Goal
- `https://jackiesllm.com` → reverse-proxied to `localhost:7070` (open-webui)
- TLS certificate via Let's Encrypt (automatic renewal)
- Caddy as the reverse proxy (already in the Podman environment)
- Router configured to forward ports 80 and 443 to `192.168.0.156`

### Constraints and environment
- Windows 11 Home, Podman 5.8.0 (WSL2, rootless)
- `podman-compose` 1.5.0 via pip (Python 3.13)
- The project repo is at `E:\Documents\Projects\Javascript\JackieLLM`
- We always run compose with the explicit file flag: `podman-compose -f podman-compose.yml`
- The open-webui container is named `household-ai`
- LAN portproxy is managed via `netsh interface portproxy` (requires admin PowerShell)
- Firewall rules exist for port 7070. Rules for 80/443 will need to be added.
- WSL2 is in mirrored networking mode

### What I need help with
1. **DNS** — Point `jackiesllm.com` (A record) to my public IP. I may need dynamic DNS if my ISP assigns a dynamic IP. Help me check and set that up.
2. **Router** — Port-forward TCP 80 and 443 from the router's WAN to `192.168.0.156`. I'll need to know my router's admin interface — it's a [FILL IN: router make/model].
3. **Caddy config** — Write a `Caddyfile` for `jackiesllm.com` that:
   - Handles TLS automatically via Let's Encrypt
   - Reverse-proxies to `localhost:7070`
   - Redirects HTTP → HTTPS
4. **Podman integration** — Add Caddy to `podman-compose.yml` alongside the open-webui container so both start together with `./manage.sh start`
5. **Firewall** — Add Windows firewall rules for inbound TCP 80 and 443
6. **Portproxy** — Add `netsh interface portproxy` entries for ports 80 and 443 (same pattern as the existing port 7070 entry)
7. **open-webui CORS** — Update `CORS_ALLOW_ORIGIN` in `podman-compose.yml` from `*` to `https://jackiesllm.com`

### Files to be aware of

**`podman-compose.yml`** (current):
```yaml
version: "3.8"
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: household-ai
    restart: unless-stopped
    ports:
      - "0.0.0.0:7070:8080"
    volumes:
      - open-webui-data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://host.containers.internal:11434
      - WEBUI_SECRET_KEY_FILE=/run/secrets/webui_secret
      - WEBUI_AUTH=true
      - ENABLE_SIGNUP=true
      - SCARF_NO_ANALYTICS=true
      - DO_NOT_TRACK=1
      - ANONYMIZED_TELEMETRY=false
      - ENABLE_IMAGE_GENERATION=false
      - ENABLE_COMMUNITY_SHARING=false
      - ENABLE_MESSAGE_RATING=false
    secrets:
      - webui_secret
    extra_hosts:
      - "host.containers.internal:host-gateway"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s
volumes:
  open-webui-data:
    driver: local
secrets:
  webui_secret:
    file: ./secrets/webui_secret.txt
```

**`manage.sh`** wraps all compose commands with `-f podman-compose.yml` and is the standard way to operate the stack.

### Important gotchas from prior setup work
- Never use `docker-compose.yaml` — the open-webui repo ships its own and podman-compose will pick it up without `-f`
- The `config/webui_config.json` pre-seed mount is disabled because open-webui tries to `os.rename` it on boot and fails against a read-only bind mount
- After any `wsl --shutdown`, the portproxy entries are lost and must be re-added (admin PowerShell)
- Ports < 1024 may require rootful mode for Podman — check whether `podman machine set --rootful` is needed for ports 80/443, or whether we route those through Caddy on higher ports and forward via portproxy

---

*Generated from household-ai project — `docs/transfer-jackiesllm-domain.md`*
