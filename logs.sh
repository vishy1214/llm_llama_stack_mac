#!/bin/bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━ Tailing all logs (Ctrl+C to exit) ━━━${NC}"
echo -e "${GREEN}[OLLAMA]${NC} → $SCRIPT_DIR/logs/ollama.log"
echo -e "${GREEN}[WEBUI]${NC}  → $SCRIPT_DIR/logs/webui.log"
echo ""

tail -f \
  "$SCRIPT_DIR/logs/ollama.log" \
  "$SCRIPT_DIR/logs/webui.log" \
  2>/dev/null | awk '
    /ollama.log/ { source="[OLLAMA]" }
    /webui.log/  { source="[WEBUI] " }
    !/==>/ { print source " " $0 }
  '