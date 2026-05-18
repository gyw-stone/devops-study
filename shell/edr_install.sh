#!/bin/bash
### auto install edr agent ,only support ubuntu and amzn 2 and amzn 2023
# Configuration
APP_NAME="falcon-sensor"
SERVICE_NAME="falcon-sensor"
DEB_URL="xxx"    
AL2_RPM_URL="xxx"     
AL2023_RPM_URL="xxxx"
TMP_DIR="/tmp/${APP_NAME}_install"

set -e

# Logging utilities
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2
}

get_os_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

install_deb() {
    if dpkg -l | grep -qw "^ii.*${APP_NAME}"; then
        log_info "${APP_NAME} is already installed. Skipping installation."
        return 0
    fi

    log_info "Downloading DEB package..."
    sudo mkdir -p "$TMP_DIR"
    sudo curl -sL "$DEB_URL" -o "${TMP_DIR}/${APP_NAME}.deb"

    log_info "Installing DEB package..."
    sudo dpkg -i "${TMP_DIR}/${APP_NAME}.deb"
    log_info "DEB package installation completed."
}

install_rpm() {
    if rpm -q "$APP_NAME" > /dev/null 2>&1; then
        log_info "${APP_NAME} is already installed. Skipping installation."
        return 0
    fi

    local version_id
    version_id=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')

    local rpm_url=""
    if [ "$version_id" = "2" ]; then
        rpm_url="$AL2_RPM_URL"
        log_info "Detected Amazon Linux 2."
    elif [ "$version_id" = "2023" ]; then
        rpm_url="$AL2023_RPM_URL"
        log_info "Detected Amazon Linux 2023."
    else
        log_error "Unsupported Amazon Linux version ($version_id). Only 2 and 2023 are supported."
        exit 1
    fi

    log_info "Downloading RPM package..."
    sudo mkdir -p "$TMP_DIR"
    
    if ! sudo curl -sL "$rpm_url" -o "${TMP_DIR}/${APP_NAME}.rpm"; then
        log_error "Failed to download RPM package from $rpm_url."
        exit 1
    fi

    log_info "Installing RPM package..."
    if command -v dnf > /dev/null 2>&1; then
        sudo dnf install -y "${TMP_DIR}/${APP_NAME}.rpm"
    else
        log_info "dnf command not found. Falling back to yum."
        sudo yum install -y "${TMP_DIR}/${APP_NAME}.rpm"
    fi

    log_info "RPM package installation completed."
}

main() {
    local os_id
    os_id=$(get_os_id)

    case "$os_id" in
        ubuntu|debian)
            log_info "OS detected: $os_id"
            install_deb
            ;;
        amzn)
            log_info "OS detected: Amazon Linux"
            install_rpm
            ;;
        *)
            log_error "Unsupported OS: $os_id. Supported targets: Ubuntu/Debian, Amazon Linux 2/2023."
            exit 1
            ;;
    esac

    # Cleanup
    sudo rm -rf "$TMP_DIR"

    # Service configuration
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "Service $SERVICE_NAME is already running. Skipping startup."
    else
        log_info "Configuring and starting $SERVICE_NAME..."
        sudo /opt/CrowdStrike/falconctl -s --cid=AF44A5F5EF1C40F1A0B7F0B0D562F50A-0A
        sudo systemctl enable "$SERVICE_NAME"
        sudo systemctl start "$SERVICE_NAME"
        log_info "Service $SERVICE_NAME configured and started successfully."
    fi
}

# Execute main function
main
