# CS187 Course Configuration (Master)
# =============================================================================
# This is the master configuration file for CS187 course materials.
# All other configuration files are generated from this one.
#
# CONFIGURATION DESIGN PRINCIPLE:
# • config.mk (this file) = BUILD-TIME configuration (Make syntax)
# • config.env (generated) = RUNTIME configuration (bash syntax)
#
# This file is used during the build process (make targets, GitHub Actions).
# The generated config.env is used at runtime (scripts, autograder, deployment).
#
# IMPORTANT: This file uses Make syntax and is the single source of truth.
# The build system automatically generates bash-compatible versions as needed.
#
# UPDATE ANNUALLY: Change ACADEMIC_YEAR at the start of each academic year.
# =============================================================================

# Academic year (update this each year)
ACADEMIC_YEAR := 2025

# Course number (used for repository naming and organization)
COURSE_NUMBER := cs187

# Python Configuration
PYTHON_VERSION := 3.10

# GitHub Organizations
PRIVATE_ORG := nlp-course
PUBLIC_ORG := $(COURSE_NUMBER)-$(ACADEMIC_YEAR)

# Git Configuration
GIT_USER_NAME := shieber
GIT_USER_EMAIL := stuart.github@shieber.com
DEFAULT_BRANCH := master

# Conda Environment Configuration Name
CONDA_ENV_NAME := cs187-env

# GitHub Classroom Configuration
GITHUB_CLASSROOM_ID := 218409594
