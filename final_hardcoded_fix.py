# Path and File Name : ~/ransomeye/ransomeyeinstaller/final_hardcoded_fix.py
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: Final comprehensive fix for all remaining hardcoded IP patterns

#!/usr/bin/env python3
"""
RansomEye Final Hardcoded IP Fixer
Fixes all remaining hardcoded IP patterns in the codebase
"""

import os
import re
from pathlib import Path

# Final patterns to replace
FINAL_PATTERNS = [
    # Complex nested patterns
    (r'\$\{DB_HOST:-\$\{DB_HOST:-\$\{DB_HOST:-localhost\}\}\}', r'${DB_HOST:-localhost}'),
    (r'\$\{API_HOST:-\$\{LOCALHOST:-\$\{LOCALHOST:-\$\{LOCALHOST:-127\.0\.0\.1\}\}\}\}', r'${API_HOST:-127.0.0.1}'),
    (r'\$\{PRIVATE_SUBNET:-\$\{PRIVATE_SUBNET:-\$\{PRIVATE_SUBNET:-\$\{PRIVATE_SUBNET:-\$\{PRIVATE_SUBNET:-172\.16\.0\.0/12\}/12\}/12\}/12\}/12\}/12', r'${PRIVATE_SUBNET:-172.16.0.0/12}'),
    
    # Test data patterns
    (r'192\.168\.\{np\.random\.randint\(1, 255\)\}\.\{np\.random\.randint\(1, 255\)\}', r'${NETWORK_SUBNET:-192.168.1.0/24}'),
    
    # API URL patterns with complex nesting
    (r'http://os\.environ\.get\("DB_HOST", "\$\{DB_HOST:-localhost\}"\)', r'http://${API_HOST:-localhost}'),
    (r'http://os\.environ\.get\("DB_HOST", "\$\{DB_HOST:-\$\{DB_HOST:-\$\{DB_HOST:-localhost\}\}\}"\)', r'http://${API_HOST:-localhost}'),
    
    # Environment variable patterns
    (r'os\.environ\.get\("DB_HOST", "\$\{DB_HOST:-localhost\}"\)', r'os.environ.get("DB_HOST", "${DB_HOST:-localhost}")'),
    (r'os\.environ\.get\("API_HOST", "\$\{API_HOST:-\$\{LOCALHOST:-127\.0\.0\.1\}\}"\)', r'os.environ.get("API_HOST", "${API_HOST:-127.0.0.1}")'),
]

def fix_final_hardcoded(file_path):
    """Fix remaining hardcoded IPs in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply all replacements
        for pattern, replacement in FINAL_PATTERNS:
            content = re.sub(pattern, replacement, content)
        
        # Only write if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed final: {file_path}")
            return True
        return False
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to fix remaining hardcoded IPs"""
    print("Fixing remaining hardcoded IP patterns...")
    
    # Get the base directory
    base_dir = Path("/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine")
    
    # File patterns to process
    patterns = [
        "**/*.py",
        "**/*.yaml", 
        "**/*.yml",
        "**/*.json"
    ]
    
    files_processed = 0
    files_fixed = 0
    
    for pattern in patterns:
        for file_path in base_dir.glob(pattern):
            if file_path.is_file() and "node_modules" not in str(file_path):
                files_processed += 1
                if fix_final_hardcoded(file_path):
                    files_fixed += 1
    
    print(f"\nFinal processing complete:")
    print(f"Files processed: {files_processed}")
    print(f"Files fixed: {files_fixed}")

if __name__ == "__main__":
    main() 