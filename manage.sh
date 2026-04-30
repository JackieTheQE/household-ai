#!/usr/bin/env bash
# manage.sh — Day-to-day management for household-ai
# Usage: ./manage.sh [start|stop|restart|update|logs|status|backup|restore]
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'

COMPOSE="podman-compose -f podman-compose.yml"
PORT=7070

cmd="${1:-help}"

case "$cmd" in
  start)
    echo -e "${GREEN}Starting household-ai...${RESET}"
    $COMPOSE up -d
    echo -e "${GREEN}Running at http://localhost:${PORT}${RESET}"
    ;;

  stop)
    echo -e "${YELLOW}Stopping household-ai...${RESET}"
    $COMPOSE down
    ;;

  restart)
    $COMPOSE down && $COMPOSE up -d
    ;;

  update)
    echo -e "${CYAN}Pulling latest open-webui image...${RESET}"
    podman pull ghcr.io/open-webui/open-webui:main
    $COMPOSE down
    $COMPOSE up -d
    echo -e "${GREEN}Updated and restarted.${RESET}"
    ;;

  logs)
    $COMPOSE logs -f --tail=100
    ;;

  status)
    podman ps --filter "name=household-ai" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    ;;

  backup)
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    podman volume export open-webui-data > "$BACKUP_DIR/open-webui-data.tar"
    echo -e "${GREEN}Backed up to $BACKUP_DIR/open-webui-data.tar${RESET}"
    ;;

  restore)
    BACKUP_FILE="${2:-}"
    [[ -z "$BACKUP_FILE" ]] && { echo "Usage: ./manage.sh restore <backup.tar>"; exit 1; }
    $COMPOSE down
    podman volume import open-webui-data "$BACKUP_FILE"
    $COMPOSE up -d
    echo -e "${GREEN}Restored from $BACKUP_FILE${RESET}"
    ;;

  help|*)
    echo ""
    echo -e "${CYAN}household-ai management${RESET}"
    echo ""
    echo "  ./manage.sh start          Start the service"
    echo "  ./manage.sh stop           Stop the service"
    echo "  ./manage.sh restart        Restart the service"
    echo "  ./manage.sh update         Pull latest image & restart"
    echo "  ./manage.sh logs           Tail container logs"
    echo "  ./manage.sh status         Show container status"
    echo "  ./manage.sh backup         Backup chat data to ./backups/"
    echo "  ./manage.sh restore <tar>  Restore from a backup"
    echo ""
    echo -e "  Accessible at: ${CYAN}http://localhost:${PORT}${RESET} or ${CYAN}http://<your-ip>:${PORT}${RESET}"
    echo ""
    ;;
esac
