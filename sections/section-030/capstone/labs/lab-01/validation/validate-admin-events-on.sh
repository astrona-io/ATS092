#!/usr/bin/env bash
# PASS when the realm inventory saves admin events and their details.
set -uo pipefail

NAMESPACE="eventscapstone-demo"

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

CONFIG="$(kcadm get events/config -r inventory 2>/dev/null)"
if ! printf '%s' "$CONFIG" | grep -q '"adminEventsEnabled" *: *true'; then
  echo "FAIL: admin events are not turned on for the realm inventory."
  exit 1
fi
if ! printf '%s' "$CONFIG" | grep -q '"adminEventsDetailsEnabled" *: *true'; then
  echo "FAIL: admin event details are not turned on for the realm inventory."
  exit 1
fi
echo "PASS: the realm saves admin events with details."
exit 0
