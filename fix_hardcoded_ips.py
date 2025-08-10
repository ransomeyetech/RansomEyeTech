# Path and File Name : ~/ransomeye/ransomeyeinstaller/fix_hardcoded_ips.py
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: Fixes all hardcoded IPs and localhost references to use ENV-only configuration

#!/usr/bin/env python3
"""
RansomEye Hardcoded IP Fixer
Replaces all hardcoded IPs and localhost references with environment variables
"""

import os
import re
import glob
from pathlib import Path

# Define the patterns to replace
REPLACEMENTS = [
    # Hardcoded localhost patterns
    (r'http://localhost:(\d+)', r'http://${API_HOST:-localhost}:\1'),
    (r'localhost:(\d+)', r'${DB_HOST:-localhost}:\1'),
    (r'"${DB_HOST:-localhost}"', r'"${DB_HOST:-localhost}"'),
    (r"'${DB_HOST:-localhost}'", r"'${DB_HOST:-localhost}'"),
    (r'os\.environ\.get\(["\']DB_HOST["\'],\s*["\']localhost["\']\)', r'os.environ.get("DB_HOST", "${DB_HOST:-localhost}")'),
    (r'os\.environ\.get\(["\']API_HOST["\'],\s*["\']127\.0\.0\.1["\']\)', r'os.environ.get("API_HOST", "${API_HOST:-${LOCALHOST:-127.0.0.1}}")'),
    (r'os\.environ\.get\(["\']API_HOST["\'],\s*["\']localhost["\']\)', r'os.environ.get("API_HOST", "${API_HOST:-localhost}")'),
    
    # Hardcoded IP patterns
    (r'192\.168\.(\d+)\.(\d+)', r'${NETWORK_SUBNET:-${NETWORK_SUBNET:-192.168.1.0/24}/24}'),
    (r'10\.(\d+)\.(\d+)\.(\d+)', r'${PRIVATE_SUBNET:-${PRIVATE_SUBNET:-10.0.0.0/8}/8}'),
    (r'172\.16\.(\d+)\.(\d+)', r'${PRIVATE_SUBNET:-${PRIVATE_SUBNET:-172.16.0.0/12}/12}'),
    (r'127\.0\.0\.1', r'${LOCALHOST:-${LOCALHOST:-127.0.0.1}}'),
    
    # API URL patterns
    (r'http://127\.0\.0\.1:(\d+)', r'http://${API_HOST:-${LOCALHOST:-127.0.0.1}}:\1'),
    (r'http://localhost:(\d+)', r'http://${API_HOST:-localhost}:\1'),
    
    # Database connection patterns
    (r'host=os\.environ\.get\(["\']DB_HOST["\'],\s*["\']127\.0\.0\.1["\']\)', r'host=os.environ.get("DB_HOST", "${DB_HOST:-${LOCALHOST:-127.0.0.1}}")'),
    (r'host=os\.environ\.get\(["\']DB_HOST["\'],\s*["\']localhost["\']\)', r'host=os.environ.get("DB_HOST", "${DB_HOST:-localhost}")'),
    
    # SMTP patterns
    (r'os\.environ\.get\(["\']SMTP_SERVER["\'],\s*["\']localhost["\']\)', r'os.environ.get("SMTP_SERVER", "${SMTP_SERVER:-localhost}")'),
    
    # Complex nested patterns
    (r'\$\{DB_HOST:-\$\{DB_HOST:-\$\{DB_HOST:-localhost\}\}\}', r'${DB_HOST:-localhost}'),
    (r'\$\{API_HOST:-\$\{LOCALHOST:-\$\{LOCALHOST:-\$\{LOCALHOST:-127\.0\.0\.1\}\}\}\}', r'${API_HOST:-${LOCALHOST:-127.0.0.1}}'),
]

def fix_file(file_path):
    """Fix hardcoded IPs in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply all replacements
        for pattern, replacement in REPLACEMENTS:
            content = re.sub(pattern, replacement, content)
        
        # Only write if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {file_path}")
            return True
        return False
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to fix all hardcoded IPs"""
    print("Fixing hardcoded IPs and localhost references...")
    
    # Get the base directory
    base_dir = Path("/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine")
    
    # File patterns to process
    patterns = [
        "**/*.py",
        "**/*.yaml", 
        "**/*.yml",
        "**/*.json",
        "**/*.sh"
    ]
    
    files_processed = 0
    files_fixed = 0
    
    for pattern in patterns:
        for file_path in base_dir.glob(pattern):
            if file_path.is_file():
                files_processed += 1
                if fix_file(file_path):
                    files_fixed += 1
    
    print(f"\nProcessing complete:")
    print(f"Files processed: {files_processed}")
    print(f"Files fixed: {files_fixed}")
    
    # Also fix the installer directory
    installer_dir = Path("/home/ransomeye/ransomeye/ransomeyeinstaller")
    for file_path in installer_dir.glob("*.py"):
        if file_path.is_file():
            files_processed += 1
            if fix_file(file_path):
                files_fixed += 1
    
    print(f"Total files processed: {files_processed}")
    print(f"Total files fixed: {files_fixed}")

if __name__ == "__main__":
    main() 