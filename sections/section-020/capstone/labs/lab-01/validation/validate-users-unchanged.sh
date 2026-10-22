#!/usr/bin/env bash
# PASS when alice still has department=warehouse and bob still has no department.
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

ALICE="$(kcadm get users -r inventory -q username=alice -q exact=true --fields attributes 2>/dev/null)"
if ! printf '%s' "$ALICE" | tr -d ' \n' | grep -q '"department":\["warehouse"\]'; then
  echo "FAIL: alice no longer has department=warehouse. Fix the code, not the users."
  exit 1
fi
BOB="$(kcadm get users -r inventory -q username=bob -q exact=true --fields attributes 2>/dev/null)"
if printf '%s' "$BOB" | grep -q '"department"'; then
  echo "FAIL: bob has a department now. Fix the code, not the users."
  exit 1
fi
echo "PASS: the users' departments are unchanged."
exit 0
