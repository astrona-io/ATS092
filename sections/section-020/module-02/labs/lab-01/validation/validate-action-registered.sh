#!/usr/bin/env bash
# PASS when the realm lists accept-terms as an enabled required action.
set -uo pipefail

NAMESPACE="actions-demo"

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

if kcadm get authentication/required-actions/accept-terms -r inventory 2>/dev/null | jq -e '.enabled == true' >/dev/null 2>&1; then
  echo "PASS: accept-terms is registered and enabled."
  exit 0
fi
echo "FAIL: the realm inventory has no enabled required action accept-terms."
exit 1
