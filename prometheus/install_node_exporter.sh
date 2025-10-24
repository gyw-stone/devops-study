#!/bin/bash

set -euo pipefail

NODE_EXPORTER_VERSION="1.9.1"
NODE_EXPORTER_NAME="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_NAME}.tar.gz"
ARCHIVE_NAME="node_exporter.tar.gz"
BINARY_PATH="/usr/local/bin/node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

download_node_exporter() {
    if [[ -f "${BINARY_PATH}" ]]; then
        printf "Node exporter binary already exists. Skipping download.\n"
        return
    fi

    wget -O "${ARCHIVE_NAME}" "${NODE_EXPORTER_URL}" || {
        printf "Failed to download node_exporter from GitHub.\n" >&2
        return 1
    }

    tar -xf "${ARCHIVE_NAME}" || {
        printf "Failed to extract %s.\n" "${ARCHIVE_NAME}" >&2
        return 1
    }

    if [[ ! -f "${NODE_EXPORTER_NAME}/node_exporter" ]]; then
        printf "Extracted binary not found.\n" >&2
        return 1
    fi

    cp "${NODE_EXPORTER_NAME}/node_exporter" "${BINARY_PATH}" || {
        printf "Failed to copy binary to %s\n" "${BINARY_PATH}" >&2
        return 1
    }

    chmod +x "${BINARY_PATH}"
}

create_service_file() {
    if [[ -f "${SERVICE_FILE}" ]]; then
        printf "Service file already exists. Skipping creation.\n"
        return
    fi

    tee "${SERVICE_FILE}" > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=${BINARY_PATH}
Restart=on-failure

[Install]
WantedBy=default.target
EOF
}

reload_and_enable_service() {
    systemctl daemon-reload
    if ! systemctl is-enabled --quiet node_exporter; then
        systemctl enable --now node_exporter || {
            printf "Failed to enable and start node_exporter service.\n" >&2
            return 1
        }
    else
        systemctl restart node_exporter
    fi
}

verify_node_exporter() {
    local response
    response=$(curl -s -I http://localhost:9100/metrics | grep -i "HTTP/1.1 200 OK")

    if [[ -z "${response}" ]]; then
        printf "Node exporter is not responding on port 9100.\n" >&2
        return 1
    fi

    printf "Node exporter is running and reachable on port 9100.\n"
}

clean_temp_files() {
    if [[ -f "${ARCHIVE_NAME}" ]]; then
        rm -f "${ARCHIVE_NAME}" || {
            printf "Failed to remove archive file.\n" >&2
            return 1
        }
    fi

    if [[ -d "${NODE_EXPORTER_NAME}" ]]; then
        rm -rf "${NODE_EXPORTER_NAME}" || {
            printf "Failed to remove extracted directory.\n" >&2
            return 1
        }
    fi

    printf "Cleaned up temporary files.\n"
}

main() {
    download_node_exporter
    create_service_file
    reload_and_enable_service
    if verify_node_exporter; then
        clean_temp_files
    fi
}

main
