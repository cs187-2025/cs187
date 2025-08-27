# =============================================================================
# CS187 Course Materials - Installation Makefile
# =============================================================================
# This Makefile handles the complete setup of the development environment
# for CS187 students. It can be used standalone or included in the main build system.
#
# USAGE:
#   Standalone: make -f install.mk install
#   Included:   make install (from main Makefile)
# =============================================================================

# Include configuration if not already defined
ifndef CONDA_ENV_NAME
-include config.mk
endif

# Python version used throughout the project
PYTHON_VERSION := 3.10

# PDF Generation Control
# =============================================================================
# Support for disabling PDF generation to speed up builds and avoid
# Playwright/Chromium dependencies. Can be controlled via:
# 1. Environment variable: CS187_NO_PDFS=1 make -f install.mk install
# 2. Command-line argument: make -f install.mk install NO_PDFS=1
# 3. Global export: export CS187_NO_PDFS=1
# =============================================================================

# Check for no-PDF flags (environment variable or make argument)
ifdef CS187_NO_PDFS
  NO_PDFS := 1
endif
ifdef NO_PDFS
  NO_PDFS := 1
endif

# Installation target for GitHub Actions and local development
# 
# This target handles the complete setup of the development environment:
# 1. Platform Detection: Identify the operating system (macOS vs Ubuntu/Linux)
# 2. System Dependencies: Install required system packages via package managers
# 3. Conda Installation: Install Miniforge3 if conda is not already available
# 4. Python Environment: Create and configure the $(CONDA_ENV_NAME) conda environment
# 5. Python Packages: Install all required Python dependencies
# 6. Browser Setup: Configure Playwright with Chromium for PDF generation
install:
	@echo "=== Installing CS187 development environment ==="
	
	# =================================================================
	# STEP 1: Platform Detection & System Dependencies Installation
	# =================================================================
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "=== macOS detected - Installing system dependencies ==="; \
		\
		echo "Installing core development tools via Homebrew..."; \
		for pkg in git pandoc inkscape graphviz; do \
			if ! brew list --formula | grep -q "^$$pkg$$"; then \
				echo "Installing $$pkg..."; \
				brew install $$pkg; \
			else \
				echo "$$pkg already installed."; \
			fi; \
		done; \
		\
		echo "Installing GitHub CLI..."; \
		if ! brew list --formula | grep -q "^gh$$"; then \
			echo "Installing gh..."; \
			brew install gh; \
		else \
			echo "gh already installed."; \
		fi; \
		\
		echo "Checking for conda installation..."; \
		if ! command -v conda >/dev/null 2>&1; then \
			if [ -n "$$GITHUB_ACTIONS" ]; then \
				echo "ERROR: conda not found in GitHub Actions environment"; \
				echo "This should be installed by the conda-incubator/setup-miniconda action"; \
				exit 1; \
			else \
				echo "Installing Miniforge3 (conda for Apple Silicon)..."; \
				curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"; \
				bash Miniforge3-MacOSX-arm64.sh -b -p $$HOME/miniforge3; \
				rm -f Miniforge3-MacOSX-arm64.sh; \
			fi; \
		else \
			echo "conda already installed."; \
		fi; \
		\
	elif [ -f /etc/debian_version ]; then \
		echo "=== Ubuntu/Debian detected - Installing system dependencies ==="; \
		\
		echo "Updating package lists..."; \
		if command -v sudo >/dev/null 2>&1; then SUDO=sudo; else SUDO=""; fi; \
		$$SUDO apt-get update; \
		\
		echo "Installing core development tools via apt..."; \
		for pkg in build-essential git pandoc inkscape graphviz; do \
			if dpkg -s $$pkg >/dev/null 2>&1; then \
				echo "$$pkg already installed."; \
			else \
				echo "Installing $$pkg..."; \
				$$SUDO apt-get install -y $$pkg; \
			fi; \
		done; \
		\
		echo "Installing GitHub CLI..."; \
		if ! dpkg -s gh >/dev/null 2>&1; then \
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $$SUDO gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
			&& echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $$SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
			&& $$SUDO apt update \
			&& $$SUDO apt install gh -y; \
		else \
			echo "gh already installed."; \
		fi; \
		\
		echo "Checking for conda installation..."; \
		if ! command -v conda >/dev/null 2>&1; then \
			if [ -n "$$GITHUB_ACTIONS" ]; then \
				echo "ERROR: conda not found in GitHub Actions environment"; \
				echo "This should be installed by the conda-incubator/setup-miniconda action"; \
				exit 1; \
			else \
				echo "Installing Miniforge3 (conda for Linux)..."; \
				ARCH=$$(uname -m); \
				if [ "$$ARCH" = "aarch64" ]; then \
					CONDA_INSTALLER="Miniforge3-Linux-aarch64.sh"; \
				else \
					CONDA_INSTALLER="Miniforge3-Linux-x86_64.sh"; \
				fi; \
				curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/$$CONDA_INSTALLER"; \
				bash $$CONDA_INSTALLER -b -p $$HOME/miniforge3; \
				rm -f $$CONDA_INSTALLER; \
			fi; \
		else \
			echo "conda already installed."; \
		fi; \
		\
	else \
		echo "ERROR: Unsupported operating system detected."; \
		echo "This installation script supports macOS and Ubuntu/Debian only."; \
		echo "Please install dependencies manually for your platform."; \
		exit 1; \
	fi

	# =================================================================
	# STEP 2: Python Environment Setup
	# =================================================================
	@echo "=== Setting up Python environment ==="
	
	# Add all common conda installation paths to PATH
	export PATH="$$HOME/miniforge3/bin:$$HOME/miniconda3/bin:$$HOME/anaconda3/bin:/opt/conda/bin:/usr/share/miniconda/bin:$$PATH"
	
	# Verify conda is available and configure it
	if command -v conda >/dev/null 2>&1; then \
		echo "conda found: $$(conda --version)"; \
		echo "Initializing conda for current shell..."; \
		eval "$$(conda shell.bash hook)"; \
		\
		echo "Setting up $(CONDA_ENV_NAME) environment..."; \
		if conda env list | grep -q "$(CONDA_ENV_NAME)"; then \
			echo "Environment '$(CONDA_ENV_NAME)' already exists, updating packages..."; \
		else \
			echo "Creating new conda environment '$(CONDA_ENV_NAME)' with Python $(PYTHON_VERSION)..."; \
			conda create -n $(CONDA_ENV_NAME) python=$(PYTHON_VERSION) -y; \
		fi; \
		\
		echo "Activating environment and installing Python packages..."; \
		conda activate $(CONDA_ENV_NAME); \
		echo "Installing all packages via pip with caching..."; \
		pip install --upgrade pip; \
		pip install --cache-dir ~/.cache/pip -q -r requirements.txt; \
		\
		if [ -z "$(NO_PDFS)" ]; then \
			echo "Setting up Playwright browser automation..."; \
			playwright install-deps chromium; \
			playwright install chromium; \
		else \
			echo "Skipping Playwright setup (PDF generation disabled)"; \
		fi; \
		\
		echo "Registering Jupyter kernel for $(CONDA_ENV_NAME) environment..."; \
		python -m ipykernel install --user --name=$(CONDA_ENV_NAME) --display-name="Python 3 ($(CONDA_ENV_NAME))"; \
		\
	else \
		echo "ERROR: Conda installation failed or not found in PATH"; \
		echo "Checked paths: $$PATH"; \
		exit 1; \
	fi

	@echo "=== Installation complete ==="
	@echo "Environment '$(CONDA_ENV_NAME)' is ready for use"
	@echo "Jupyter kernel '$(CONDA_ENV_NAME)' has been registered"
	@echo "Run 'conda activate $(CONDA_ENV_NAME)' to activate the environment"

# Help target for standalone usage
install-help:
	@echo "=== CS187 Environment Setup ==="
	@echo ""
	@echo "TARGETS:"
	@echo "  install     Install complete development environment"
	@echo "  help        Show this help message"
	@echo ""
	@echo "USAGE:"
	@echo "  make install                   # Full install with PDF support"
	@echo "  make install NO_PDFS=1         # Install without Chromium browser"
	@echo "  make help                      # Show this help"
	@echo ""
	@echo "PDF GENERATION CONTROL:"
	@echo "  By default, the environment includes PDF generation capabilities."
	@echo "  To skip PDF generation (faster install, no Chromium browser needed):"
	@echo ""
	@echo "  Environment variable:"
	@echo "    export CS187_NO_PDFS=1"
	@echo "    make install"
	@echo ""
	@echo "  Command-line argument:"
	@echo "    make install NO_PDFS=1"
	@echo "    CS187_NO_PDFS=1 make install"
	@echo ""

.PHONY: install install-help 