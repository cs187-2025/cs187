# CS187 Course Materials - Environment Setup

This repository contains the environment setup files and configuration 
needed for CS187 (Introduction to Computational Linguistics).

**Note**: Throughout this document, we refer to the course-standard Conda environment name as `<environment-name>`. You can determine the actual environment name by looking in the `config.mk` file.

## Directory Structure

The CS187 course materials are organized as follows:

```
cs187/
├── setup.sh              # Environment setup script
├── Makefile              # Build system for assignments
├── requirements.txt      # Python package dependencies
├── .condarc             # Conda configuration
├── config.mk            # Course configuration (contains environment name)
├── README.md            # This file
└── assignments/         # Individual assignment repositories
    ├── lab1-1/         # Lab 1.1 materials
    ├── lab1-2/         # Lab 1.2 materials
    ├── project1/       # Project 1 materials
    └── ...             # Additional assignments
```

## Getting Started

### Step 1: Get Your CS187 Environment Setup

First, you'll need to get the CS187 environment setup files. **Do NOT clone the repository directly** - instead, use the GitHub Classroom link provided by your instructor to get your own copy.

Once you have access to your CS187 environment repository, clone it to your local machine:

```bash
git clone <your-github-classroom-repo-url>
cd <your-repo-name>
```

This repository contains the common setup files needed for all CS187 
assignments. You'll put the individual assignments in the `assignments` 
subdirectory.

### Step 2: Set Up Your Environment

Now set up your Python environment using the provided setup script:

```bash
# Run the automated setup script
bash setup.sh
```

This script will:
- Install conda (if needed)
- Create the `<environment-name>` environment
- Install all required packages
- Verify the installation

**Alternative setup options:**
```bash
# For faster setup without PDF generation capabilities
CS187_NO_PDFS=1 bash setup.sh
```

### Step 3: Get Individual Assignments

For each assignment you need to work on, you'll get access through GitHub Classroom. **Do NOT clone the public repositories directly** - instead, use the GitHub Classroom links provided by your instructor for each assignment.

Once you have access to an assignment repository, clone it to your local machine:

```bash
# Example: After getting Lab 1.1 through GitHub Classroom
git clone <your-lab1-1-repo-url> assignments/lab1-1

# Example: After getting Project 1 through GitHub Classroom  
git clone <your-project1-repo-url> assignments/project1
```

**Important**: Always use GitHub Classroom links; never clone from the
public `cs187-2025` organization repositories directly.

## Overview

We use a **local `.condarc` file** to ensure reliable package 
installation regardless of your existing conda setup. This approach 
preserves all your existing conda environments and configurations.

## How It Works

### Local Configuration Overrides
When you run conda commands from the CS187 Materials directory, conda 
automatically uses the local `.condarc` file which:
- Sets `conda-forge` as the primary channel
- Uses strict channel priority to prevent package conflicts
- Ensures PyTorch, Jupyter, and other packages install correctly

### Your Setup Remains Unchanged
- ✅ Your global conda configuration is preserved
- ✅ Your existing environments are untouched  
- ✅ Works with any conda distribution (Anaconda, Miniconda, Miniforge)
- ✅ No system-wide changes or installations required

## What's Included

- **`Makefile`**: Environment installation target
- **`setup.sh`**: Setup script
- **`requirements.txt`**: All Python package dependencies
- **`.condarc`**: Conda configuration for reliable package installation

## Daily Usage

```bash
# Always work from the CS187 directory
cd /path/to/CS187

# Activate the CS187 environment
conda activate <environment-name>

# Launch Jupyter (will use correct packages)
jupyter lab
```

### Working on Assignments

When working on a specific assignment:

```bash
# Navigate to the assignment directory
cd assignments/lab1-1

# Open the notebook
jupyter lab lab1-1.ipynb
```

**Important**: When you open a notebook, make sure to select the 
`<environment-name>` kernel from the kernel menu. This kernel has all the 
required packages pre-installed, so you won't need to run any package 
installation cells.

The environment setup ensures that all assignments use the same Python 
packages and configuration.
