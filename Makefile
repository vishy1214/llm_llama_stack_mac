# ═══════════════════════════════════════════════════════════════
#  LLM Stack — Mac Mini
#  Usage: make <target>
# ═══════════════════════════════════════════════════════════════

SHELL      := /bin/bash
STACK_DIR  := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
NC     := \033[0m

.DEFAULT_GOAL := help

# ═══════════════════════════════════════════════════════════════
#  HELP
# ═══════════════════════════════════════════════════════════════
.PHONY: help
help:
	@echo ""
	@echo -e "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo -e "$(BLUE)  LLM Stack — Mac Mini      $(NC)"
	@echo -e "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo -e "STACK_DIR: $(STACK_DIR)"
	@echo ""
	@echo -e "  $(GREEN)make setup$(NC)    chmod all scripts"
	@echo -e "  $(GREEN)make start$(NC)    start Ollama + model + WebUI"
	@echo -e "  $(GREEN)make stop$(NC)     stop all services"
	@echo -e "  $(GREEN)make status$(NC)   show what is running"
	@echo -e "  $(GREEN)make restart$(NC)  stop then start"
	@echo -e "  $(GREEN)make logs$(NC)     tail all logs"
	@echo ""

# ═══════════════════════════════════════════════════════════════
#  SETUP — chmod only
# ═══════════════════════════════════════════════════════════════
.PHONY: setup
setup:
	@echo -e "$(GREEN)[setup]$(NC) Setting permissions..."
	@chmod +x $(STACK_DIR)/start.sh  && echo -e "  ✓ start.sh"
	@chmod +x $(STACK_DIR)/stop.sh   && echo -e "  ✓ stop.sh"
	@chmod +x $(STACK_DIR)/status.sh && echo -e "  ✓ status.sh"
	@chmod +x $(STACK_DIR)/logs.sh   && echo -e "  ✓ logs.sh"
	@echo -e "$(GREEN)[setup]$(NC) Done"

# ═══════════════════════════════════════════════════════════════
#  START
# ═══════════════════════════════════════════════════════════════
.PHONY: start
start:
	$(STACK_DIR)/start.sh

# ═══════════════════════════════════════════════════════════════
#  STOP
# ═══════════════════════════════════════════════════════════════
.PHONY: stop
stop:
	$(STACK_DIR)/stop.sh

# ═══════════════════════════════════════════════════════════════
#  STATUS
# ═══════════════════════════════════════════════════════════════
.PHONY: status
status:
	$(STACK_DIR)/status.sh

# ═══════════════════════════════════════════════════════════════
#  RESTART
# ═══════════════════════════════════════════════════════════════
.PHONY: restart
restart:
	$(STACK_DIR)/stop.sh
	sleep 2
	$(STACK_DIR)/start.sh
# ═══════════════════════════════════════════════════════════════
#  LOGS
# ═══════════════════════════════════════════════════════════════
.PHONY: logs
logs:
	$(STACK_DIR)/logs.sh