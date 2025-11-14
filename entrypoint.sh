#!/bin/sh
# Minimal supervisor for kspeeder:
# - Ensure default mirror config exists
# - Run /usr/bin/kspeeder and restart it when it exits (it auto-stops ~ every 36h)
# - Stop cleanly on SIGTERM/SIGINT

APP="/usr/bin/kspeeder"
RESTART_DELAY="${KSPEEDER_RESTART_DELAY:-5}"   # seconds between restarts

# 1) Bootstrap config if not present
CONFIG_DIR="${KSPEEDER_CONFIG:-/kspeeder-config}"
CONFIG_FILE="${CONFIG_DIR}/kspeeder.yml"
if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$CONFIG_DIR" 2>/dev/null || true
  cat > "$CONFIG_FILE" << 'EOF'
mirrors:
EOF
fi
export KS_USER_MIRROR_CONFIG="$CONFIG_FILE"

# 2) Simple supervise loop with trap
STOP=0
PID=""
trap 'STOP=1; [ -n "$PID" ] && kill -TERM "$PID" 2>/dev/null || true' INT TERM

while [ "$STOP" -eq 0 ]; do
  "$APP" &
  PID=$!
  wait "$PID" || true
  [ "$STOP" -eq 1 ] && break
  sleep "$RESTART_DELAY"
done

exit 0
