#!/usr/bin/env bash
# PASS when the keycloak Deployment has at least one ready pod.
set -uo pipefail

NAMESPACE="spi-demo"

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

READY="$(kubectl -n "$NAMESPACE" get deployment keycloak -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
if [ "${READY:-0}" -lt 1 ]; then
  echo "FAIL: the keycloak Deployment has no ready pod. Check kubectl -n $NAMESPACE logs deploy/keycloak."
  exit 1
fi
echo "PASS: Keycloak is running and ready."
exit 0
