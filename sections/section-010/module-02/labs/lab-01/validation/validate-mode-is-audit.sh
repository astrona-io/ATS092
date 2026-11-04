#!/usr/bin/env bash
# PASS when the endpoint reports mode=audit.
set -uo pipefail

NAMESPACE="config-demo"

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

BODY="$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/inventory-status 2>/dev/null)"
case "$BODY" in
  *"inventory-status ok realm=inventory mode=audit"*)
    echo "PASS: the endpoint answers: $BODY"
    exit 0 ;;
esac
echo "FAIL: the endpoint did not report mode=audit. Got: ${BODY:-nothing}"
exit 1
