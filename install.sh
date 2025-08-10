# Path and File Name : ~/ransomeye/ransomeyeinstaller/install.sh
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: install module

#!/bin/bash

# Path and File Name : /home/ransomeye/ransomeye/ransomeyeinstaller/ransomeye_master_core_engine/install.sh
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Details of functionality of this file: Main installation script for RansomEye Master Core Engine

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script information
SCRIPT_NAME="RansomEye Master Core Engine Installer"
VERSION="2025.1.0"
AUTHOR="Gagan@RansomEye.tech"
WEBSITE="https://www.ransomeye.tech"

# Installation paths
INSTALL_DIR="/opt/ransomeye/master_core_engine"
SERVICE_USER="gagan"
SERVICE_GROUP="gagan"
PYTHON_VERSION="3.9"

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
        print_status "Running as root - proceeding with installation"
    else
        print_error "This script must be run as root for systemd service installation"
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Python version
    if command -v python3 &> /dev/null; then
        PYTHON_VER=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
        if [[ $(echo "$PYTHON_VER >= $PYTHON_VERSION" | bc -l) -eq 1 ]]; then
            print_success "Python $PYTHON_VER found"
        else
            print_error "Python $PYTHON_VERSION or higher required, found $PYTHON_VER"
            exit 1
        fi
    else
        print_error "Python3 not found"
        exit 1
    fi
    
    # Check PostgreSQL
    if command -v psql &> /dev/null; then
        print_success "PostgreSQL found"
    else
        print_warning "PostgreSQL not found - will install PostgreSQL"
    fi
    
    # Check systemd
    if command -v systemctl &> /dev/null; then
        print_success "systemd found"
    else
        print_error "systemd required but not found"
        exit 1
    fi
    
    # Check required packages
    REQUIRED_PACKAGES=("curl" "wget" "git" "pandoc")
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if command -v $package &> /dev/null; then
            print_success "$package found"
        else
            print_warning "$package not found - will attempt to install"
        fi
    done
}

# Function to install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    
    # Update package lists
    apt update
    
    # Install system dependencies
    apt install -y \
        python3 \
        python3-pip \
        python3-dev \
        build-essential \
        libpq-dev \
        postgresql \
        postgresql-contrib \
        curl \
        wget \
        git \
        unzip \
        libffi-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
        liblcms2-dev \
        libwebp-dev \
        libtiff5-dev \
        libopenjp2-7-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libxcb1-dev
    
    print_success "System dependencies installed"
}

# Function to setup PostgreSQL
setup_postgresql() {
    print_status "Setting up PostgreSQL..."
    
    # Enable and start PostgreSQL
    systemctl enable postgresql
    systemctl start postgresql
    
    # Create database and user
    sudo -u postgres psql -c "CREATE DATABASE ransomeye;" || print_status "Database already exists"
    sudo -u postgres psql -c "CREATE USER gagan WITH PASSWORD 'gagan';" || print_status "User already exists"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ransomeye TO gagan;"
    sudo -u postgres psql -c "ALTER USER gagan CREATEDB;"
    sudo -u postgres psql -c "GRANT ALL ON SCHEMA public TO gagan;"
    
    print_success "PostgreSQL configured"
}

# Function to setup database schema
setup_database_schema() {
    print_status "Setting up database schema..."
    
    # Set environment variables
    export DB_HOST=localhost
    export DB_PORT=5432
    export DB_NAME=ransomeye
    export DB_USER=gagan
    export DB_PASS=gagan
    
    # Run schema initialization
    cd "$INSTALL_DIR/ransomeye_master_core_engine/db_core"
    if [[ -f "simple_init.py" ]]; then
        python3 simple_init.py
        print_success "Database schema initialized"
    else
        print_error "Schema initialization script not found"
        exit 1
    fi
    
    # Return to original directory
    cd - > /dev/null
}

# Function to create service user
create_service_user() {
    print_status "Creating service user..."
    
    if ! id "$SERVICE_USER" &>/dev/null; then
        useradd -r -s /bin/bash -d /home/$SERVICE_USER -m $SERVICE_USER
        print_success "Created user $SERVICE_USER"
    else
        print_status "User $SERVICE_USER already exists"
    fi
    
    # Create group if it doesn't exist
    if ! getent group "$SERVICE_GROUP" &>/dev/null; then
        groupadd $SERVICE_GROUP
        print_success "Created group $SERVICE_GROUP"
    fi
    
    # Add user to group
    usermod -a -G $SERVICE_GROUP $SERVICE_USER
}

# Function to install Python dependencies
install_python_deps() {
    print_status "Installing Python dependencies..."
    
    # Upgrade pip
    python3 -m pip install --upgrade pip
    
    # Install requirements
    if [[ -f "requirements.txt" ]]; then
        python3 -m pip install -r requirements.txt
        print_success "Python dependencies installed"
    else
        print_error "requirements.txt not found"
        exit 1
    fi
}

