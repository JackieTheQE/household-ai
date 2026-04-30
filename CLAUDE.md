# household-ai — Project Context for AI Assistants

## What this project is

A private, local-first ChatGPT-style chat interface for household use. No data leaves the local network. Built on top of a fork of [open-webui](https://github.com/open-webui/open-webui), containerized with rootless Podman, and connected to a locally-running Ollama instance.

## Repository relationship — READ THIS FIRST

This repo (`JackieTheQE/household-ai`) is a **fork of `open-webui/open-webui`**.

- `origin` → `https://github.com/JackieTheQE/household-ai` (our fork — push here)
- `upstream` → `https://github.com/open-webui/open-webui` (fetch/merge updates from here, **never push**)

**We pull from upstream, we never push to upstream.** The workflow for syncing:

```bash
git fetch upstream
git merge upstream/main
git push   # pushes to origin (our fork) only
```

Our additions live on top of the open-webui codebase as commits on `main`. Do not rebase them away when merging upstream.

## Environment

- **OS:** Windows 11 Home
- **Shell:** Git Bash (for bash scripts) and PowerShell (for Windows admin tasks)
- **Podman:** 5.8.0, WSL2 backend (`podman-machine-default`), rootless mode
- **WSL2 networking:** Mirrored mode (`C:\Users\Jacki\.wslconfig` has `[wsl2]` — currently no `networkingMode` override active)
- **podman-compose:** 1.5.0, installed via pip into Python 3.13
- **Ollama:** Running natively on Windows, listening on `0.0.0.0:11434` (all interfaces)

## Running the stack

Always use the explicit `-f` flag — the repo root contains open-webui's own `docker-compose.yaml` which podman-compose will pick up otherwise:

```bash
podman-compose -f podman-compose.yml up -d
podman-compose -f podman-compose.yml down
podman-compose -f podman-compose.yml logs -f
```

Or use `manage.sh` (Git Bash):

```bash
./manage.sh start
./manage.sh stop
./manage.sh restart
./manage.sh logs
./manage.sh status
./manage.sh backup
```

## Key files we own (do not revert these)

| File | Purpose |
|---|---|
| `podman-compose.yml` | Our container definition — open-webui image + Ollama bridge + secrets |
| `manage.sh` | Bash management CLI wrapping podman-compose |
| `setup.sh` | First-time setup: generates `secrets/webui_secret.txt`, creates `config/` stub |
| `household-ai.service` | Systemd unit for Linux boot auto-start (not currently used on Windows) |
| `config/webui_config.json` | Empty stub — config.json pre-seed mount is disabled (see below) |
| `CLAUDE.md` | This file |

## Secrets (gitignored)

`secrets/webui_secret.txt` is generated locally by `setup.sh` and **must never be committed**. It is mounted into the container as a Podman secret. The `secrets/` directory is in `.gitignore`.

## Networking — important quirks

### Port and binding
- Container runs on **port 7070** (`0.0.0.0:7070 → 8080` inside container)
- `0.0.0.0` binding makes it LAN-accessible at `http://192.168.0.156:7070`

### WSL2 + LAN access setup
WSL2 in mirrored mode proxies container ports to Windows loopback only. LAN access requires a persistent Windows portproxy entry. This requires a one-time admin command after each machine restart that loses it:

```powershell
# Run as Administrator
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=7070 connectaddress=127.0.0.1 connectport=7070
```

Check existing entries with:
```powershell
netsh interface portproxy show all
```

### Firewall
Three inbound rules exist for TCP port 7070 (Private profile). If LAN stops working, check that the portproxy entry is still present — it does not survive `wsl --shutdown` + machine restart.

### Ollama reachability
Ollama on Windows is already on `0.0.0.0:11434`. The container reaches it via `host.containers.internal:11434` (set in `podman-compose.yml`). No changes needed.

## Known issues / decisions

### config.json pre-seed mount is disabled
open-webui migrates `config.json` on first boot (`os.rename` to `old_config.json`), which fails if the file is bind-mounted read-only. The volume mount line is commented out in `podman-compose.yml`. All config lives in the `open-webui-data` named Podman volume.

### podman-compose must use `-f` flag
The open-webui repo ships its own `docker-compose.yaml` at the root. Without `-f podman-compose.yml`, podman-compose picks up the wrong file and tries to pull an Ollama container image. `manage.sh` already hardcodes this.

### Do not use `wsl --shutdown` lightly
Shutting down WSL resets the Podman machine connection and loses the portproxy entry. If you must restart WSL, follow up with:
1. `podman machine start`
2. Re-add the portproxy (admin PowerShell)
3. `podman-compose -f podman-compose.yml up -d`

## Available Ollama models (as of project init)

qwen2.5:7b, qwen2.5:14b, qwen2.5-coder:7b, qwen2.5-coder:14b, llama3.1:8b, deepseek-r1:14b, qwen3:4b, qwen3:8b, qwen3-vl:8b, qwen3-coder:30b, gpt-oss:20b

## Future planned work

- HTTPS via `jackiesllm.com` — Caddy reverse proxy + Let's Encrypt + router port forwarding
- open-webui Tools/Functions (agents): web search, Python exec, custom API integrations
- OpenAI-compatible API endpoint (stubbed in `podman-compose.yml`, commented out)
- Multi-user household: admin account + roommate account, signup disabled after registration
