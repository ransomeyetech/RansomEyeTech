# Path and File Name : ~/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/uninstall.sh
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: uninstall module

#!/bin/bash

# Path and File Name : /home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/uninstall.sh
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: Uninstall script for RansomEye Master Core Engine

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script information
SCRIPT_NAME="RansomEye Master Core Engine Uninstaller"
VERSION="2025.1.0"
AUTHOR="Gagan@RansomEye.tech"
WEBSITE="https://www.ransomeye.tech"

# Installation paths
INSTALL_DIR="/opt/ransomeye/master_core_engine"
SERVICE_USER="gagan"
SERVICE_GROUP="gagan"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_status "Running as root - proceeding with uninstallation"
    else
        print_error "This script must be run as root for systemd service removal"
        exit 1
    fi
}

# Function to stop and disable services
stop_services() {
    print_status "Stopping and disabling services..."
    
    # List of all services to stop and disable
    SERVICES=(
        "ransomeye-engine.service"
        "ransomeye-alerts.service"
        "ransomeye-alert-engine.service"
        "ransomeye-ai-models.service"
        "ransomeye-ai-core.service"
        "ransomeye-decryptor.service"
        "ransomeye-killchain.service"
        "ransomeye-correlation.service"
        "ransomeye-llm-summary.service"
        "ransomeye-forensic.service"
        "ransomeye-response.service"
        "ransomeye-assistant.service"
        "ransomeye-deception.service"
        "ransomeye-threatintel.service"
        "ransomeye-net-scan.service"
        "ransomeye-hnmp.service"
        "ransomeye-api.service"
        "ransomeye-orchestrator-loop.service"
    )
    
    # List of all timers to stop and disable
    TIMERS=(
        "killchain-rebuilder.timer"
        "correlation-runner.timer"
        "forensic-dump-trigger.timer"
        "model-drift-check.timer"
        "ransomeye-orchestrator-loop.timer"
        "alert-policy-escalation.timer"
    )
    
    # Stop and disable all services
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            systemctl stop "$service"
            print_success "Stopped $service"
        fi
        
        if systemctl is-enabled --quiet "$service"; then
            systemctl disable "$service"
            print_success "Disabled $service"
        fi
    done
    
    # Stop and disable all timers
    for timer in "${TIMERS[@]}"; do
        if systemctl is-active --quiet "$timer"; then
            systemctl stop "$timer"
            print_success "Stopped $timer"
        fi
        
        if systemctl is-enabled --quiet "$timer"; then
            systemctl disable "$timer"
            print_success "Disabled $timer"
        fi
    done
}

# Function to remove systemd service files
remove_systemd_files() {
    print_status "Removing systemd service files..."
    
    # List of all service files to remove
    SERVICE_FILES=(
        "/etc/systemd/system/ransomeye-engine.service"
        "/etc/systemd/system/ransomeye-alerts.service"
        "/etc/systemd/system/ransomeye-ai-models.service"
        "/etc/systemd/system/ransomeye-decryptor.service"
        "/etc/systemd/system/ransomeye-killchain.service"
        "/etc/systemd/system/ransomeye-correlation.service"
        "/etc/systemd/system/ransomeye-llm-summary.service"
        "/etc/systemd/system/ransomeye-forensic.service"
        "/etc/systemd/system/ransomeye-response.service"
        "/etc/systemd/system/ransomeye-assistant.service"
        "/etc/systemd/system/ransomeye-deception.service"
        "/etc/systemd/system/ransomeye-threatintel.service"
        "/etc/systemd/system/ransomeye-net-scan.service"
        "/etc/systemd/system/ransomeye-hnmp.service"
    )
    
    # List of all timer files to remove
    TIMER_FILES=(
        "/etc/systemd/system/killchain-rebuilder.timer"
        "/etc/systemd/system/correlation-runner.timer"
        "/etc/systemd/system/forensic-dump-trigger.timer"
    )
    
    # Remove all service files
    for file in "${SERVICE_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            print_success "Removed $file"
        else
            print_warning "Service file $file not found"
        fi
    done
    
    # Remove all timer files
    for file in "${TIMER_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            print_success "Removed $file"
        else
            print_warning "Timer file $file not found"
        fi
    done
    
    # Reload systemd
    systemctl daemon-reload
    print_success "systemd daemon reloaded"
}

# Function to remove installation directory
remove_install_dir() {
    print_status "Removing installation directory..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        print_success "Removed installation directory: $INSTALL_DIR"
    else
        print_warning "Installation directory not found: $INSTALL_DIR"
    fi
}

# Function to remove log directories
remove_log_dirs() {
    print_status "Removing log directories..."
    
    if [[ -d "/var/log/ransomeye" ]]; then
        rm -rf "/var/log/ransomeye"
        print_success "Removed log directory: /var/log/ransomeye"
    else
        print_warning "Log directory not found: /var/log/ransomeye"
    fi
}

# Function to remove service user (optional)
remove_service_user() {
    print_status "Checking service user..."
    
    read -p "Do you want to remove the service user '$SERVICE_USER'? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if id "$SERVICE_USER" &>/dev/null; then
            userdel -r "$SERVICE_USER" 2>/dev/null || print_warning "Could not remove user $SERVICE_USER (may be in use)"
        else
            print_warning "User $SERVICE_USER not found"
        fi
        
        if getent group "$SERVICE_GROUP" &>/dev/null; then
            groupdel "$SERVICE_GROUP" 2>/dev/null || print_warning "Could not remove group $SERVICE_GROUP (may be in use)"
        else
            print_warning "Group $SERVICE_GROUP not found"
        fi
    else
        print_status "Keeping service user $SERVICE_USER"
    fi
}

