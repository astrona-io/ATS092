#!/usr/bin/env bash
# PASS when creating a user through the Admin REST API produces an AUDIT-LOG admin line.
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

CHECK_USER="audit-check-$$"
kcadm create users -r inventory -s username="$CHECK_USER" -s enabled=true \
  -s email="$CHECK_USER@example.com" -s firstName=Audit -s lastName=Check >/dev/null 2>&1
sleep 3
EXPECTED="AUDIT-LOG admin operation=CREATE resourceType=USER realm=inventory"
FOUND="$(kubectl -n "$NAMESPACE" logs deploy/keycloak --since=2m 2>/dev/null | grep -F "$EXPECTED" || true)"
CHECK_ID="$(kcadm get users -r inventory -q username="$CHECK_USER" -q exact=true --fields id --format csv --noquotes 2>/dev/null)"
[ -n "$CHECK_ID" ] && kcadm delete "users/$CHECK_ID" -r inventory >/dev/null 2>&1
if [ -z "$FOUND" ]; then
  echo "FAIL: creating a user wrote no line with: $EXPECTED"
  exit 1
fi
echo "PASS: the admin change was logged: $(printf '%s' "$FOUND" | tail -1)"
exit 0
