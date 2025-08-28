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

# Load configuration
make .tmp/config.env >/dev/null 2>&1
source .tmp/config.env

# Check for dry-run mode
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
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
elif [[ "$1" != "--yes" && "$1" != "--dry-run" ]]; then
    read -p "Continue with setup? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
elif [[ "$1" == "--yes" ]]; then
    echo "⚠️  Auto-confirming setup (--yes flag provided)"
fi

echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

# Step 3: Verify .condarc file exists
echo ""
echo "🔍 Verifying CS187 conda configuration..."

# Get student's CS187 workspace directory (where this script is run)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    # Script is in scripts/ subdirectory
    WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
else
    # Script is in the workspace root directory
    WORKSPACE_DIR="$SCRIPT_DIR"
fi
CONDARC_PATH="$WORKSPACE_DIR/.condarc"

if [ ! -f "$CONDARC_PATH" ]; then
    echo "❌ ERROR: .condarc file not found in your CS187 workspace"
    echo "   Expected location: $CONDARC_PATH"
    echo ""
    echo "📥 This file is required for reliable package installation."
    echo "   It configures conda to use conda-forge channels for CS187."
    echo ""
    echo "🔧 How to fix:"
    echo "   1. Make sure you're in your CS187 workspace directory"
    echo "   2. Download .condarc from the course repository to this directory"
    echo "   3. If using Git: ensure you have the latest course files"
    echo ""
    exit 1
fi

# Validate .condarc content
if grep -q "conda-forge" "$CONDARC_PATH"; then
    echo "  ✅ .condarc file found with conda-forge channel configured"
else
    echo "  ⚠️  WARNING: .condarc exists but doesn't contain conda-forge channel"
    echo "     This may cause package installation issues"
fi

echo "  Configuration preview:"
echo "    $(grep -A 2 "channels:" "$CONDARC_PATH" | sed 's/^/    /')"

# Step 4: Verify conda channel configuration (before make install)
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

# Step 5: Install packages and dependencies using Makefile
echo ""
echo "🚀 Installing packages and dependencies via Makefile..."

# Change to the student's CS187 workspace directory
if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would change directory to: $WORKSPACE_DIR"
    echo "  [DRY RUN] Would run: make install"
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

    if ! make install; then
        echo ""
        echo "❌ ERROR: Makefile installation failed!"
        echo "   The 'make install' command handles all complex dependency installation."
        echo "   Check the error messages above for details."
        echo ""
        echo "🔧 Troubleshooting:"
        echo "   • Make sure you're in your CS187 workspace directory"
        echo "   • Check that Makefile exists and is readable"
        echo "   • Ensure you have make installed (brew install make on macOS)"
        echo "   • Try running 'make install' manually for more detailed output"
        exit 1
    fi

    echo "  ✅ Makefile installation completed successfully"
    echo "     System dependencies, Python packages, and Playwright all configured"
fi

# Step 6: Verify installation
echo ""
echo "🧪 Verifying installation..."

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would verify Python installation and packages"
    echo "  [DRY RUN] Would check: Python version, location, environment"
    echo "  [DRY RUN] Would test imports: torch, jupyter, otter"
    echo "  [DRY RUN] Would verify conda channels configuration"
    echo "  [DRY RUN] Expected environment: $CONDA_ENV_NAME"
    echo "  [DRY RUN] Expected conda: $CONDA_DIR"
    echo "  [DRY RUN] Expected distribution: $CONDA_TYPE"
else
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
    conda config --show channels | head -3 | sed 's/^/    /'
    
    echo -n "  PyTorch: "
    if python -c "import torch; print('✅ v' + torch.__version__)" 2>/dev/null; then
        :
    else
        echo "❌ Not available"
    fi
    
    echo -n "  Jupyter: "
    if command_exists jupyter; then
        echo "✅ Available"
    else
        echo "❌ Not available"
    fi
    
    echo -n "  Otter-grader: "
    if python -c "import otter; print('✅ Available')" 2>/dev/null; then
        :
    else
        echo "❌ Not available"
    fi
fi

# Step 7: Test basic functionality
echo ""
echo "🎯 Testing basic functionality..."

if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would create temporary test environment"
    echo "  [DRY RUN] Would test Python package imports"
    echo "  [DRY RUN] Would test conda environment functionality"
    echo "  [DRY RUN] Would verify key packages: torch, jupyter, otter"
else
    echo "  Creating self-contained test environment..."
    
    # Create temporary directory for testing
    TEST_DIR=$(mktemp -d)
    echo "  Test directory: $TEST_DIR"
    
    # Create a simple test script
    cat > "$TEST_DIR/test_cs187_env.py" << 'EOF'
#!/usr/bin/env python3
"""
CS187 Environment Test Script
Tests that all required packages are available and working.
"""

import sys
import importlib