# Function to clean up Python packages (optional)
cleanup_python_packages() {
    print_status "Checking Python packages..."
    
    read -p "Do you want to remove RansomEye Python packages? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_warning "This will remove all RansomEye-related Python packages"
        print_warning "This may affect other applications using the same packages"
        
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # List of packages to potentially remove
            PACKAGES=(
                "asyncpg" "fastapi" "uvicorn" "pydantic"
                "llama-cpp-python" "sentence-transformers"
                "scapy" "python-nmap" "volatility3"
                "reportlab" "weasyprint"
            )
            
            for package in "${PACKAGES[@]}"; do
                if python3 -m pip show "$package" &>/dev/null; then
                    print_status "Removing $package..."
                    python3 -m pip uninstall -y "$package" || print_warning "Could not remove $package"
                fi
            done
            
            print_success "Python package cleanup completed"
        else
            print_status "Skipping Python package cleanup"
        fi
    else
        print_status "Keeping Python packages"
    fi
}

# Function to backup data (optional)
backup_data() {
    print_status "Checking for data backup..."
    
    read -p "Do you want to backup RansomEye data before uninstalling? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP_DIR="/tmp/ransomeye_backup_$(date +%Y%m%d_%H%M%S)"
        
        mkdir -p "$BACKUP_DIR"
        
        # Backup installation directory
        if [[ -d "$INSTALL_DIR" ]]; then
            cp -r "$INSTALL_DIR" "$BACKUP_DIR/"
            print_success "Backed up installation directory to $BACKUP_DIR"
        fi
        
        # Backup log directory
        if [[ -d "/var/log/ransomeye" ]]; then
            cp -r "/var/log/ransomeye" "$BACKUP_DIR/"
            print_success "Backed up log directory to $BACKUP_DIR"
        fi
        
        print_success "Backup completed: $BACKUP_DIR"
    else
        print_status "Skipping data backup"
    fi
}

# Function to verify uninstallation
verify_uninstallation() {
    print_status "Verifying uninstallation..."
    
    # List of all services to check
    SERVICES=(
        "ransomeye-engine.service"
        "ransomeye-alerts.service"
        "ransomeye-ai-models.service"
        "ransomeye-decryptor.service"
        "ransomeye-killchain.service"
        "ransomeye-correlation.service"
        "ransomeye-llm-summary.service"
        "ransomeye-forensic.service"
        "ransomeye-response.service"
        "ransomeye-assistant.service"
        "ransomeye-deception.service"
        "ransomeye-threatintel.service"
        "ransomeye-net-scan.service"
        "ransomeye-hnmp.service"
    )
    
    # Check if services are stopped
    for service in "${SERVICES[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            print_success "$service is stopped"
        else
            print_error "$service is still running"
        fi
    done
    
    # Check if installation directory is removed
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_success "Installation directory removed"
    else
        print_error "Installation directory still exists"
    fi
    
    # Check if log directory is removed
    if [[ ! -d "/var/log/ransomeye" ]]; then
        print_success "Log directory removed"
    else
        print_error "Log directory still exists"
    fi
    
    # Check if systemd files are removed
    SYSTEMD_FILES=(
        "/etc/systemd/system/ransomeye-engine.service"
        "/etc/systemd/system/ransomeye-alerts.service"
        "/etc/systemd/system/ransomeye-ai-models.service"
        "/etc/systemd/system/ransomeye-decryptor.service"
        "/etc/systemd/system/ransomeye-killchain.service"
        "/etc/systemd/system/ransomeye-correlation.service"
        "/etc/systemd/system/ransomeye-llm-summary.service"
        "/etc/systemd/system/ransomeye-forensic.service"
        "/etc/systemd/system/ransomeye-response.service"
        "/etc/systemd/system/ransomeye-assistant.service"
        "/etc/systemd/system/ransomeye-deception.service"
        "/etc/systemd/system/ransomeye-threatintel.service"
        "/etc/systemd/system/ransomeye-net-scan.service"
        "/etc/systemd/system/ransomeye-hnmp.service"
        "/etc/systemd/system/killchain-rebuilder.timer"
        "/etc/systemd/system/correlation-runner.timer"
        "/etc/systemd/system/forensic-dump-trigger.timer"
    )
    
    for file in "${SYSTEMD_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_success "Systemd file removed: $file"
        else
            print_error "Systemd file still exists: $file"
        fi
    done
}

# Function to display uninstallation summary
display_summary() {
    echo
    echo "=========================================="
    echo "RansomEye Master Core Engine Uninstallation"
    echo "=========================================="
    echo
    echo "Uninstallation completed!"
    echo
    echo "Removed Components:"
    echo "  - Installation directory: $INSTALL_DIR"
    echo "  - Log directory: /var/log/ransomeye"
    echo "  - systemd services and timers"
    echo "  - Service files"
    echo
    echo "If you backed up data, check: /tmp/ransomeye_backup_*"
    echo
    echo "Support:"
    echo "  - Email: $AUTHOR"
    echo "  - Website: $WEBSITE"
    echo
    echo "=========================================="
}

# Main uninstallation function
main() {
    echo "=========================================="
    echo "$SCRIPT_NAME v$VERSION"
    echo "=========================================="
    echo
    
    check_root
    
    echo "This will completely remove the RansomEye Master Core Engine."
    echo "All data, logs, and configurations will be deleted."
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_data
        stop_services
        remove_systemd_files
        remove_install_dir
        remove_log_dirs
        remove_service_user
        cleanup_python_packages
        verify_uninstallation
        display_summary
        
        print_success "Uninstallation completed successfully!"
    else
        print_status "Uninstallation cancelled"
        exit 0
    fi
}

# Run main function
main "$@" 