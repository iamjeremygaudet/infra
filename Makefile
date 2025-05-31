# ##############################################################################
# Makefile for Managing Docker Compose Application Stacks
# ##############################################################################
#
# Purpose:
# --------
# This Makefile automates the management of multiple Docker Compose application
# stacks. It handles environment file generation and provides convenient targets
# for controlling stack lifecycles using Docker Compose (V2+).
#
# Core Functionality:
# -------------------
# 1. Environment File Management:
#    - Discovers stacks dynamically (assumes each subdirectory in STACKS_ROOT is a stack).
#    - For each stack, merges a common .env file (from COMMON_ENV_FILE)
#      with a stack-specific .env file (e.g., <stack_dir>/.env.<stack_name>)
#      into the final .env file (<stack_dir>/.env) used by Docker Compose.
#
# 2. Docker Compose V2+ Integration:
#    - Provides targets for individual stacks (e.g., <stack_name>-up,
#      <stack_name>-down, <stack_name>-logs, <stack_name>-build, etc.).
#    - Supports passing custom arguments to Docker Compose commands via the
#      `ARGS` variable (e.g., make <stack_name>-up ARGS="-d --build").
#    - Uses `docker compose` syntax by default (configurable via DOCKER_COMPOSE_COMMAND).
#
# 3. Aggregate Stack Management:
#    - `make all-envs`: Prepares .env files for all discovered stacks.
#    - `make up ARGS="-d"` (or `make up-all ARGS="-d"`): Brings up all stacks.
#    - `make down` (or `make down-all`): Takes down all stacks.
#    - `make clean`: Removes all generated .env files.
#
# Key Variables & Conventions:
# ----------------------------
# - STACKS_ROOT:           Root directory for all stack subdirectories.
#                          (Default: /stacks). Each direct subdirectory is treated as a stack.
# - COMMON_ENV_FILE:       Path to the common environment file.
#                          (Default: $(STACKS_ROOT)/.env.common).
# - Stack-Specific Env:    Expected as `.env.<stack_name>` within each stack's directory
#                          (e.g., $(STACKS_ROOT)/my_stack/.env.my_stack).
# - Target Env File:       Generated as `.env` within each stack's directory
#                          (e.g., $(STACKS_ROOT)/my_stack/.env).
# - Docker Compose File:   Standard `compose.yaml` is expected in each stack directory.
#
# - DOCKER_COMPOSE_COMMAND: The command to invoke Docker Compose.
#                          (Default: "docker compose" for V2+).
# - ARGS:                  Variable to pass extra arguments to Docker Compose commands.
#                          (e.g., make <stack_name>-command ARGS="...").
# - COMPOSE_COMMANDS:      List of Docker Compose sub-commands for which targets are generated.
#
# Basic Usage Examples:
# ---------------------
#   make all-envs                        # Prepare .env files for all stacks
#   make my_stack-env                    # Prepare .env file for 'my_stack'
#
#   make my_stack-up ARGS="-d"           # Start 'my_stack' in detached mode
#   make my_stack-logs ARGS="-f"         # Follow logs for 'my_stack'
#   make my_stack-build                  # Build images for 'my_stack'
#   make my_stack-exec ARGS="<service_name> bash" # Execute bash in a service
#
#   make up ARGS="-d"                    # Start all stacks in detached mode
#   make down                            # Stop all stacks
#
#   make clean                           # Remove all generated .env files
#
# Prerequisites:
# --------------
# - Docker installed and running.
# - Docker Compose V2+ installed (so the `docker compose` command is available).
# - A directory structure matching the conventions defined by STACKS_ROOT,
#   COMMON_ENV_FILE, and stack-specific environment file naming.
# - Each stack directory must contain a `compose.yaml` file.
#
# ##############################################################################

# Define root and common file paths
STACKS_ROOT := $(CURDIR)/stacks
COMMON_ENV_FILE := $(STACKS_ROOT)/.env.common

