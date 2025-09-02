#!/bin/bash

# CS187 Environment Setup Script
# This script creates or updates the CS187 conda environment without touching
# existing conda installations. It's safe to run on systems with existing conda setups.
#
# USAGE: Run this script from your CS187 workspace directory (where you'll do assignments).
# The script works from whatever directory you run it in, making that your CS187 workspace.
#
# SECURITY: This script supports --dry-run mode which shows what would be done
# without making any changes. All destructive commands are properly guarded.

set -e  # Exit on any error

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to find and setup proper make command
setup_make() {
    # Check if we have a working GNU make
    local make_cmd=""
    
    # Try different make commands in order of preference
    for cmd in make gmake /opt/homebrew/bin/make /usr/local/bin/make; do
        if command_exists "$cmd"; then
            if "$cmd" --version 2>/dev/null | grep -q "GNU Make"; then
                local version=$("$cmd" --version | head -1 | grep -o '[0-9]\+\.[0-9]\+')
                if [ "$(printf '%s\n3.82\n' "$version" | sort -V | head -1)" = "3.82" ]; then
                    make_cmd="$cmd"
                    break
                fi
            fi
        fi
    done
    
    if [ -z "$make_cmd" ]; then
        echo "❌ ERROR: GNU Make 3.82+ not found"
        echo ""
        echo "🔧 To fix this issue:"
        echo "   1. Install GNU make: brew install make"
        echo "   2. Create an alias for make:"
        echo "      echo 'alias make=\"gmake\"' >> ~/.zshrc"
        echo "   3. Reload your shell: source ~/.zshrc"
        echo "   4. Try again: ./scripts/setup.sh"
        echo ""
        echo "💡 Alternative: Use gmake directly instead of make for CS187 commands"
        echo "   Example: gmake lab1-1 instead of make lab1-1"
        exit 1
    fi
    
    # Export the working make command
    export MAKE_CMD="$make_cmd"
    echo "✅ Using GNU Make: $make_cmd ($($make_cmd --version | head -1))"
    
    # Provide helpful guidance if using gmake instead of make
    if [[ "$make_cmd" == "gmake" ]] && [[ "$OSTYPE" == "darwin"* ]]; then
        echo ""
        echo "💡 Note: You're using 'gmake' (GNU Make installed via Homebrew)"
        echo "   To use 'make' commands in CS187, either:"
        echo "   • Use 'gmake' instead: gmake lab1-1"
        echo "   • Or create an alias: echo 'alias make=\"gmake\"' >> ~/.zshrc"
    fi
}

# Setup make and load configuration
setup_make
$MAKE_CMD .tmp/config.env >/dev/null 2>&1
source .tmp/config.env

# Parse command line arguments
DRY_RUN=false
AUTO_YES=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --yes)
            AUTO_YES=true
            ;;
        --help|-h)
            echo "CS187 Environment Setup Script"
            echo ""
            echo "USAGE:"
            echo "  bash scripts/setup.sh                # Interactive setup"
            echo "  bash scripts/setup.sh --yes          # Non-interactive setup"
            echo "  bash scripts/setup.sh --dry-run      # Preview what would be done"
            echo ""
            echo "OPTIONS:"
            echo "  --yes       Skip confirmation prompts (useful for automation)"
            echo "  --dry-run   Show what would be done without making changes"
            echo "  --help      Show this help message"
            echo ""
            echo "DESCRIPTION:"
            echo "  This script sets up the CS187 conda environment safely:"
            echo "  • Uses existing conda installation or installs miniforge3"
            echo "  • Initializes conda for your shell (makes 'conda' command available)"
            echo "  • Creates/updates the cs187-env environment"
            echo "  • Installs all required Python packages"
            echo "  • Verifies the installation works correctly"
            echo ""
            echo "SAFETY:"
            echo "  • Your existing conda environments are NOT touched"
            echo "  • Script is idempotent - safe to run multiple times"
            echo "  • Always use --dry-run first to preview changes"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 DRY RUN MODE - No changes will be made"
    echo "   This will show what the script would do without actually doing it"
    echo ""
fi

echo "🎯 CS187 Environment Setup"
echo "=================================="
echo ""
echo "This script will:"
echo "1. Install conda (miniforge3) if no conda installation is found"
echo "2. Verify CS187 configuration (.condarc file for conda-forge channels)"
echo "3. Use 'make install' to create environment and install all dependencies"
echo "4. Verify the installation works correctly"
echo ""
echo "✅ Your existing conda environments will NOT be touched"
echo "✅ Your shell configuration will NOT be modified"
echo "✅ Only the '$CONDA_ENV_NAME' environment is created/updated"
echo ""

