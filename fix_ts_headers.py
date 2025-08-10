#!/usr/bin/env python3
"""
Script to remove header comments from TypeScript files that were added by validation
"""

import os
import re

def remove_headers_from_file(file_path):
    """Remove header comments from a file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remove header comments (lines starting with #)
        lines = content.split('\n')
        new_lines = []
        header_removed = False
        
        for line in lines:
            if not header_removed and line.strip().startswith('#'):
                continue
            elif not header_removed and line.strip() == '':
                continue
            else:
                header_removed = True
                new_lines.append(line)
        
        new_content = '\n'.join(new_lines)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"Fixed: {file_path}")
        return True
    except Exception as e:
        print(f"Error fixing {file_path}: {e}")
        return False

def fix_typescript_files():
    """Fix all TypeScript files in the React frontend"""
    ui_dir = "ransomeye_master_core_engine/ui/react_frontend"
    
    # Files to fix
    files_to_fix = [
        "src/App.tsx",
        "src/api/axiosClient.ts",
        "src/components/AlertCard.tsx",
        "src/components/ChartBox.tsx",
        "src/components/Footer.tsx",
        "src/components/Header.tsx",
        "src/components/SummaryCard.tsx",
        "src/components/Timeline.tsx",
        "src/pages/Alerts.tsx",
        "src/pages/Dashboard.tsx",
        "src/pages/Forensics.tsx",
        "src/pages/KillChain.tsx",
        "src/pages/LLMSummaries.tsx",
        "src/pages/ResponseMatrix.tsx",
        "tsconfig.json"
    ]
    
    fixed_count = 0
    for file_path in files_to_fix:
        full_path = os.path.join(ui_dir, file_path)
        if os.path.exists(full_path):
            if remove_headers_from_file(full_path):
                fixed_count += 1
    
    print(f"\nFixed {fixed_count} files")

if __name__ == "__main__":
    fix_typescript_files() 