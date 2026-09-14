#!/bin/sh
set -eu

# Install the hooks and their systemd drop-ins as root.
if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo $0" >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INSTALL_DIR=/usr/local/libexec
PRE_HOOK=$INSTALL_DIR/re-suspend-pre.sh
POST_HOOK=$INSTALL_DIR/re-suspend-post.sh
SUSPEND_DROPIN_DIR=/etc/systemd/system/systemd-suspend.service.d
SUSPEND_THEN_HIBERNATE_DROPIN_DIR=/etc/systemd/system/systemd-suspend-then-hibernate.service.d

install -d -m 0755 "$INSTALL_DIR"
install -m 0755 "$SCRIPT_DIR/re-suspend-pre.sh" "$PRE_HOOK"
install -m 0755 "$SCRIPT_DIR/re-suspend-post.sh" "$POST_HOOK"

install -d -m 0755 "$SUSPEND_DROPIN_DIR" "$SUSPEND_THEN_HIBERNATE_DROPIN_DIR"

cat > "$SUSPEND_DROPIN_DIR/re-suspend.conf" <<EOF
[Service]
ExecStartPre=$PRE_HOOK suspend
ExecStopPost=$POST_HOOK
EOF

cat > "$SUSPEND_THEN_HIBERNATE_DROPIN_DIR/re-suspend.conf" <<EOF
[Service]
ExecStartPre=$PRE_HOOK suspend-then-hibernate
ExecStopPost=$POST_HOOK
EOF

systemctl daemon-reload

echo "Installed re-suspend hooks."
