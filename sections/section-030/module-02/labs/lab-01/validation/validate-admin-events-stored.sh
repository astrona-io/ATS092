#!/usr/bin/env bash
# PASS when admin events are stored with details and an update of a client appears as an admin event.
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
if ! printf '%s' "$CONFIG" | grep -q '"adminEventsEnabled":true'; then
  echo "FAIL: adminEventsEnabled is not true, so the realm stores no admin events."
  exit 1
fi
if ! printf '%s' "$CONFIG" | grep -q '"adminEventsDetailsEnabled":true'; then
  echo "FAIL: adminEventsDetailsEnabled is not true, so stored admin events have no representation."
  exit 1
fi
CLIENT_ID="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes 2>/dev/null | tr -d '\r\n')"
if [ -z "$CLIENT_ID" ]; then
  echo "FAIL: the client inventory-cli does not exist."
  exit 1
fi
kcadm update "clients/$CLIENT_ID" -r inventory -s "description=checked by the grader" >/dev/null 2>&1
sleep 2
STORED="$(kcadm get admin-events -r inventory -q resourceTypes=CLIENT -q operationTypes=UPDATE -q max=20 2>/dev/null | tr -d ' \n')"
if ! printf '%s' "$STORED" | grep -q '"resourceType":"CLIENT"'; then
  echo "FAIL: an update of a client was not stored as an admin event."
  exit 1
fi
if ! printf '%s' "$STORED" | grep -q 'checkedbythegrader'; then
  echo "FAIL: the stored admin event has no representation of the change."
  exit 1
fi
echo "PASS: admin events are stored with their representation."
exit 0