# --- Discover Stack Names ---
STACK_NAMES := $(notdir $(patsubst %/,%,$(wildcard $(STACKS_ROOT)/*/)))

# If no stacks are found, print a warning.
ifeq ($(strip $(STACK_NAMES)),)
$(warning No stack directories found in $(STACKS_ROOT). Makefile may not function as expected.)
$(warning Check STACKS_ROOT definition and your directory structure (e.g., /stacks/collect/, /stacks/acquire/))
$(warning Some targets like 'all-envs', 'clean', or Docker Compose targets might report nothing to do or fail to generate.)
endif

# --- Global Configuration for Docker Compose (V2+) ---
ARGS ?=
DOCKER_COMPOSE_COMMAND ?= docker compose
COMPOSE_COMMANDS := up down logs ps build pull restart stop start config exec

# --- Default Target ---
all: all-envs

# --- Aggregate Target for All Stack Environments ---
all-envs: $(addsuffix -env,$(STACK_NAMES))
	@if [ -z "$(strip $(STACK_NAMES))" ]; then \
		echo "No stacks found to prepare environments for." ; \
	else \
		echo "All stack environments prepared." ; \
	fi
	@echo "---"

# --- Aggregate Docker Compose Targets for All Stacks ---
# Brings up all discovered stacks.
# It's highly recommended to use ARGS="-d" for detached mode, e.g., 'make up-all ARGS="-d"'
up-all: $(addsuffix -up,$(STACK_NAMES))
	@echo ""
	@if [ -z "$(strip $(STACK_NAMES))" ]; then \
		echo "No stacks found to bring up." ; \
	else \
		echo ">>> All specified stacks have been instructed to come up. <<<" ; \
		echo "Note: For 'up-all' (or 'up'), it is highly recommended to use ARGS='-d' for detached mode." ; \
		echo "      Example: make up ARGS=\"-d\"" ; \
	fi
	@echo "---"

# Takes down all discovered stacks.
down-all: $(addsuffix -down,$(STACK_NAMES))
	@echo ""
	@if [ -z "$(strip $(STACK_NAMES))" ]; then \
		echo "No stacks found to take down." ; \
	else \
		echo ">>> All specified stacks have been instructed to go down. <<<" ; \
	fi
	@echo "---"

# Convenience aliases
up: up-all
down: down-all

# --- Clean Target ---
clean:
	@echo "Cleaning generated .env files..."
	@if [ -z "$(strip $(STACK_NAMES))" ]; then \
		echo "No stack directories found or defined. Nothing to clean based on STACK_NAMES." ; \
	else \
		for stack_name in $(STACK_NAMES); do \
			target_env_file="$(STACKS_ROOT)/$${stack_name}/.env"; \
			if [ -f "$${target_env_file}" ]; then \
				echo "Removing $${target_env_file}"; \
				rm -f "$${target_env_file}"; \
			else \
				echo "No .env file found for stack $${stack_name} at $${target_env_file} (already clean or never generated)."; \
			fi; \
		done; \
		echo "Cleanup complete for discovered stacks."; \
	fi
	@echo "---"


# --- Target Generation for Stack Environment Files ---
define ENV_TARGET_template
$(1)-env:
	$(eval STACK_NAME := $(1))
	$(eval CURRENT_STACK_DIR := $(STACKS_ROOT)/$(STACK_NAME))
	$(eval CURRENT_STACK_SPECIFIC_ENV_FILE := $(CURRENT_STACK_DIR)/.env.$(STACK_NAME))
	$(eval CURRENT_TARGET_ENV_FILE := $(CURRENT_STACK_DIR)/.env)

	@echo "Preparing environment file for stack \"$(STACK_NAME)\"..."
	@if [ ! -f "$(COMMON_ENV_FILE)" ]; then \
		echo "" >&2; \
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2; \
		echo "ERROR: CRITICAL - Common environment file \"$(COMMON_ENV_FILE)\" not found!" >&2; \
		echo "       Cannot proceed with environment generation for stack \"$(STACK_NAME)\"." >&2; \
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2; \
		exit 1; \
	fi
	@echo "Ensuring stack directory exists: $(CURRENT_STACK_DIR)"
	@mkdir -p "$(CURRENT_STACK_DIR)"
	@echo "Removing old $(CURRENT_TARGET_ENV_FILE) if it exists..."
	@rm -f "$(CURRENT_TARGET_ENV_FILE)"
	@echo "Merging environment files into $(CURRENT_TARGET_ENV_FILE)..."
	@echo "  Common input:         $(COMMON_ENV_FILE)"
	@cat "$(COMMON_ENV_FILE)" > "$(CURRENT_TARGET_ENV_FILE)"
	@if [ -f "$(CURRENT_STACK_SPECIFIC_ENV_FILE)" ]; then \
		echo "  Stack-specific input: $(CURRENT_STACK_SPECIFIC_ENV_FILE)" ; \
		echo "" >> "$(CURRENT_TARGET_ENV_FILE)"; \
		cat "$(CURRENT_STACK_SPECIFIC_ENV_FILE)" >> "$(CURRENT_TARGET_ENV_FILE)"; \
		echo "Successfully merged common and stack-specific .env files into $(CURRENT_TARGET_ENV_FILE)." ; \
	else \
		echo "  Warning: Stack-specific env file \"$(CURRENT_STACK_SPECIFIC_ENV_FILE)\" not found for stack \"$(STACK_NAME)\"." ; \
		echo "           Only common environment variables from $(COMMON_ENV_FILE) will be used for this stack." ; \
		echo "Successfully created $(CURRENT_TARGET_ENV_FILE) using only common env file." ; \
	fi
	@echo "Environment preparation complete for stack \"$(STACK_NAME)\"."
	@echo "---"
.PHONY: $(1)-env
endef

ifneq ($(strip $(STACK_NAMES)),)
  $(foreach stack,$(STACK_NAMES), \
    $(eval $(call ENV_TARGET_template,$(stack))) \
  )
endif

# --- Docker Compose Target Generation ---
define COMPOSE_TARGET_template
$(1)-$(2): $(1)-env
	$(eval TARGET_STACK_NAME := $(1))
	$(eval TARGET_COMPOSE_COMMAND := $(2))
	$(eval TARGET_STACK_DIR := $(STACKS_ROOT)/$(TARGET_STACK_NAME))
	@echo ""
	@echo ">>> Running '$(DOCKER_COMPOSE_COMMAND) $(TARGET_COMPOSE_COMMAND)' for stack \"$(TARGET_STACK_NAME)\" <<<"
	@echo "    Stack directory: $(TARGET_STACK_DIR)"
	@echo "    Compose command: $(DOCKER_COMPOSE_COMMAND) $(TARGET_COMPOSE_COMMAND) $(ARGS)"
	@if [ ! -f "$(TARGET_STACK_DIR)/compose.yaml" ]; then \
		echo "" >&2; \
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2; \
		echo "ERROR: compose.yaml not found in stack directory: $(TARGET_STACK_DIR)" >&2; \
		echo "       Cannot execute '$(DOCKER_COMPOSE_COMMAND) $(TARGET_COMPOSE_COMMAND)' for stack \"$(TARGET_STACK_NAME)\"." >&2; \
		echo "       Expected file: $(TARGET_STACK_DIR)/compose.yaml" >&2; \
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2; \
		exit 1; \
	fi
	@cd "$(TARGET_STACK_DIR)" && $(DOCKER_COMPOSE_COMMAND) $(TARGET_COMPOSE_COMMAND) $(ARGS)
	@echo "--- Docker Compose command for \"$(TARGET_STACK_NAME)\" finished ---"
.PHONY: $(1)-$(2)
endef

ifneq ($(strip $(STACK_NAMES)),)
  $(foreach stack,$(STACK_NAMES), \
    $(foreach cmd,$(COMPOSE_COMMANDS), \
      $(eval $(call COMPOSE_TARGET_template,$(stack),$(cmd))) \
    ) \
  )
else
  $(info No stacks found, Docker Compose targets will not be generated.)
endif

# --- Phony Targets ---
.PHONY: all all-envs clean \
        up-all down-all up down debug-env-vars