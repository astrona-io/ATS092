#!/usr/bin/env bash
# PASS when require-department-attribute is a REQUIRED step of direct-grant-with-department, the flow is bound to inventory-cli for the direct grant, and the realm's own direct grant flow is unchanged.
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

if ! kcadm get authentication/flows/direct-grant-with-department/executions -r inventory \
     --fields providerId,requirement --format csv --noquotes 2>/dev/null \
     | grep -qx 'require-department-attribute,REQUIRED'; then
  echo "FAIL: the flow direct-grant-with-department has no REQUIRED step require-department-attribute."
  exit 1
fi
FLOW_ID="$(kcadm get authentication/flows -r inventory --fields id,alias --format csv --noquotes 2>/dev/null \
  | awk -F, '$2=="direct-grant-with-department"{print $1}')"
CLIENT_ID="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes 2>/dev/null)"
if [ -z "$FLOW_ID" ] || ! kcadm get "clients/$CLIENT_ID" -r inventory --fields authenticationFlowBindingOverrides 2>/dev/null \
     | grep -q "\"direct_grant\" *: *\"$FLOW_ID\""; then
  echo "FAIL: inventory-cli does not use direct-grant-with-department as its direct grant flow override."
  exit 1
fi
if ! kcadm get realms/inventory --fields directGrantFlow 2>/dev/null | grep -q '"directGrantFlow" *: *"direct grant"'; then
  echo "FAIL: the realm's direct grant flow was changed. Bind the new flow to the client only."
  exit 1
fi
echo "PASS: the authenticator is a required step, and the flow is bound to inventory-cli only."
exit 0
