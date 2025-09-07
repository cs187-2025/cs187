#!/usr/bin/env python3
"""
Convert Make configuration to bash configuration.

This script reads a Make configuration file and outputs bash-compatible
variable assignments. It's used by the build system to generate config.env
from the master config.mk file.

Usage: mk2bash.py config.mk > config.env
"""

import sys
import re

def convert_make_to_bash(make_file):
    """Convert Make variable assignments to bash format."""
    
    # Read the Make file
    try:
        with open(make_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Could not find {make_file}", file=sys.stderr)
        sys.exit(1)
    
    print("# Generated from config.mk - DO NOT EDIT DIRECTLY")
    print("# Edit config.mk instead and run 'make .github/workflows/config.env'")
    print()
    
    # Process each line
    for line in content.split('\n'):
        # Skip comments and empty lines
        if line.strip().startswith('#') or not line.strip():
            continue
            
        # Look for variable assignments (VAR := value)
        match = re.match(r'^([A-Z_]+)\s*:=\s*(.*)$', line.strip())
        if match:
            var_name = match.group(1)
            var_value = match.group(2)
            
            # Handle Make variable expansion $(VAR) -> ${VAR}
            var_value = re.sub(r'\$\(([^)]+)\)', r'${\1}', var_value)
            
            print(f"{var_name}={var_value}")

def main():
    if len(sys.argv) != 2:
        print("Usage: mk2bash.py <make_config_file>", file=sys.stderr)
        sys.exit(1)
    
    make_file = sys.argv[1]
    convert_make_to_bash(make_file)

if __name__ == "__main__":
    main() 