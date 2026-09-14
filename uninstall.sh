#!/bin/sh
set -eu

# Remove only the files and drop-ins installed by install.sh.
if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo $0" >&2
    exit 1
fi

INSTALL_DIR=/usr/local/libexec
SUSPEND_DROPIN_DIR=/etc/systemd/system/systemd-suspend.service.d
SUSPEND_THEN_HIBERNATE_DROPIN_DIR=/etc/systemd/system/systemd-suspend-then-hibernate.service.d

# Stop a pending detached re-suspend before removing its hook scripts.
systemctl stop re-suspend-once.timer re-suspend-once.service 2>/dev/null || true
rm -f /run/re-suspend-state

rm -f "$SUSPEND_DROPIN_DIR/re-suspend.conf"
rmdir "$SUSPEND_DROPIN_DIR" 2>/dev/null || true
rm -f "$SUSPEND_THEN_HIBERNATE_DROPIN_DIR/re-suspend.conf"
rmdir "$SUSPEND_THEN_HIBERNATE_DROPIN_DIR" 2>/dev/null || true

rm -f "$INSTALL_DIR/re-suspend-pre.sh" "$INSTALL_DIR/re-suspend-post.sh"

systemctl daemon-reload

echo "Uninstalled re-suspend hooks."
