# CS187 Conda Setup Guide

## Overview

This project uses a **local `.condarc` file** to ensure reliable package installation regardless of your existing conda setup. This approach is gentle and preserves all your existing conda environments and configurations.

## How It Works

### Local Configuration Overrides
When you run conda commands from the CS187 Materials directory, conda automatically uses the local `.condarc` file which:
- Sets `conda-forge` as the primary channel
- Uses strict channel priority to prevent package conflicts
- Ensures PyTorch, Jupyter, and other packages install correctly

### Your Setup Remains Unchanged
- ✅ Your global conda configuration is preserved
- ✅ Your existing environments are untouched  
- ✅ Works with any conda distribution (Anaconda, Miniconda, Miniforge)
- ✅ No system-wide changes or installations required

## Quick Setup

### 1. Run the Setup Script
```bash
# From the CS187 Materials directory
bash scripts/setup.sh

# For faster setup without PDF generation capabilities (optional)
CS187_NO_PDFS=1 bash scripts/setup.sh
```

This script:
- Uses your existing conda installation (any distribution)
- Creates the `otter-latest` environment
- Installs all required packages using conda-forge
- Verifies everything works correctly
- With `CS187_NO_PDFS=1`: Skips Chromium browser download (faster, lighter setup)

### 2. Daily Usage
```bash
# Always work from the CS187 Materials directory
cd /path/to/CS187/Materials

# Activate the CS187 environment
conda activate otter-latest

# Launch Jupyter (will use correct packages)
jupyter lab
```

## Troubleshooting

### Check Configuration
```bash
# See what conda configuration is active
bash scripts/check-conda-channels.sh

# Test Playwright (for PDF generation)
python scripts/test-playwright.py
```

### Common Issues

**"Packages not found" or "Version conflicts"**
- Make sure you're in the CS187 Materials directory
- Check that `.condarc` file exists in the project root
- Run `conda config --show channels` to verify conda-forge is listed first

**"PDF generation doesn't work"**
- Run the Playwright diagnostic: `python scripts/test-playwright.py`
- Try installing system dependencies (script provides platform-specific commands)
- Alternative: Use File → Export → HTML instead of PDF

**"Wrong Python/packages being used"**
- Make sure `otter-latest` environment is active: `conda activate otter-latest`
- Check Python location: `which python` (should be in otter-latest environment)
- Restart Jupyter after activating the environment

## Technical Details

### Conda Configuration Hierarchy
Conda searches for configuration in this order (highest priority first):
1. **Command line flags** (`conda install -c conda-forge`)
2. **Local directory** (`./.condarc`) ← **This is what we use**
3. **User home** (`~/.condarc`)
4. **System** (`/opt/conda/.condarc`)

### What's in the Local `.condarc`
```yaml
channels:
  - conda-forge  # Primary channel for reliability
  - defaults     # Fallback for any missing packages

channel_priority: strict  # Prevents mixing channels
show_channel_urls: true  # Shows where packages come from
```

### Environment Isolation
- The `otter-latest` environment contains only CS187 packages
- Removing it is simple: `conda env remove -n otter-latest`
- No impact on your other projects or environments

## Why This Approach?

### Compared to Installing New Conda
- ✅ **Gentler**: Uses existing setup instead of replacing it
- ✅ **Faster**: No need to download/install another conda distribution
- ✅ **Cleaner**: No conflicts between multiple conda installations

### Compared to Global Configuration Changes
- ✅ **Safer**: Only affects CS187 project, not your entire system
- ✅ **Reversible**: Remove the project and all changes are gone
- ✅ **Isolated**: Other projects continue using your preferred settings

### Compared to Manual Package Management
- ✅ **Automatic**: Just `cd` to the directory and conda uses correct settings
- ✅ **Reliable**: Eliminates channel conflicts and version mismatches
- ✅ **Maintainable**: One configuration file for the entire class

## Getting Help

If you encounter issues:

1. **Check the diagnostic scripts** in the `scripts/` directory
2. **Verify you're in the right directory** and environment
3. **Ask for help** with the output from `bash scripts/check-conda-channels.sh`

The local `.condarc` approach makes conda "just work" for CS187 while respecting your existing setup! 🎉 