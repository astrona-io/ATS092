#!/usr/bin/env bash
# PASS when the last run of the build-provider Job finished without an error.
set -uo pipefail

NAMESPACE="spicapstone-demo"

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

SUCCEEDED="$(kubectl -n "$NAMESPACE" get job build-provider -o jsonpath='{.status.succeeded}' 2>/dev/null)"
if [ "${SUCCEEDED:-0}" -lt 1 ]; then
  echo "FAIL: the Job build-provider did not succeed. Read kubectl -n $NAMESPACE logs job/build-provider."
  exit 1
fi
echo "PASS: the last build of the provider succeeded."
exit 0
