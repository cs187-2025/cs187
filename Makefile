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

# Use single shell for entire recipes - enables proper exit handling
.ONESHELL:

# Include configuration if not already defined
ifndef CONDA_ENV_NAME
-include config.mk
endif

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
		echo "=== Network connectivity test ==="; \
		INTERNET_OK=false; \
		REPOS_OK=false; \
		\
		echo "Testing basic internet connectivity..."; \
		if ping -c 2 8.8.8.8 >/dev/null 2>&1; then \
			echo "Internet: ACCESSIBLE"; \
			INTERNET_OK=true; \
		else \
			echo "Internet: BLOCKED/LIMITED"; \
			echo "  - Cannot reach 8.8.8.8 (Google DNS)"; \
		fi; \
		\
		echo "Testing Ubuntu repository access..."; \
		if ping -c 2 archive.ubuntu.com >/dev/null 2>&1; then \
			echo "Ubuntu repos: ACCESSIBLE"; \
			REPOS_OK=true; \
		else \
			echo "Ubuntu repos: BLOCKED/LIMITED"; \
			echo "  - Cannot reach archive.ubuntu.com"; \
		fi; \
		\
		echo "Additional diagnostics:"; \
		echo "  - Available packages test:"; \
		for pkg in pandoc inkscape graphviz; do \
			if command -v $$pkg >/dev/null 2>&1; then \
				echo "    $$pkg: PRE-INSTALLED"; \
			else \
				echo "    $$pkg: Not available"; \
			fi; \
		done; \
		echo "  - Python environment test:"; \
		if command -v python3 >/dev/null 2>&1; then \
			echo "    python3: Available ($(python3 --version 2>&1))"; \
		else \
			echo "    python3: Not available"; \
		fi; \
		echo "  - Network troubleshooting:"; \
		echo "    Testing specific service connectivity:"; \
		if curl -s --connect-timeout 5 https://pypi.org >/dev/null 2>&1; then \
			echo "    PyPI (pypi.org): ACCESSIBLE"; \
		else \
			echo "    PyPI (pypi.org): BLOCKED"; \
		fi; \
		if curl -s --connect-timeout 5 https://files.pythonhosted.org >/dev/null 2>&1; then \
			echo "    PyPI files: ACCESSIBLE"; \
		else \
			echo "    PyPI files: BLOCKED"; \
		fi; \
		echo "    This appears to be a security-hardened environment with selective network access."; \
		echo "    Python packages (pip) may work while system packages (apt) are blocked."; \
		\
		if [ "$$INTERNET_OK" = false ] || [ "$$REPOS_OK" = false ]; then \
			echo ""; \
			echo "========================================"; \
			echo "WARNING: Limited network connectivity"; \
			echo "========================================"; \
			echo "Network access is restricted in this environment."; \
			echo ""; \
			echo "Status:"; \
			echo "  Internet (8.8.8.8): $$INTERNET_OK"; \
			echo "  Ubuntu repos: $$REPOS_OK"; \
			echo ""; \
			echo "Impact:"; \
			echo "  - System packages (pandoc, inkscape, graphviz) will be skipped"; \
			echo "  - Python packages (pip install) should still work"; \
			echo "  - Core Python environment will still be set up"; \
			echo "  - Autograder functionality should work normally"; \
			echo ""; \
			echo "This appears to be a security-hardened environment with selective"; \
			echo "network restrictions (Python repos allowed, system repos blocked)."; \
			echo "Continuing with available resources..."; \
			echo ""; \
		else \
			echo "Network connectivity: OK"; \
		fi; \
		echo ""; \
		\
		echo "Updating package lists..."; \
		if command -v sudo >/dev/null 2>&1; then SUDO=sudo; else SUDO=""; fi; \
		if $$SUDO apt-get update; then \
			echo "apt-get update: SUCCESS"; \
		else \
			echo "apt-get update: FAILED - network connectivity issues may prevent package installation"; \
		fi; \
		\
		if [ "$$INTERNET_OK" = true ] && [ "$$REPOS_OK" = true ]; then \
			echo "Installing core development tools via apt..."; \
			\
			# Essential packages (required for core functionality) \
			for pkg in build-essential git; do \
				if dpkg -s $$pkg >/dev/null 2>&1; then \
					echo "$$pkg already installed."; \
				else \
					echo "Installing $$pkg..."; \
					$$SUDO apt-get install -y $$pkg >/dev/null 2>&1; \
					echo "$$pkg installation completed."; \
				fi; \
			done; \
			\
			echo "Installing document processing and visualization tools..."; \
			for pkg in pandoc inkscape graphviz; do \
				if dpkg -s $$pkg >/dev/null 2>&1; then \
					echo "$$pkg already installed."; \
				else \
					echo "Attempting to install $$pkg..."; \
					if $$SUDO apt-get install -y $$pkg >/dev/null 2>&1; then \
						echo "  $$pkg: INSTALLATION SUCCESS"; \
					else \
						echo "  $$pkg: INSTALLATION FAILED"; \
						echo "  Note: This may be due to network connectivity issues in restricted environments."; \
						echo "  Core functionality will work without this package."; \
					fi; \
				fi; \
			done; \
		else \
			echo "Skipping system package installation due to network restrictions."; \
			echo "Checking for pre-installed packages..."; \
			for pkg in build-essential git pandoc inkscape graphviz; do \
				if command -v $$pkg >/dev/null 2>&1 || dpkg -s $$pkg >/dev/null 2>&1; then \
					echo "  $$pkg: Available"; \
				else \
					echo "  $$pkg: Not available (skipped)"; \
				fi; \
			done; \
		fi; \
		\
		if [ "$$INTERNET_OK" = true ] && [ "$$REPOS_OK" = true ]; then \
			echo "Installing GitHub CLI..."; \
			if ! dpkg -s gh >/dev/null 2>&1; then \
				curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg 2>/dev/null | $$SUDO gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null \
				&& echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $$SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null 2>&1 \
				&& $$SUDO apt update >/dev/null 2>&1 \
				&& $$SUDO apt install gh -y >/dev/null 2>&1; \
				echo "GitHub CLI installation completed."; \
			else \
				echo "gh already installed."; \
			fi; \
		else \
			echo "Skipping GitHub CLI installation (network restricted)."; \
			if command -v gh >/dev/null 2>&1; then \
				echo "GitHub CLI: Available"; \
			else \
				echo "GitHub CLI: Not available (skipped)"; \
			fi; \
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
		\
		echo "Configuring conda-forge as primary channel for $(CONDA_ENV_NAME)..."; \
		conda config --env --prepend channels conda-forge >/dev/null 2>&1; \
		echo "Conda configuration completed."; \
		echo "Installing all packages via pip with caching..."; \
		pip install --upgrade pip >/dev/null 2>&1; \
		pip install --cache-dir ~/.cache/pip -q -r requirements.txt; \
		echo "Python packages installation completed."; \
		\
		if [ -z "$(NO_PDFS)" ]; then \
			echo "Setting up Playwright browser automation..."; \
			playwright install-deps chromium >/dev/null 2>&1; \
			playwright install chromium >/dev/null 2>&1; \
			echo "Playwright setup completed."; \
		else \
			echo "Skipping Playwright setup (PDF generation disabled)"; \
		fi; \
		\
		echo "Registering Jupyter kernel for $(CONDA_ENV_NAME) environment..."; \
		python -m ipykernel install --user --name=$(CONDA_ENV_NAME) --display-name="Python 3 ($(CONDA_ENV_NAME))" >/dev/null 2>&1; \
		echo "Jupyter kernel registration completed."; \
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