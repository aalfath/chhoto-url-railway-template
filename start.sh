#!/bin/sh
# Start script for Chhoto URL on Railway.
# - listens on Railway's $PORT, keeps the SQLite database on the /data volume
# - refuses to start without a password (no open admin UI)
# - watches the app and its loopback /healthz and exits non-zero on any stop,
#   so Railway's ON_FAILURE restart policy brings it back.
set -u

log() { echo "[start.sh] $*"; }

: "${PORT:=4567}"
export CHHOTO_LISTEN_PORT="$PORT"
export CHHOTO_LISTEN_ADDRESS="${CHHOTO_LISTEN_ADDRESS:-::}"
export CHHOTO_DB_URL="${CHHOTO_DB_URL:-/data/urls.sqlite}"
export CHHOTO_SQLITE_USE_WAL_MODE="${CHHOTO_SQLITE_USE_WAL_MODE:-True}"
export CHHOTO_EXIT_ON_NO_AUTH="${CHHOTO_EXIT_ON_NO_AUTH:-True}"
export CHHOTO_REDIRECT_METHOD="${CHHOTO_REDIRECT_METHOD:-TEMPORARY}"
export CHHOTO_SLUG_STYLE="${CHHOTO_SLUG_STYLE:-Pair}"
export CHHOTO_TRY_LONGER_SLUG="${CHHOTO_TRY_LONGER_SLUG:-True}"
HEALTH_PORT="${CHHOTO_HEALTH_PORT:-1729}"
export CHHOTO_HEALTH_PORT="$HEALTH_PORT"

# Ignore an empty or half-resolved site URL (e.g. "https://" before the domain exists).
case "${CHHOTO_SITE_URL:-}" in
  http://?*.?*|https://?*.?*) ;;
  *) [ -n "${CHHOTO_SITE_URL:-}" ] && log "Ignoring invalid CHHOTO_SITE_URL '${CHHOTO_SITE_URL}'."; unset CHHOTO_SITE_URL ;;
esac

# Never run with an open admin UI.
if [ -z "$(echo "${CHHOTO_PASSWORD:-}" | tr -d '[:space:]')" ] && [ -z "${CHHOTO_OIDC_ISSUER_URL:-}" ]; then
  log "CHHOTO_PASSWORD is empty. Set it (the template generates one) and redeploy."
  exit 1
fi

db_dir=$(dirname "$CHHOTO_DB_URL")
mkdir -p "$db_dir" || { log "Cannot create $db_dir"; exit 1; }
if ! touch "$db_dir/.write-test" 2>/dev/null; then
  log "$db_dir is not writable. Attach a volume at /data."; exit 1
fi
rm "$db_dir/.write-test"

/app/chhoto-url &
app=$!
trap 'kill -TERM "$app" 2>/dev/null; wait "$app"; exit 143' TERM INT

# Poll instead of `wait -n` (BusyBox). Health is checked once the app has had time to start.
fails=0
i=0
while kill -0 "$app" 2>/dev/null; do
  sleep 5
  i=$((i + 1))
  if [ "$HEALTH_PORT" != "0" ] && [ $((i % 6)) -eq 0 ]; then
    if wget -q -T 10 -O /dev/null "http://127.0.0.1:${HEALTH_PORT}/healthz" 2>/dev/null; then
      fails=0
    else
      fails=$((fails + 1))
      log "Health check failed ($fails/3)."
      if [ "$fails" -ge 3 ]; then
        log "App is unhealthy, stopping it so Railway restarts the service."
        kill -TERM "$app" 2>/dev/null; sleep 5; kill -KILL "$app" 2>/dev/null
        exit 1
      fi
    fi
  fi
done

wait "$app"
code=$?
log "Chhoto URL exited with code $code."
[ "$code" -eq 0 ] && code=1
exit "$code"
