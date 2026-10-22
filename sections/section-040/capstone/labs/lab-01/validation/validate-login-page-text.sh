#!/usr/bin/env bash
# PASS when the login page of the realm inventory shows the text Sign in to Inventory.
set -uo pipefail

NAMESPACE="themescapstone-demo"

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

LOGIN_URL='http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Flocalhost%2Fcallback'
PAGE="$(kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s "$LOGIN_URL" 2>/dev/null)"
if ! printf '%s' "$PAGE" | grep -q 'Sign in to Inventory'; then
  echo "FAIL: the login page of the realm inventory does not show the text Sign in to Inventory."
  exit 1
fi
echo "PASS: the login page shows Sign in to Inventory."
exit 0
