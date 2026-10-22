#!/usr/bin/env bash
# PASS when bob, who has no department, gets no token, although his account and password are fine.
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

# Make sure a refusal comes from the flow, not from a changed or disabled account.
BOB_ID="$(kcadm get users -r inventory -q username=bob -q exact=true --fields id --format csv --noquotes 2>/dev/null)"
if [ -z "$BOB_ID" ]; then
  echo "FAIL: the user bob does not exist any more. Do not delete users to pass the check."
  exit 1
fi
if ! kcadm get "users/$BOB_ID" -r inventory --fields enabled 2>/dev/null | grep -q '"enabled" *: *true'; then
  echo "FAIL: bob is disabled. The flow must refuse him, not a disabled account."
  exit 1
fi
kcadm set-password -r inventory --username bob --new-password bob-password >/dev/null 2>&1
TOKEN="$(get_user_token bob bob-password)"
if [ -n "$TOKEN" ]; then
  echo "FAIL: bob gets a token through inventory-cli. The flow must refuse a user without a department."
  exit 1
fi
echo "PASS: bob is refused."
exit 0
