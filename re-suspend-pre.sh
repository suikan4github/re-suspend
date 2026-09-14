#!/bin/sh
# ExecStartPre for systemd-suspend.service / systemd-suspend-then-hibernate.service
# $1 = mode passed from the drop-in (suspend | suspend-then-hibernate)

STATE_FILE="/run/re-suspend-state"
TAG="re-suspend-hook"
MODE="$1"

# The second suspend in the cycle must not schedule another RTC wake.
if [ -f "$STATE_FILE" ] && [ "$(sed -n '1p' "$STATE_FILE")" = "in_progress" ]; then
    logger -t "$TAG" "Re-entering sleep ($MODE). Skipping RTC wake timer setup."
    exit 0
fi

logger -t "$TAG" "Initial sleep triggered. Mode: $MODE. Setting RTC wake timer for 30s."
# Store the planned wake time so post.sh can distinguish an early manual wake.
# State format: mode, wake deadline in milliseconds, and a diagnostic cycle ID.
WAKE_AT=$(date +%s%3N)
CYCLE_ID="$$-$WAKE_AT"
printf '%s\n%s\n%s\n' "$MODE" "$WAKE_AT" "$CYCLE_ID" > "$STATE_FILE"

# -m no only programs the RTC alarm; systemd performs the actual suspend.
if ! rtcwake -m no -s 30; then
    # Do not leave stale state that could trigger an unrelated re-suspend.
    logger -t "$TAG" "Failed to set RTC wake timer. Removing state."
    rm -f "$STATE_FILE"
    exit 1
fi