# Function to create installation directory
create_install_dir() {
    print_status "Creating installation directory..."
    
    mkdir -p $INSTALL_DIR
    cp -r . $INSTALL_DIR/
    
    # Set ownership
    chown -R $SERVICE_USER:$SERVICE_GROUP $INSTALL_DIR
    chmod -R 755 $INSTALL_DIR
    
    print_success "Installation directory created at $INSTALL_DIR"
}

# Function to create systemd services
create_systemd_services() {
    print_status "Creating systemd services..."
    
    # Copy all service files from systemd directory
    SYSTEMD_SOURCE_DIR="$INSTALL_DIR/systemd"
    
    if [[ -d "$SYSTEMD_SOURCE_DIR" ]]; then
        # Copy all .service files
        for service_file in "$SYSTEMD_SOURCE_DIR"/*.service; do
            if [[ -f "$service_file" ]]; then
                service_name=$(basename "$service_file")
                cp "$service_file" "/etc/systemd/system/$service_name"
                print_success "Installed $service_name"
            fi
        done
        
        # Copy all .timer files
        for timer_file in "$SYSTEMD_SOURCE_DIR"/*.timer; do
            if [[ -f "$timer_file" ]]; then
                timer_name=$(basename "$timer_file")
                cp "$timer_file" "/etc/systemd/system/$timer_name"
                print_success "Installed $timer_name"
            fi
        done
    else
        print_error "Systemd source directory not found: $SYSTEMD_SOURCE_DIR"
        exit 1
    fi
    
    # Reload systemd
    systemctl daemon-reload
    
    print_success "All systemd services and timers created"
}

# Function to create log directories
create_log_dirs() {
    print_status "Creating log directories..."
    
    mkdir -p /var/log/ransomeye
    chown -R $SERVICE_USER:$SERVICE_GROUP /var/log/ransomeye
    chmod -R 755 /var/log/ransomeye
    
    print_success "Log directories created"
}

# Function to create output directories
create_output_dirs() {
    print_status "Creating output directories..."
    
    mkdir -p $INSTALL_DIR/output/{alerts,killchain,summaries,forensic,response,deception,threat_intel}
    chown -R $SERVICE_USER:$SERVICE_GROUP $INSTALL_DIR/output
    chmod -R 755 $INSTALL_DIR/output
    
    print_success "Output directories created"
}

# Function to create AI models directory
create_ai_models_dir() {
    print_status "Creating AI models directory..."
    
    mkdir -p $INSTALL_DIR/ai_models
    chown -R $SERVICE_USER:$SERVICE_GROUP $INSTALL_DIR/ai_models
    chmod -R 755 $INSTALL_DIR/ai_models
    
    # Create placeholder for TinyLlama model
    touch $INSTALL_DIR/ai_models/TinyLlama-1.1B-Chat.gguf
    print_warning "Placeholder created for TinyLlama model - please download actual model"
    
    print_success "AI models directory created"
}

# Function to create dashboards directory
create_dashboards_dir() {
    print_status "Creating dashboards directory..."
    
    mkdir -p $INSTALL_DIR/dashboards
    chown -R $SERVICE_USER:$SERVICE_GROUP $INSTALL_DIR/dashboards
    chmod -R 755 $INSTALL_DIR/dashboards
    
    # Create placeholder dashboard files
    DASHBOARDS=(
        "killchain_timeline.json"
        "llm_summaries.json"
        "forensic_dumps.json"
        "deception_trigger_summary.json"
        "ioc_threat_feed_summary.json"
        "response_action_matrix.json"
        "ai_core_model_status.json"
        "db_core_health.json"
        "assistant_interaction_timeline.json"
        "hnmp_compliance_overlay.json"
        "ransomware_family_classification.json"
    )
    
    for dashboard in "${DASHBOARDS[@]}"; do
        echo '{"dashboard": {"title": "'$dashboard'", "version": "1.0"}}' > $INSTALL_DIR/dashboards/$dashboard
    done
    
    print_success "Dashboards directory created with placeholder files"
}

# Function to enable and start services
enable_services() {
    print_status "Enabling and starting services..."
    
    # List of all services to enable and start
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
    
    # List of all timers to enable and start
    TIMERS=(
        "killchain-rebuilder.timer"
        "correlation-runner.timer"
        "forensic-dump-trigger.timer"
        "model-drift-check.timer"
        "ransomeye-orchestrator-loop.timer"
        "alert-policy-escalation.timer"
    )
    
    # Enable and start all services
    for service in "${SERVICES[@]}"; do
        if systemctl enable "$service"; then
            print_success "Enabled $service"
        else
            print_error "Failed to enable $service"
        fi
        
        if systemctl start "$service"; then
            print_success "Started $service"
        else
            print_error "Failed to start $service"
        fi
    done
    
    # Enable and start all timers
    for timer in "${TIMERS[@]}"; do
        if systemctl enable "$timer"; then
            print_success "Enabled $timer"
        else
            print_error "Failed to enable $timer"
        fi
        
        if systemctl start "$timer"; then
            print_success "Started $timer"
        else
            print_error "Failed to start $timer"
        fi
    done
    
    print_success "All services and timers enabled and started"
}

# Function to run post-install validation
run_validation() {
    print_status "Running post-install validation..."
    
    # List of all services to check
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
    
    # List of all timers to check
    TIMERS=(
        "killchain-rebuilder.timer"
        "correlation-runner.timer"
        "forensic-dump-trigger.timer"
        "model-drift-check.timer"
        "ransomeye-orchestrator-loop.timer"
        "alert-policy-escalation.timer"
    )
    
    # Check if services are running
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            print_success "$service is running"
        else
            print_error "$service failed to start"
            systemctl status "$service"
        fi
    done
    
    # Check if timers are active
    for timer in "${TIMERS[@]}"; do
        if systemctl is-active --quiet "$timer"; then
            print_success "$timer is active"
        else
            print_warning "$timer is not active"
        fi
    done
    
    # Check installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        print_success "Installation directory exists"
    else
        print_error "Installation directory not found"
    fi
    
    # Check log directory
    if [[ -d "/var/log/ransomeye" ]]; then
        print_success "Log directory exists"
    else
        print_error "Log directory not found"
    fi
    
    # Check output directories
    OUTPUT_DIRS=(
        "$INSTALL_DIR/output/alerts"
        "$INSTALL_DIR/output/killchain"
        "$INSTALL_DIR/output/summaries"
        "$INSTALL_DIR/output/forensic"
        "$INSTALL_DIR/output/response"
        "$INSTALL_DIR/output/deception"
        "$INSTALL_DIR/output/threat_intel"
        "$INSTALL_DIR/output/correlation"
        "$INSTALL_DIR/output/assistant"
        "$INSTALL_DIR/output/net_scan"
        "$INSTALL_DIR/output/hnmp"
    )
    
    for dir in "${OUTPUT_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "Output directory exists: $dir"
        else
            print_error "Output directory not found: $dir"
        fi
    done
}

# Function to display installation summary
display_summary() {
    echo
    echo "=========================================="
    echo "RansomEye Master Core Engine Installation"
    echo "=========================================="
    echo
    echo "Installation completed successfully!"
    echo
    echo "Installation Directory: $INSTALL_DIR"
    echo "Service User: $SERVICE_USER"
    echo "Log Directory: /var/log/ransomeye"
    echo "Output Directory: $INSTALL_DIR/output"
    echo
    echo "Services:"
    echo "  - ransomeye-engine.service (Main Core Engine)"
    echo "  - ransomeye-alerts.service (Alert Engine + Policy Manager)"
    echo "  - ransomeye-alert-engine.service (Alert API Service)"
    echo "  - ransomeye-ai-models.service (AI Core + Model Registry)"
    echo "  - ransomeye-ai-core.service (AI API Service)"
    echo "  - ransomeye-decryptor.service (Decryptor Engine)"
    echo "  - ransomeye-killchain.service (MITRE Timeline Builder)"
    echo "  - ransomeye-correlation.service (Threat Correlation)"
    echo "  - ransomeye-llm-summary.service (LLM Summarization)"
    echo "  - ransomeye-forensic.service (Forensic Dump Engine)"
    echo "  - ransomeye-response.service (Incident Response)"
    echo "  - ransomeye-assistant.service (SOC Assistant)"
    echo "  - ransomeye-deception.service (Deception Engine)"
    echo "  - ransomeye-threatintel.service (Threat Intelligence)"
    echo "  - ransomeye-net-scan.service (Network Scanner)"
    echo "  - ransomeye-hnmp.service (Host/Network Profiling)"
    echo "  - ransomeye-api.service (Main API Service)"
    echo "  - ransomeye-orchestrator-loop.service (Orchestrator Loop)"
    echo
    echo "Timers:"
    echo "  - killchain-rebuilder.timer (KillChain updates every 5min)"
    echo "  - correlation-runner.timer (IOC correlation every 10min)"
    echo "  - forensic-dump-trigger.timer (Forensic dumps every 15min)"
    echo "  - model-drift-check.timer (Model drift monitoring)"
    echo "  - ransomeye-orchestrator-loop.timer (Orchestrator loop timer)"
    echo "  - alert-policy-escalation.timer (Alert policy escalation)"
    echo
    echo "Useful Commands:"
    echo "  - systemctl status ransomeye-master-core.service"
    echo "  - journalctl -u ransomeye-master-core.service -f"
    echo "  - systemctl restart ransomeye-master-core.service"
    echo
    echo "Support:"
    echo "  - Email: $AUTHOR"
    echo "  - Website: $WEBSITE"
    echo
    echo "=========================================="
}

# Main installation function
main() {
    echo "=========================================="
    echo "$SCRIPT_NAME v$VERSION"
    echo "=========================================="
    echo
    
    check_root
    check_requirements
    install_system_deps
    setup_postgresql
    create_service_user
    install_python_deps
    create_install_dir
    create_systemd_services
    create_log_dirs
    create_output_dirs
    create_ai_models_dir
    create_dashboards_dir
    setup_database_schema
    enable_services
    run_validation
    display_summary
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@" 