#!/bin/sh
# ExecStopPost for systemd-suspend.service / systemd-suspend-then-hibernate.service
# Runs after resume; decides whether this is the RTC auto-wake or the final wake.

STATE_FILE="/run/re-suspend-state"
TAG="re-suspend-hook"

# No state means this was an ordinary suspend/resume cycle.
if [ ! -f "$STATE_FILE" ]; then
    logger -t "$TAG" "Normal wake up detected (no re-suspend cycle active)."
    exit 0
fi

# The first line is either the original suspend mode or the cycle marker.
PREV_MODE=$(sed -n '1p' "$STATE_FILE")

# The second suspend is the final one; do not schedule another wake cycle.
if [ "$PREV_MODE" = "in_progress" ]; then
    logger -t "$TAG" "Final wake up complete. Cleaning up state file."
    rm -f "$STATE_FILE"
    exit 0
fi

# The second line is the RTC wake deadline written by pre.sh.
WAKE_AT=$(sed -n '2p' "$STATE_FILE")
NOW=$(date +%s%3N)

# Reject malformed state rather than making a re-suspend decision from it.
case "$WAKE_AT" in
    ''|*[!0-9]*)
        logger -t "$TAG" "Invalid RTC wake time. Cancelling RTC alarm and re-suspend."
        rtcwake -m disable
        rm -f "$STATE_FILE"
        exit 1
        ;;
esac

    # A wake before the deadline was caused by the user, for example by opening
    # the lid. Cancel the pending RTC alarm and abandon this re-suspend cycle.
if [ "$NOW" -lt "$WAKE_AT" ]; then
    logger -t "$TAG" "Manual wake up detected before the RTC wake time. Cancelling re-suspend."
    rtcwake -m disable
    rm -f "$STATE_FILE"
    exit 0
fi

logger -t "$TAG" "Auto wake up detected (original mode: $PREV_MODE). Scheduling re-suspend in 5s."
# Mark the cycle before starting the detached timer so its pre-hook skips RTC.
echo "in_progress" > "$STATE_FILE"

# Run outside this service's stop transaction to avoid re-entering suspend
# while systemd is still stopping the current suspend service.
# Re-check the marker immediately before suspending in case the state was cleared.
# shellcheck disable=SC1009,SC2016
if ! systemd-run --on-active=5s --unit=re-suspend-once \
    /bin/sh -c '
        if [ "$(sed -n "1p" /run/re-suspend-state 2>/dev/null)" = "in_progress" ]; then
            exec systemctl "$1"
        fi
    ' \
    sh "$PREV_MODE"; then
    logger -t "$TAG" "Failed to schedule re-suspend. Removing state."
    rm -f "$STATE_FILE"
    exit 1
fi
