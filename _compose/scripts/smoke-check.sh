#!/bin/sh
set -eu

COMPOSE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

HERMES_HOST_PORT="${HERMES_HOST_PORT:-18642}"
HERMES_DASHBOARD_HOST_PORT="${HERMES_DASHBOARD_HOST_PORT:-19119}"
HERMES_DASHBOARD_BASIC_AUTH_USERNAME="${HERMES_DASHBOARD_BASIC_AUTH_USERNAME:-musuhi_admin}"
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD:-Musuhi-Local-2026!RotateNow}"

log() {
  printf '%s\n' "$1"
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

http_code() {
  url="$1"
  shift
  curl -sS --retry 12 --retry-delay 1 --retry-all-errors -o /dev/null -w "%{http_code}" "$@" "$url" 2>/dev/null || true
}

http_code_no_retry() {
  url="$1"
  shift
  curl -sS -o /dev/null -w "%{http_code}" "$@" "$url" 2>/dev/null || true
}

response_headers() {
  url="$1"
  shift
  curl -sS --retry 12 --retry-delay 1 --retry-all-errors -D - -o /dev/null "$@" "$url" || true
}

location_from_headers() {
  printf '%s\n' "$1" | awk 'BEGIN{IGNORECASE=1} /^Location:/ {sub(/\r$/, "", $2); print $2; exit}'
}

log "[1/5] compose status check"
if ! docker compose -f "$COMPOSE_FILE" ps >/dev/null 2>&1; then
  fail "docker compose ps failed"
fi

if ! docker compose -f "$COMPOSE_FILE" ps --status running | grep -q "hermes"; then
  fail "hermes is not running"
fi

log "[2/5] TCP port check"
for p in "$HERMES_HOST_PORT" "$HERMES_DASHBOARD_HOST_PORT"; do
  if ! nc -z localhost "$p" >/dev/null 2>&1; then
    fail "port $p is not open"
  fi
  log "  - port $p: open"
done

log "[3/5] dashboard auth gate check (unauthenticated)"
unauth_headers="$(response_headers "http://localhost:${HERMES_DASHBOARD_HOST_PORT}/")"
unauth_code="$(printf '%s\n' "$unauth_headers" | awk 'NR==1{print $2; exit}')"
unauth_location="$(location_from_headers "$unauth_headers")"
case "$unauth_code" in
  401|302|303|307|308)
    log "  - unauthenticated code: $unauth_code (expected auth gate)"
    if [ -n "$unauth_location" ]; then
      log "  - redirect location: $unauth_location"
    fi
    ;;
  *)
    fail "unexpected unauthenticated dashboard code: $unauth_code"
    ;;
esac

case "$unauth_location" in
  */auth/*|*/login*|/auth/*|/login*)
    log "  - auth redirect path looks valid"
    ;;
  "")
    if [ "$unauth_code" = "401" ]; then
      log "  - unauthenticated 401 without redirect is acceptable"
    fi
    ;;
  *)
    fail "unexpected unauthenticated redirect location: $unauth_location"
    ;;
esac

log "[4/5] dashboard login check (basic auth)"
auth_headers="$(response_headers "http://localhost:${HERMES_DASHBOARD_HOST_PORT}/" -u "${HERMES_DASHBOARD_BASIC_AUTH_USERNAME}:${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD}")"
auth_code="$(printf '%s\n' "$auth_headers" | awk 'NR==1{print $2; exit}')"
case "$auth_code" in
  200|302|303)
    log "  - authenticated code: $auth_code"
    ;;
  *)
    fail "dashboard auth failed, code: $auth_code"
    ;;
esac

final_code="$(http_code "http://localhost:${HERMES_DASHBOARD_HOST_PORT}/" -L -u "${HERMES_DASHBOARD_BASIC_AUTH_USERNAME}:${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD}")"
case "$final_code" in
  200)
    log "  - authenticated follow-redirect final code: $final_code"
    ;;
  *)
    fail "dashboard follow-redirect check failed, code: $final_code"
    ;;
esac

log "[5/5] Hermes API port reachability"
if ! nc -z localhost "$HERMES_HOST_PORT" >/dev/null 2>&1; then
  fail "Hermes API TCP endpoint is not reachable on port ${HERMES_HOST_PORT}"
fi
log "  - Hermes API TCP port reachable: ${HERMES_HOST_PORT}"

# Some Hermes builds reset plain HTTP on the API socket; do not fail on that.
api_code="$(http_code_no_retry "http://localhost:${HERMES_HOST_PORT}/")"
log "  - Hermes API HTTP probe code: $api_code"

log "Smoke check passed"
