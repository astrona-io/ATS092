#!/usr/bin/env bash
# PASS when bob has accept-terms in requiredActions and alice does not.
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

BOB="$(kcadm get users -r inventory -q username=bob -q exact=true --fields requiredActions 2>/dev/null | jq -r '.[0].requiredActions // [] | join(",")')"
ALICE="$(kcadm get users -r inventory -q username=alice -q exact=true --fields requiredActions 2>/dev/null | jq -r '.[0].requiredActions // [] | join(",")')"
case ",$BOB," in
  *",accept-terms,"*) ;;
  *) echo "FAIL: bob does not have accept-terms. Got: ${BOB:-nothing}"; exit 1 ;;
esac
case ",$ALICE," in
  *",accept-terms,"*) echo "FAIL: alice must not have accept-terms."; exit 1 ;;
esac
echo "PASS: bob has accept-terms and alice does not."
exit 0