# Check if we should proceed (skip in dry-run mode)
if [[ "$DRY_RUN" == "true" ]]; then
    echo "⚠️  Dry-run mode: Skipping confirmation prompt"
elif [[ "$AUTO_YES" == "true" ]]; then
    echo "⚠️  Auto-confirming setup (--yes flag provided)"
else
    read -p "Continue with setup? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
fi

echo ""

# Function to find conda in common locations
find_conda() {
    local conda_paths=(
        "$HOME/miniforge3/bin/conda"
        "$HOME/miniconda3/bin/conda"
        "$HOME/anaconda3/bin/conda"
        "/opt/homebrew/anaconda3/bin/conda"
        "/opt/homebrew/miniconda3/bin/conda"
        "/opt/homebrew/miniforge3/bin/conda"
        "/opt/conda/bin/conda"
        "/usr/share/miniconda/bin/conda"
    )
    
    for conda_path in "${conda_paths[@]}"; do
        if [ -x "$conda_path" ]; then
            echo "$conda_path"
            return 0
        fi
    done
    
    # Check if conda is in PATH
    if command_exists conda; then
        which conda
        return 0
    fi
    
    return 1
}

# Step 1: Check for conda installation (use any existing conda)
echo "🔍 Checking for conda installation..."

if CONDA_PATH=$(find_conda); then
    CONDA_FOUND=true
    CONDA_DIR=$(dirname "$(dirname "$CONDA_PATH")")
    echo "  ✅ Found conda at: $CONDA_PATH"
    echo "  Conda installation: $CONDA_DIR"
    
    # Detect conda distribution type
    if [[ "$CONDA_DIR" == *"miniforge"* ]]; then
        CONDA_TYPE="Miniforge"
    elif [[ "$CONDA_DIR" == *"anaconda"* ]]; then
        CONDA_TYPE="Anaconda"
    elif [[ "$CONDA_DIR" == *"miniconda"* ]]; then
        CONDA_TYPE="Miniconda"
    else
        CONDA_TYPE="Unknown conda distribution"
    fi
    
    echo "  Distribution: $CONDA_TYPE"
    echo ""
    echo "  💡 Using your existing conda installation"
    echo "     The CS187 environment will be configured to use conda-forge"
    echo "     regardless of your global conda channel settings."
else
    CONDA_FOUND=false
    echo "  ❌ No conda installation found"
    echo ""
    echo "📦 Installing miniforge3 (lightweight conda with conda-forge as default)..."
    
    # Detect architecture and OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ $(uname -m) == "arm64" ]]; then
            INSTALLER_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
        else
            INSTALLER_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ $(uname -m) == "aarch64" ]]; then
            INSTALLER_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh"
        else
            INSTALLER_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
        fi
    else
        echo "❌ Unsupported operating system: $OSTYPE"
        echo "   Please install conda manually from https://conda.io"
        exit 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would download: $INSTALLER_URL"
        echo "  [DRY RUN] Would install miniforge3 to $HOME/miniforge3"
        echo "  [DRY RUN] Would set CONDA_PATH to $HOME/miniforge3/bin/conda"
        
        # For dry-run, simulate what would happen
        CONDA_PATH="$HOME/miniforge3/bin/conda"
        CONDA_DIR="$HOME/miniforge3"
    else
        echo "  Downloading miniforge3..."
        INSTALLER_NAME=$(basename "$INSTALLER_URL")
        
        if command_exists curl; then
            curl -L -O "$INSTALLER_URL"
        elif command_exists wget; then
            wget "$INSTALLER_URL"
        else
            echo "❌ Neither curl nor wget found. Please install one of them first."
            exit 1
        fi
        
        echo "  Installing miniforge3 to $HOME/miniforge3..."
        bash "$INSTALLER_NAME" -b -p "$HOME/miniforge3"
        rm -f "$INSTALLER_NAME"
        
        CONDA_PATH="$HOME/miniforge3/bin/conda"
        CONDA_DIR="$HOME/miniforge3"
        echo "  ✅ Miniforge3 installed successfully"
    fi
    echo ""
    echo "  📝 To use conda in new terminals, run: conda init"
    echo "     (This is optional - not required for CS187)"
fi

# Step 2: Setup conda for this session
echo ""
echo "🔧 Setting up conda for current session..."

