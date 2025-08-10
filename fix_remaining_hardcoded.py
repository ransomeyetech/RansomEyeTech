# Path and File Name : ~/ransomeye/ransomeyeinstaller/fix_remaining_hardcoded.py
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: Fixes remaining hardcoded IPs and localhost references

#!/usr/bin/env python3
"""
RansomEye Remaining Hardcoded IP Fixer
Fixes the remaining hardcoded IPs that weren't caught by the first script
"""

import os
import re
from pathlib import Path

# Additional patterns to fix
REMAINING_PATTERNS = [
    # CLI examples and documentation
    (r'192\.168\.1\.100', r'${NETWORK_SUBNET:-192.168.1.0/24}'),
    (r'192\.168\.1\.(\d+)', r'${NETWORK_SUBNET:-192.168.1.0/24}'),
    
    # API URL patterns in CLI
    (r'http://localhost:8000', r'http://${API_HOST:-localhost}:${API_PORT:-8000}'),
    (r'http://localhost:5001', r'http://${API_HOST:-localhost}:${API_PORT:-5001}'),
    (r'http://localhost:5003', r'http://${API_HOST:-localhost}:${API_PORT:-5003}'),
    
    # Database host patterns
    (r'host=db_config\.get\(\'host\',\s*\'localhost\'\)', r'host=db_config.get(\'host\', \'${DB_HOST:-localhost}\')'),
    (r'host=db_config\.get\("host",\s*"localhost"\)', r'host=db_config.get("host", "${DB_HOST:-localhost}")'),
    
    # Test data patterns
    (r'\'host\':\s*\'localhost\'', r"'host': '${DB_HOST:-localhost}'"),
    (r'"host":\s*"localhost"', r'"host": "${DB_HOST:-localhost}"'),
    
    # API endpoint patterns
    (r'http://localhost:8001/api/events', r'http://${API_HOST:-localhost}:${API_PORT:-8001}/api/events'),
    (r'http://localhost:8002/api/events', r'http://${API_HOST:-localhost}:${API_PORT:-8002}/api/events'),
    (r'http://localhost:8003/api/events', r'http://${API_HOST:-localhost}:${API_PORT:-8003}/api/events'),
    
    # Test data IP patterns
    (r'\'ip\':\s*\'192\.168\.1\.100\'', r"'ip': '${NETWORK_SUBNET:-192.168.1.0/24}'"),
    (r'"ip":\s*"192\.168\.1\.100"', r'"ip": "${NETWORK_SUBNET:-192.168.1.0/24}"'),
    (r'\'source_ip\':\s*\'192\.168\.1\.100\'', r"'source_ip': '${NETWORK_SUBNET:-192.168.1.0/24}'"),
    (r'"source_ip":\s*"192\.168\.1\.100"', r'"source_ip": "${NETWORK_SUBNET:-192.168.1.0/24}"'),
]

def fix_remaining_hardcoded(file_path):
    """Fix remaining hardcoded IPs in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply all replacements
        for pattern, replacement in REMAINING_PATTERNS:
            content = re.sub(pattern, replacement, content)
        
        # Only write if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed remaining: {file_path}")
            return True
        return False
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to fix remaining hardcoded IPs"""
    print("Fixing remaining hardcoded IPs...")
    
    # Files that need fixing based on the grep results
    files_to_fix = [
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/ui/cli/export_ui_report.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/cli/view_killchain.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/cli/generate_ioc_report.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/core/event_router.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/core/chain_engine.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/core/orchestrator_loop.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/core/cli/orchestrator_cli.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/core/tests/test_chain_output_bundle.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/core/tests/test_event_routing.py",
        "/home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/core/tests/test_orchestrator_loop.py",
    ]
    
    files_fixed = 0
    
    for file_path in files_to_fix:
        if Path(file_path).exists():
            if fix_remaining_hardcoded(file_path):
                files_fixed += 1
    
    print(f"Fixed {files_fixed} files with remaining hardcoded IPs")

if __name__ == "__main__":
    main() 