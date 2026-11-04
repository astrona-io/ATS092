#!/usr/bin/env bash
# PASS when the realm inventory stores LOGIN and LOGIN_ERROR events, expires them after 86400 seconds and still lists jboss-logging.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

NAMESPACE="events-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}

# get_user_token USER PASSWORD: prints the access token, or nothing.
# The password grant is used only so a script can sign a user in.
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      --data-urlencode username="$1" --data-urlencode password="$2" \
    | jq -r ".access_token // empty"' sh "$1" "$2" 2>/dev/null
}

CONFIG="$(kcadm get events/config -r inventory 2>/dev/null | tr -d ' \n')"
if [ -z "$CONFIG" ]; then
  echo "FAIL: cannot read the event configuration of the realm inventory."
  exit 1
fi
if ! printf '%s' "$CONFIG" | grep -q '"eventsEnabled":true'; then
  echo "FAIL: eventsEnabled is not true, so the realm stores no user events."
  exit 1
fi
for TYPE in LOGIN LOGIN_ERROR; do
  if ! printf '%s' "$CONFIG" | grep -q "\"$TYPE\""; then
    echo "FAIL: enabledEventTypes does not contain $TYPE."
    exit 1
  fi
done
if ! printf '%s' "$CONFIG" | grep -q '"eventsExpiration":86400'; then
  echo "FAIL: eventsExpiration is not 86400 seconds."
  exit 1
fi
if ! printf '%s' "$CONFIG" | grep -q '"jboss-logging"'; then
  echo "FAIL: the realm no longer lists the event listener jboss-logging."
  exit 1
fi
echo "PASS: the realm stores LOGIN and LOGIN_ERROR events for 86400 seconds and keeps jboss-logging."
exit 0