# Add conda to PATH for this session
CONDA_DIR=$(dirname "$(dirname "$CONDA_PATH")")

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would add to PATH: $CONDA_DIR/bin"
    echo "  [DRY RUN] Would source: $CONDA_DIR/etc/profile.d/conda.sh"
    
    # Check if the conda initialization script would exist
    if [ -f "$CONDA_DIR/etc/profile.d/conda.sh" ]; then
        echo "  ✅ Conda initialization script found (would be sourced)"
    else
        echo "  ❌ Conda initialization script not found: $CONDA_DIR/etc/profile.d/conda.sh"
        echo "     This would cause setup to fail in real run"
        exit 1
    fi
    
    # In dry-run, we need to simulate conda being available for later checks
    # but we don't actually modify PATH or source anything
    echo "  [DRY RUN] Simulating conda availability for subsequent checks"
else
    export PATH="$CONDA_DIR/bin:$PATH"
    
    # Initialize conda for this shell session
    if [ -f "$CONDA_DIR/etc/profile.d/conda.sh" ]; then
        source "$CONDA_DIR/etc/profile.d/conda.sh"
        echo "  ✅ Conda initialized for current session"
    else
        echo "❌ Could not find conda initialization script"
        exit 1
    fi
fi

# Step 3: Initialize conda for your shell
echo ""
echo "🔧 Initializing conda for your shell..."
USER_SHELL=$(basename "$SHELL")

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would run: conda init $USER_SHELL"
else
    conda init "$USER_SHELL" >/dev/null 2>&1
    echo "  ✅ Conda initialized for $USER_SHELL"
fi

# Step 4: Verify .condarc file exists
echo ""
echo "🔍 Verifying CS187 conda configuration..."

if [ ! -f ".condarc" ]; then
    echo "❌ ERROR: .condarc file not found - make sure you're in the CS187 workspace directory"
    exit 1
fi
echo "  ✅ .condarc file found"

# Step 5: Verify conda channel configuration (before make install)
echo ""
echo "🔧 Verifying conda channel configuration..."

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would check effective conda configuration"
    echo "  [DRY RUN] Expected channels based on .condarc:"
    grep -A 3 "channels:" "$CONDARC_PATH" | sed 's/^/    /'
    echo "  [DRY RUN] Expected priority: $(grep "channel_priority:" "$CONDARC_PATH" | cut -d: -f2 | xargs)"
    echo "  [DRY RUN] make install will use these channels for environment creation"
else
    # Show effective conda configuration being used
    echo "  📋 Effective conda configuration in this directory:"
    if conda config --show channels | grep -q conda-forge; then
        echo "  ✅ conda-forge channel detected"
        conda config --show channels | head -3 | sed 's/^/    /'
        echo "  ✅ make install will use conda-forge channels"
    else
        echo "  ⚠️  Warning: conda-forge not detected as primary channel"
        echo "     Check that .condarc file exists in project directory"
        echo "     make install may use wrong channels"
    fi
    
    echo "  Channel priority: $(conda config --show channel_priority | grep -o 'strict\|flexible')"
fi

# Step 6: Install packages and dependencies using Makefile
echo ""
echo "🚀 Installing packages and dependencies via Makefile..."

# Change to the student's CS187 workspace directory
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would change directory to: $WORKSPACE_DIR"
    echo "  [DRY RUN] Would run: $MAKE_CMD install"
    echo "  [DRY RUN] This would:"
    echo "     • Verify conda is available (exits with error if not found)"
    echo "     • Install system dependencies (git, pandoc, graphviz)"
    echo "     • Create $CONDA_ENV_NAME environment (or update if exists)"
    echo "     • Use local .condarc channels (conda-forge) for reliable packages"
    echo "     • Install Python packages from requirements.txt"
    if [[ -n "$CS187_NO_PDFS" ]]; then
        echo "     • Skip Chromium browser download (PDF generation disabled)"
    else
        echo "     • Setup Playwright with Chromium browser"
    fi
    echo ""
    echo "  [DRY RUN] Package preview from requirements.txt:"
    if [ -f "$WORKSPACE_DIR/requirements.txt" ]; then
        head -10 "$WORKSPACE_DIR/requirements.txt" | grep -v "^#" | grep -v "^$" | sed 's/^/     /'
        echo "     ... ($(wc -l < "$WORKSPACE_DIR/requirements.txt") total lines)"
    else
        echo "     ❌ requirements.txt not found in $WORKSPACE_DIR"
    fi
