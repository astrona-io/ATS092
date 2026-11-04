#!/usr/bin/env bash
# PASS when the Deployment has the correctly named variable and not the wrong one.
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

NAMES="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].env[*].name}' 2>/dev/null)"
case " $NAMES " in
  *" KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODES "*)
    echo "FAIL: the wrong variable KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODES is still set."
    exit 1 ;;
esac
case " $NAMES " in
  *" KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE "*)
    echo "PASS: the Deployment sets KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE."
    exit 0 ;;
esac
echo "FAIL: the Deployment does not set KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE."
exit 1
