#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[LLM-STACK]${NC} $1"; }
error()  { echo -e "${RED}[LLM-STACK]${NC} $1"; }
header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ─── Stop Open WebUI ───────────────────────────────
header "Stopping Open WebUI"

if docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
  docker stop open-webui
  log "Open WebUI stopped ✓"
else
  log "Open WebUI was not running"
fi



# ─── Stop Ollama ───────────────────────────────────
header "Stopping Ollama"
if [ -f "$SCRIPT_DIR/logs/ollama.pid" ]; then
  PID=$(cat "$SCRIPT_DIR/logs/ollama.pid")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    rm "$SCRIPT_DIR/logs/ollama.pid"
    log "Ollama stopped ✓"
  else
    log "Ollama was not running"
    rm -f "$SCRIPT_DIR/logs/ollama.pid"
  fi
else
  pkill -x "ollama" 2>/dev/null && log "Ollama stopped ✓" || log "Ollama was not running"
fi

header "LLM Stack Stopped"
echo ""