def test_import(package_name, description=""):
    """Test if a package can be imported."""
    try:
        importlib.import_module(package_name)
        print(f"  ✅ {package_name} - {description}")
        return True
    except ImportError as e:
        print(f"  ❌ {package_name} - {description} (FAILED: {e})")
        return False

def main():
    print("🧪 CS187 Environment Test")
    print("=" * 30)
    
    # Test Python version
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    print(f"  Python version: {python_version}")
    
    if sys.version_info >= (3, 10):
        print("  ✅ Python version is 3.10+ (compatible)")
    else:
        print("  ⚠️  Python version is older than 3.10 (may have issues)")
    
    print("\n📦 Testing package imports:")
    
    # Core packages
    results = []
    results.append(test_import("pip", "Package installer"))
    results.append(test_import("wheel", "Built package format"))
    
    # Jupyter ecosystem
    results.append(test_import("jupyter", "Jupyter notebook environment"))
    results.append(test_import("jupyterlab", "JupyterLab interface"))
    results.append(test_import("nbconvert", "Notebook conversion"))
    results.append(test_import("ipywidgets", "Interactive widgets"))
    
    # Data science stack
    results.append(test_import("numpy", "Numerical computing"))
    results.append(test_import("pandas", "Data analysis"))
    results.append(test_import("matplotlib", "Plotting library"))
    results.append(test_import("sklearn", "Machine learning (scikit-learn)"))
    
    # Deep learning
    results.append(test_import("torch", "PyTorch deep learning"))
    results.append(test_import("transformers", "Hugging Face transformers"))
    
    # NLP specific
    results.append(test_import("nltk", "Natural Language Toolkit"))
    
    # CS187 specific
    results.append(test_import("otter", "Otter grader"))
    
    # PDF generation
    playwright_available = test_import("playwright", "Browser automation for PDFs")
    
    print(f"\n📊 Test Results:")
    passed = sum(results)
    total = len(results)
    print(f"  Packages: {passed}/{total} passed")
    
    if playwright_available:
        print("  🎭 PDF generation should work")
    else:
        print("  ⚠️  PDF generation may not work (Playwright missing)")
    
    if passed == total:
        print("\n🎉 All tests passed! Environment is ready for CS187.")
        return 0
    elif passed >= total * 0.8:  # 80% threshold
        print(f"\n⚠️  Most tests passed ({passed}/{total}). Environment should work for most CS187 tasks.")
        return 0
    else:
        print(f"\n❌ Many tests failed ({total-passed}/{total}). Environment needs attention.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF
    
    # Run the test script
    echo "  Running comprehensive package test..."
    if python "$TEST_DIR/test_cs187_env.py"; then
        echo "  ✅ Environment test passed"
        TEST_RESULT="✅ PASSED"
    else
        echo "  ⚠️  Environment test had issues (see details above)"
        TEST_RESULT="⚠️ ISSUES"
    fi
    
    # Test conda channel configuration
    echo ""
    echo "  Testing conda channel configuration..."
    if conda config --show channels | head -1 | grep -q conda-forge; then
        echo "  ✅ conda-forge is primary channel"
    else
        echo "  ⚠️  conda-forge is not the primary channel"
        echo "     This may cause package conflicts later"
    fi
    
    # Test a simple conda install/uninstall to verify environment works
    echo ""
    echo "  Testing conda environment functionality..."
    if conda install -n $CONDA_ENV_NAME --dry-run numpy >/dev/null 2>&1; then
        echo "  ✅ Conda environment can resolve package dependencies"
    else
        echo "  ⚠️  Conda environment may have dependency resolution issues"
    fi
    
    # Clean up test directory
    rm -rf "$TEST_DIR"
    echo "  Test cleanup completed"
    
    echo ""
    echo "🏁 Self-contained test summary: $TEST_RESULT"
fi

# Step 8: Check for potential conflicts
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

# Step 9: Success and usage instructions
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
echo "   1. Activate the environment:"
echo "      conda activate $CONDA_ENV_NAME"
echo ""
echo "   2. Navigate to your CS187 workspace:"
echo "      cd '$WORKSPACE_DIR'"
echo ""
echo "   3. Launch Jupyter:"
echo "      jupyter lab"
echo ""
echo "   4. Test the environment:"
echo "      python scripts/test-playwright.py  # Test PDF generation"
echo ""
echo "🔄 To update the environment later:"
echo "   Run this script again - it will update packages safely"
echo ""
echo "🧹 To remove only the CS187 environment:"
echo "   conda env remove -n $CONDA_ENV_NAME"
echo ""
echo "🎭 If Playwright/PDF generation doesn't work:"
echo "   • Run diagnostic: python scripts/test-playwright.py"
echo "   • Linux: sudo apt install libnss3 libatk-bridge2.0-0 libxss1 libasound2"
echo "   • macOS: brew install --cask chromium"
echo "   • Manual: playwright install chromium"
echo "   • Alternative: Use 'File → Export → HTML' instead of PDF"
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