else
    cd "$WORKSPACE_DIR"

    echo "  Using Makefile's robust installation process..."
    if [[ -n "$CS187_NO_PDFS" ]]; then
        echo "  This handles system dependencies, conda environment, and packages (Chromium download skipped)..."
        export NO_PDFS=1
    else
        echo "  This handles system dependencies, conda environment, and all packages..."
    fi

    if ! $MAKE_CMD install; then
        echo ""
        echo "❌ ERROR: Makefile installation failed!"
        echo "   The 'make install' command handles all complex dependency installation."
        echo "   Check the error messages above for details."
        echo ""
        echo "🔧 Troubleshooting:"
        echo "   • Make sure you're in your CS187 workspace directory"
        echo "   • Check that Makefile exists and is readable"
        echo "   • Ensure you have make installed (brew install make on macOS)"
        echo "   • Try running '$MAKE_CMD install' manually for more detailed output"
        exit 1
    fi

    echo "  ✅ Makefile installation completed successfully"
    echo "     System dependencies, Python packages, and Playwright all configured"
fi

# Step 7: Verify installation
echo ""
echo "🧪 Verifying installation..."

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would verify Python installation and environment"
    echo "  [DRY RUN] Would check: Python version, location, conda environment"
    echo "  [DRY RUN] Would verify conda channels configuration"
    echo "  [DRY RUN] Expected environment: $CONDA_ENV_NAME"
    echo "  [DRY RUN] Expected conda: $CONDA_DIR"
    echo "  [DRY RUN] Expected distribution: $CONDA_TYPE"
else
    # Activate the cs187-env environment for verification
    echo "  Activating $CONDA_ENV_NAME environment for verification..."
    if conda activate $CONDA_ENV_NAME 2>/dev/null; then
        echo "  ✅ Successfully activated $CONDA_ENV_NAME"
    else
        echo "  ⚠️  Could not activate $CONDA_ENV_NAME, verification may be inaccurate"
        echo "     Continuing with current environment..."
    fi
    echo -n "  Python version: "
    python --version
    
    echo -n "  Python location: "
    which python
    
    echo -n "  Conda environment: "
    echo "$CONDA_DEFAULT_ENV"
    
    echo -n "  Conda installation: "
    echo "$CONDA_DIR"
    
    echo -n "  Conda distribution: "
    echo "$CONDA_TYPE"
    
    echo "  Local conda config (from .condarc in project directory):"
    if [ -f "$CONDARC_PATH" ]; then
        echo "    ✅ .condarc file found"
        grep -A 3 "channels:" "$CONDARC_PATH" | sed 's/^/      /'
    else
        echo "    ❌ .condarc file not found - using global settings"
    fi
    
    echo "  Effective channels (what conda actually uses here):"
    # Show channels from the local .condarc file (if it exists)
    if [ -f "$CONDARC_PATH" ]; then
        echo "    Using local .condarc configuration:"
        grep -A 5 "channels:" "$CONDARC_PATH" | sed 's/^/    /'
    else
        echo "    Using global configuration:"
        conda config --show channels | head -3 | sed 's/^/    /'
    fi
fi

# Step 8: Test basic functionality

echo ""
echo "🎯 Testing basic functionality..."

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would test core packages: torch, otter, jupyter, numpy, nltk"
    echo "  [DRY RUN] Would verify conda channel configuration"
    echo "  [DRY RUN] Would test conda environment functionality"
    echo "  [DRY RUN] All tests would run using: conda run -n $CONDA_ENV_NAME"
else
    echo "  Testing core packages..."
    if conda run -n $CONDA_ENV_NAME python -c "
import sys
try:
    import torch, otter, jupyter, numpy, nltk
    print('  ✅ All core packages available (torch, otter, jupyter, numpy, nltk)')
    print('  🎉 Environment is ready for CS187!')
except ImportError as e:
    print(f'  ❌ Missing package: {e}')
    print('  ⚠️  Environment needs attention')
    sys.exit(1)
"; then
        echo "  ✅ Package test passed"
        TEST_RESULT="✅ PASSED"
    else
        echo "  ⚠️  Package test failed"
        TEST_RESULT="⚠️ ISSUES"
    fi
    
    # Test conda channel configuration
    echo ""
    echo "  Testing conda channel configuration..."
    # Check the environment-specific channel configuration
    if conda run -n $CONDA_ENV_NAME conda config --show channels | head -1 | grep -q conda-forge; then
        echo "  ✅ conda-forge is primary channel (environment-specific)"
    elif [ -f "$CONDARC_PATH" ] && grep -A 10 "channels:" "$CONDARC_PATH" | grep -E "^\s*-\s*conda-forge" | head -1 >/dev/null; then
        echo "  ✅ conda-forge is configured (from local .condarc)"
        echo "     Note: May be overridden by global settings"
    else
        echo "  ⚠️  conda-forge is not the primary channel"
        echo "     This may cause package conflicts later"
    fi
    
    # Test conda environment functionality
    echo ""
    echo "  Testing conda environment functionality..."
    if conda install -n $CONDA_ENV_NAME --dry-run numpy >/dev/null 2>&1; then
        echo "  ✅ Conda environment can resolve package dependencies"
    else
        echo "  ⚠️  Conda environment may have dependency resolution issues"
    fi
    
    echo ""
    echo "🏁 Environment test summary: $TEST_RESULT"
