#!/bin/sh
set -e

QBIT_WEBUI_PORT="${QBIT_WEBUI_PORT:-8081}"
QBIT_USERNAME="${QBIT_USERNAME:-admin}"
QBIT_PASSWORD="${QBIT_PASSWORD:-adminadmin}"

# Determine qBittorrent config directory based on user
if [ "$(id -u)" = "0" ]; then
    QBIT_CONF_DIR="/root/.config/qBittorrent"
else
    QBIT_CONF_DIR="$(eval echo ~$(whoami))/.config/qBittorrent"
fi

mkdir -p "$QBIT_CONF_DIR"

# Generate PBKDF2 password hash for qBittorrent
generate_qbit_password() {
    SALT=$(openssl rand -base64 16)
    HASH=$(echo -n "$1" | openssl dgst -sha512 -binary -hmac "$SALT" | openssl enc -base64 -A)
    echo "@ByteArray(${SALT}:${HASH})"
}

PASSWORD_HASH=$(generate_qbit_password "$QBIT_PASSWORD")

# Write qBittorrent config if it doesn't exist
if [ ! -f "$QBIT_CONF_DIR/qBittorrent.conf" ]; then
    cat > "$QBIT_CONF_DIR/qBittorrent.conf" <<EOF
[Preferences]
WebUI\Port=${QBIT_WEBUI_PORT}
WebUI\Username=${QBIT_USERNAME}
WebUI\Password_PBKDF2="${PASSWORD_HASH}"

[BitTorrent]
Session\DefaultSavePath=/downloads

[Meta]
MigrationVersion=6
EOF
else
    # Update existing config with new values
    sed -i "s|^WebUI\\\\Port=.*|WebUI\\\\Port=${QBIT_WEBUI_PORT}|" "$QBIT_CONF_DIR/qBittorrent.conf"
    sed -i "s|^WebUI\\\\Username=.*|WebUI\\\\Username=${QBIT_USERNAME}|" "$QBIT_CONF_DIR/qBittorrent.conf"
    sed -i "s|^WebUI\\\\Password_PBKDF2=.*|WebUI\\\\Password_PBKDF2=\"${PASSWORD_HASH}\"|" "$QBIT_CONF_DIR/qBittorrent.conf"
fi

# Generate supervisord config with the configured port
cat > /tmp/supervisord.conf <<EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/tmp/supervisord.pid

[program:seanime]
command=/app/seanime --host 0.0.0.0
directory=/app
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:qbittorrent]
command=qbittorrent-nox --webui-port=${QBIT_WEBUI_PORT}
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

exec /usr/bin/supervisord -c /tmp/supervisord.conf
