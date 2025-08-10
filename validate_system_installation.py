# Path and File Name : ~/ransomeye/ransomeyeinstaller/validate_system_installation.py
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: System-wide validation for RansomEye installation

#!/usr/bin/env python3

import os
import sys
import asyncio
import subprocess
import json
from pathlib import Path
from datetime import datetime

class SystemInstallationValidator:
    """Validate system-wide RansomEye installation"""
    
    def __init__(self):
        self.results = {
            'timestamp': datetime.now().isoformat(),
            'system_checks': {},
            'dependency_checks': {},
            'database_checks': {},
            'service_checks': {},
            'overall_score': 0
        }
    
    def check_system_dependencies(self) -> dict:
        """Check system dependencies"""
        print("🔧 Checking system dependencies...")
        
        checks = {}
        
        # Check Python
        try:
            result = subprocess.run(['python3', '--version'], capture_output=True, text=True)
            checks['python3'] = {
                'installed': result.returncode == 0,
                'version': result.stdout.strip() if result.returncode == 0 else 'Not found'
            }
        except Exception as e:
            checks['python3'] = {'installed': False, 'error': str(e)}
        
        # Check PostgreSQL
        try:
            result = subprocess.run(['psql', '--version'], capture_output=True, text=True)
            checks['postgresql'] = {
                'installed': result.returncode == 0,
                'version': result.stdout.strip() if result.returncode == 0 else 'Not found'
            }
        except Exception as e:
            checks['postgresql'] = {'installed': False, 'error': str(e)}
        
        # Check pip
        try:
            result = subprocess.run(['pip3', '--version'], capture_output=True, text=True)
            checks['pip3'] = {
                'installed': result.returncode == 0,
                'version': result.stdout.strip() if result.returncode == 0 else 'Not found'
            }
        except Exception as e:
            checks['pip3'] = {'installed': False, 'error': str(e)}
        
        # Check system directories
        directories = [
            '/opt/ransomeye',
            '/var/log/ransomeye',
            '/etc/ransomeye'
        ]
        
        for directory in directories:
            checks[f'directory_{directory.replace("/", "_")}'] = {
                'exists': os.path.exists(directory),
                'writable': os.access(directory, os.W_OK) if os.path.exists(directory) else False
            }
        
        self.results['system_checks'] = checks
        return checks
    
    def check_python_dependencies(self) -> dict:
        """Check Python dependencies"""
        print("🐍 Checking Python dependencies...")
        
        dependencies = [
            'asyncpg', 'fastapi', 'uvicorn', 'pydantic',
            'numpy', 'pandas', 'scikit-learn', 'shap',
            'requests', 'aiofiles', 'click', 'reportlab',
            'jinja2', 'structlog', 'prometheus_client',
            'python_dotenv', 'pyyaml', 'psutil'
        ]
        
        checks = {}
        
        for dep in dependencies:
            try:
                result = subprocess.run([
                    'python3', '-c', f'import {dep}; print("{dep} version:", {dep}.__version__)'
                ], capture_output=True, text=True)
                checks[dep] = {
                    'installed': result.returncode == 0,
                    'version': result.stdout.strip() if result.returncode == 0 else 'Not found'
                }
            except Exception as e:
                checks[dep] = {'installed': False, 'error': str(e)}
        
        self.results['dependency_checks'] = checks
        return checks
    
    async def check_database_connection(self) -> dict:
        """Check database connectivity"""
        print("🗄️ Checking database connectivity...")
        
        try:
            # Test database connection
            result = subprocess.run([
                'python3', '-c', '''
import asyncio
import asyncpg
import os

async def test_db():
    try:
        conn = await asyncpg.connect(
            host=os.getenv("DB_HOST", "${DB_HOST:-localhost}"),
            port=int(os.getenv("DB_PORT", "5432")),
            database=os.getenv("DB_NAME", "ransomeye"),
            user=os.getenv("DB_USER", "gagan"),
            password=os.getenv("DB_PASS", "gagan")
        )
        result = await conn.fetchval("SELECT version()")
        await conn.close()
        print(f"Database connected: {result}")
        return True
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False

asyncio.run(test_db())
'''
            ], capture_output=True, text=True)
            
            checks = {
                'connected': 'Database connected:' in result.stdout,
                'version': result.stdout.strip() if 'Database connected:' in result.stdout else 'Connection failed',
                'error': result.stderr if result.returncode != 0 else None
            }
            
        except Exception as e:
            checks = {'connected': False, 'error': str(e)}
        
        self.results['database_checks'] = checks
        return checks
    
    def check_systemd_services(self) -> dict:
        """Check systemd services"""
        print("⚙️ Checking systemd services...")
        
        services = [
            'postgresql',
            'ransomeye-db-core',
            'ransomeye-ai-core',
            'ransomeye-llm-core'
        ]
        
        checks = {}
        
        for service in services:
            try:
                result = subprocess.run(['systemctl', 'is-active', service], capture_output=True, text=True)
                checks[service] = {
                    'active': result.stdout.strip() == 'active',
                    'status': result.stdout.strip(),
                    'enabled': subprocess.run(['systemctl', 'is-enabled', service], capture_output=True, text=True).stdout.strip() == 'enabled'
                }
            except Exception as e:
                checks[service] = {'active': False, 'error': str(e)}
        
        self.results['service_checks'] = checks
        return checks
    
    def calculate_overall_score(self) -> float:
        """Calculate overall installation score"""
        total_checks = 0
        passed_checks = 0
        
        # System checks
        for check_name, check_result in self.results['system_checks'].items():
            total_checks += 1
            if check_result.get('installed', False) or check_result.get('exists', False):
                passed_checks += 1
        
        # Dependency checks
        for check_name, check_result in self.results['dependency_checks'].items():
            total_checks += 1
            if check_result.get('installed', False):
                passed_checks += 1
        
        # Database checks
        for check_name, check_result in self.results['database_checks'].items():
            total_checks += 1
            if isinstance(check_result, dict) and check_result.get('connected', False):
                passed_checks += 1
        
        # Service checks
        for check_name, check_result in self.results['service_checks'].items():
            total_checks += 1
            if isinstance(check_result, dict) and check_result.get('active', False):
                passed_checks += 1
        
        score = (passed_checks / total_checks * 100) if total_checks > 0 else 0
        self.results['overall_score'] = score
        return score
    
    def save_results(self):
        """Save validation results"""
        output_dir = Path("/var/log/ransomeye")
        output_dir.mkdir(exist_ok=True)
        
        output_file = output_dir / f"system_validation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(output_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        print(f"📝 Results saved to: {output_file}")
    
    async def run_all_checks(self) -> dict:
        """Run all validation checks"""
        print("="*60)
        print("RANSOMEYE SYSTEM INSTALLATION VALIDATION")
        print("="*60)
        
        # Run checks
        self.check_system_dependencies()
        self.check_python_dependencies()
        await self.check_database_connection()
        self.check_systemd_services()
        
        # Calculate score
        score = self.calculate_overall_score()
        
        # Save results
        self.save_results()
        
        # Print summary
        print(f"\n📊 VALIDATION RESULTS")
        print(f"   Overall Score: {score:.1f}/100")
        
        if score >= 90:
            print("   Status: ✅ EXCELLENT - System ready for production")
        elif score >= 75:
            print("   Status: ⚠️ GOOD - Minor issues detected")
        elif score >= 50:
            print("   Status: 🔶 FAIR - Some issues need attention")
        else:
            print("   Status: ❌ POOR - Major issues detected")
        
        return self.results

async def main():
    """Main validation function"""
    validator = SystemInstallationValidator()
    results = await validator.run_all_checks()
    
    if results['overall_score'] >= 75:
        return True
    else:
        return False

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1) 