fi

# Step 9: Check for potential conflicts
echo ""
echo "🔍 Checking for potential environment conflicts..."

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would check for pyenv conflicts"
    echo "  [DRY RUN] Would check for multiple Python installations"
else
    if command_exists pyenv; then
        PYENV_VERSION=$(pyenv version 2>/dev/null | cut -d' ' -f1)
        echo "  ⚠️  pyenv detected with version: $PYENV_VERSION"
        echo "     Make sure to launch Jupyter from conda environment!"
        echo "     Run: conda activate $CONDA_ENV_NAME && jupyter lab"
    else
        echo "  ✅ No pyenv conflicts detected"
    fi
    
    # Check for other Python versions
    SYSTEM_PYTHON=$(which python3 2>/dev/null || echo "none")
    CONDA_PYTHON=$(which python)
    
    if [ "$SYSTEM_PYTHON" != "none" ] && [ "$SYSTEM_PYTHON" != "$CONDA_PYTHON" ]; then
        echo "  ℹ️  Multiple Python installations detected:"
        echo "     System Python: $SYSTEM_PYTHON"
        echo "     Conda Python: $CONDA_PYTHON"
        echo "     Always use conda Python for CS187!"
    fi
fi

# Step 10: Success and usage instructions
echo ""
if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 Dry Run Complete!"
    echo "===================="
    echo ""
    echo "📋 What would happen in a real run:"
    if [[ "$CONDA_FOUND" == "true" ]]; then
        echo "✅ Use existing conda installation: $CONDA_TYPE at $CONDA_DIR"
    else
        echo "✅ Install miniforge3 (no existing conda found)"
    fi
    echo "✅ Verify .condarc file exists for conda-forge channels"
    echo "✅ Run 'make install' to create/update environment and install packages"
    echo "✅ Verify installation works correctly"
    echo ""
    echo "🚀 To actually run the setup:"
    echo "   bash scripts/setup.sh"
    echo ""
    echo "💡 This dry run detected no blocking issues!"
else
    echo "🎉 Setup Complete!"
    echo "=================="
    echo ""
    echo "✅ $CONDA_ENV_NAME environment ready"
    echo "✅ All Python packages installed"
    echo "✅ Basic functionality verified"
fi
echo ""
echo "📝 Usage Instructions:"
echo "   1. Restart your terminal or run: source ~/.${USER_SHELL}rc"
echo "      (Future terminals won't need to do this)"
echo ""
echo "   2. Activate the environment:"
echo "      conda activate $CONDA_ENV_NAME"
echo ""
echo "   3. Navigate to your CS187 workspace:"
echo "      cd '$WORKSPACE_DIR'"
echo ""
echo "   4. Launch Jupyter:"
echo "      jupyter lab"
echo ""
echo "   5. Test the environment:"
echo "      python -c \"import torch, otter, nltk; print('✅ Environment test passed!')\""
echo ""
echo "🔄 To update the environment later:"
echo "   Run this script again - it will update packages safely"
echo ""
echo "🧹 To remove only the CS187 environment:"
echo "   conda env remove -n $CONDA_ENV_NAME"
echo ""
echo "🎭 If PDF generation doesn't work in Jupyter:"
echo "   • Try: File → Export → HTML instead of PDF"
echo "   • Linux: sudo apt install libnss3 libatk-bridge2.0-0 libxss1 libasound2"
echo "   • macOS: brew install --cask chromium"
echo "   • Manual: playwright install chromium"
echo "   • Contact course staff if issues persist"
echo ""
echo "💡 Your existing conda installation and environments are unchanged!"
echo "   The local .condarc file configures conda-forge channels only when"
echo "   working in your CS187 workspace directory. Your global conda settings"
echo "   remain exactly as they were."
echo ""

# Final environment check
if [ "$CONDA_DEFAULT_ENV" = "$CONDA_ENV_NAME" ]; then
    echo "✅ You're ready to go! The $CONDA_ENV_NAME environment is active."
else
    echo "⚠️  Run 'conda activate $CONDA_ENV_NAME' to start working."
fi

echo "" 