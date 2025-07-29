# Workspace Makefile

# Include the recursive system
repo_root = $(shell git rev-parse --show-toplevel)
include $(repo_root)/tools/makefiles/recursive.mk

# Helper function to list discovered projects
define list_projects
	@echo "Projects discovered: $(words $(MAKE_DIRS))"
	@for dir in $(MAKE_DIRS); do echo "  - $$dir"; done
	@echo ""
endef

# Default goal
.DEFAULT_GOAL := help

# Main targets
.PHONY: help install dev test check

help: ## Show this help message
	@echo ""
	@echo "Quick Start:"
	@echo "  make install         Install all dependencies"
	@echo ""
	@echo "Development:"
	@echo "  make check          Format, lint, and type-check all code"
	@echo ""
	@echo "AI Context:"
	@echo "  make ai-context-files Build AI context documentation"
	@echo ""
	@echo "Other:"
	@echo "  make clean          Clean build artifacts"
	@echo ""

# Installation
install: ## Install all dependencies
	@echo "Installing workspace dependencies..."
	uv sync --group dev
	@echo ""
	@echo "Dependencies installed!"
	@echo ""
	@if [ -n "$$VIRTUAL_ENV" ]; then \
		echo "✓ Virtual environment already active"; \
	elif [ -f .venv/bin/activate ]; then \
		echo "→ Run this command: source .venv/bin/activate"; \
	else \
		echo "✗ No virtual environment found. Run 'make install' first."; \
	fi

# Code quality
# check is handled by recursive.mk automatically

# AI Context
ai-context-files: ## Build AI context files
	@echo "Building AI context files..."
	uv run python tools/build_ai_context_files.py
	uv run python tools/build_git_collector_files.py
	@echo "AI context files generated"

# Workspace info
workspace-info: ## Show workspace information
	@echo ""
	@echo "Workspace"
	@echo "==============="
	@echo ""
	$(call list_projects)
	@echo ""
