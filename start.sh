#!/bin/bash
set -e

# ─── Load config ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "WEBUI_DATA_DIR: $WEBUI_DATA_DIR"
WEBUI_DATA_DIR="$SCRIPT_DIR/webui_data"

# Expand tilde in paths
WEBUI_DATA_DIR="${WEBUI_DATA_DIR/#\~/$HOME}"

# ─── Colors ────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[LLM-STACK]${NC} $1"; }
warn()   { echo -e "${YELLOW}[LLM-STACK]${NC} $1"; }
error()  { echo -e "${RED}[LLM-STACK]${NC} $1"; }
header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ─── Check dependencies ────────────────────────────
header "Checking Dependencies"

if ! command -v ollama &> /dev/null; then
  error "Ollama not found. Install it first:"
  echo "  Mac:   brew install ollama"
  echo "  Linux: curl -fsSL https://ollama.com/install.sh | sh"
  exit 1
fi
log "Ollama ✓"

if ! command -v open-webui &> /dev/null; then
  warn "Open WebUI not found. Installing now..."
  brew install open-webui || pip3 install open-webui -q || (echo "Failed to install Open WebUI. Please install it manually." && exit 1)
  log "Open WebUI installed ✓"
fi
log "Open WebUI ✓"

# ─── Create data directory ─────────────────────────
mkdir -p "$WEBUI_DATA_DIR"
mkdir -p "$SCRIPT_DIR/logs"

# ─── Start Ollama ──────────────────────────────────
header "Starting Ollama"

# Check if already running
if pgrep -x "ollama" > /dev/null; then
  warn "Ollama already running — skipping start"
else
  OLLAMA_HOST="$OLLAMA_HOST:$OLLAMA_PORT" ollama serve \
    > "$SCRIPT_DIR/logs/ollama.log" 2>&1 &
  echo $! > "$SCRIPT_DIR/logs/ollama.pid"
  log "Ollama started (PID: $(cat $SCRIPT_DIR/logs/ollama.pid))"

  # Wait for Ollama to be ready
  log "Waiting for Ollama to be ready..."
  for i in {1..30}; do
    if curl -s "http://localhost:$OLLAMA_PORT" > /dev/null 2>&1; then
      log "Ollama is ready ✓"
      break
    fi
    if [ $i -eq 30 ]; then
      error "Ollama failed to start. Check logs: $SCRIPT_DIR/logs/ollama.log"
      exit 1
    fi
    sleep 1
  done
fi

# ─── Pull model if not present ─────────────────────
header "Checking Model: $MODEL"

if ollama list | grep -q "^$MODEL"; then
  log "Model '$MODEL' already downloaded ✓"
else
  warn "Model '$MODEL' not found. Pulling now (this may take a while)..."
  ollama pull "$MODEL"
  log "Model '$MODEL' ready ✓"
fi

# ─── Warm up model ─────────────────────────────────
header "Loading Model into Memory"
log "Pre-loading $MODEL..."
curl -s "http://localhost:$OLLAMA_PORT/api/generate" \
  -d "{\"model\": \"$MODEL\", \"prompt\": \"hi\", \"stream\": false}" \
  > /dev/null 2>&1
log "Model loaded and ready ✓"



# ─── Starting Open WebUI─────────────────────────────────
header "Starting Open WebUI"

# Check if docker is available
if ! command -v docker &> /dev/null; then
  error "Docker not found. Install it first: https://docs.docker.com/get-docker/"
  exit 1
fi

# Check if container already exists and is running
if docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
  warn "Open WebUI container already running — skipping start"

# Check if container exists but is stopped
elif docker ps -a --format '{{.Names}}' | grep -q "^open-webui$"; then
  warn "Open WebUI container exists but stopped — restarting..."
  docker start open-webui > "$SCRIPT_DIR/logs/webui.log" 2>&1
  log "Open WebUI container restarted ✓"

# Container doesn't exist — create and run it
else
  log "Pulling Open WebUI image..."
  docker pull ghcr.io/open-webui/open-webui:main >> "$SCRIPT_DIR/logs/webui.log" 2>&1

  docker run -d \
    --name open-webui \
    --restart always \
    --network host \
    -e OLLAMA_BASE_URL="http://localhost:$OLLAMA_PORT" \
    -v "$WEBUI_DATA_DIR:/app/backend/data" \
    ghcr.io/open-webui/open-webui:main \
    >> "$SCRIPT_DIR/logs/webui.log" 2>&1

  log "Open WebUI container created and started ✓"
fi

# Wait for WebUI to be ready
log "Waiting for Open WebUI to be ready..."
for i in {1..60}; do
  if ! curl -s "http://localhost:$WEBUI_PORT" > /dev/null 2>&1; then
    log "Open WebUI is ready ✓"
    break
  fi
  if [ $i -eq 60 ]; then
    error "Open WebUI failed to start. Check logs: $SCRIPT_DIR/logs/webui.log"
    error "Also check docker logs: docker logs open-webui"
    exit 1
  fi
  sleep 1
done


# ─── Done ──────────────────────────────────────────
header "LLM Stack is Running"
echo ""
echo -e "  ${GREEN}Model:${NC}      $MODEL"
echo -e "  ${GREEN}Ollama API:${NC} http://localhost:$OLLAMA_PORT"
echo -e "  ${GREEN}Web UI:${NC}     http://localhost:$WEBUI_PORT"
echo ""
echo -e "  ${YELLOW}Logs:${NC}       $SCRIPT_DIR/logs/"
echo -e "  ${YELLOW}Stop:${NC}       ./stop.sh"
echo ""