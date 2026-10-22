#!/usr/bin/env bash
# PASS when bob, who has no department, still gets a token through inventory-report-cli.
set -uo pipefail

NAMESPACE="authcapstone-demo"

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

kcadm set-password -r inventory --username bob --new-password bob-password >/dev/null 2>&1
TOKEN="$(kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-report-cli \
    -d username=bob -d password=bob-password \
  | jq -r ".access_token // empty"' 2>/dev/null)"
if [ -z "$TOKEN" ]; then
  echo "FAIL: bob gets no token through inventory-report-cli. The department rule must apply to inventory-cli only."
  exit 1
fi
echo "PASS: inventory-report-cli is not affected by the department rule."
exit 0
