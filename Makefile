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
	@echo "  make worktree NAME   Create git worktree with .data copy"
	@echo "  make worktree-rm NAME  Remove worktree and delete branch"
	@echo "  make worktree-rm-force NAME  Force remove (even with changes)"
	@echo ""
	@echo "AI Context:"
	@echo "  make ai-context-files Build AI context documentation"
	@echo ""
	@echo "Other:"
	@echo "  make clean          Clean build artifacts"
	@echo "  make clean-wsl-files Clean up WSL-related files"
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

# Git worktree management
worktree: ## Create a git worktree with .data copy. Usage: make worktree feature-name
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Error: Please provide a branch name. Usage: make worktree feature-name"; \
		exit 1; \
	fi
	@python tools/create_worktree.py "$(filter-out $@,$(MAKECMDGOALS))"

worktree-rm: ## Remove a git worktree and delete branch. Usage: make worktree-rm feature-name
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Error: Please provide a branch name. Usage: make worktree-rm feature-name"; \
		exit 1; \
	fi
	@python tools/remove_worktree.py "$(filter-out $@,$(MAKECMDGOALS))"

worktree-rm-force: ## Force remove a git worktree (even with changes). Usage: make worktree-rm-force feature-name
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Error: Please provide a branch name. Usage: make worktree-rm-force feature-name"; \
		exit 1; \
	fi
	@python tools/remove_worktree.py "$(filter-out $@,$(MAKECMDGOALS))" --force

# Catch-all target to prevent "No rule to make target" errors for branch names
%:
	@:

# AI Context
ai-context-files: ## Build AI context files
	@echo "Building AI context files..."
	uv run python tools/build_ai_context_files.py
	uv run python tools/build_git_collector_files.py
	@echo "AI context files generated"

# Clean WSL Files
clean-wsl-files: ## Clean up WSL-related files (Zone.Identifier, sec.endpointdlp)
	@echo "Cleaning WSL-related files..."
	@uv run python tools/clean_wsl_files.py

# Workspace info
workspace-info: ## Show workspace information
	@echo ""
	@echo "Workspace"
	@echo "==============="
	@echo ""
	$(call list_projects)
	@echo ""
