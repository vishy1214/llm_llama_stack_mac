#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; }
info()   { echo -e "  ${YELLOW}→${NC} $1"; }

header "LLM Stack Status"

# ─── Ollama ────────────────────────────────────────
echo ""
echo "Ollama:"
if command -v ollama &> /dev/null; then
  ok "Process running"
  if curl -s "http://localhost:$OLLAMA_PORT" > /dev/null 2>&1; then
    ok "API responding on :$OLLAMA_PORT"
  else
    fail "API not responding"
  fi
  # Show loaded models
  MODELS=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
  if [ -n "$MODELS" ]; then
    ok "Available models:"
    echo "$MODELS" | while read m; do info "$m"; done
  fi
  # Show running model
  RUNNING=$(ollama ps 2>/dev/null | tail -n +2)
  if [ -n "$RUNNING" ]; then
    ok "Currently loaded in memory:"
    echo "$RUNNING" | while read r; do info "$r"; done
  fi
else
  fail "Ollama not running"
fi

# ─── Open WebUI ────────────────────────────────────
echo ""
echo "Open WebUI:"
if command -v open-webui &> /dev/null; then
  ok "Process running"
  if curl -s "http://localhost:$WEBUI_PORT" > /dev/null 2>&1; then
    ok "UI responding on :$WEBUI_PORT"
    info "Open: http://localhost:$WEBUI_PORT"
  else
    fail "UI not responding yet (still starting?)"
  fi
else
  fail "Open WebUI not running"
fi
