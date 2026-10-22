#!/usr/bin/env bash
# PASS when the realm inventory lists both jboss-logging and audit-log as event listeners.
set -uo pipefail

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

CONFIG="$(kcadm get events/config -r inventory 2>/dev/null)"
for LISTENER in jboss-logging audit-log; do
  if ! printf '%s' "$CONFIG" | grep -q "\"$LISTENER\""; then
    echo "FAIL: the realm inventory does not list the event listener $LISTENER."
    exit 1
  fi
done
echo "PASS: the realm sends events to jboss-logging and audit-log."
exit 0
