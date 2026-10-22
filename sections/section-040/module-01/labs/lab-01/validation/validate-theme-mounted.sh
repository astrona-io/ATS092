#!/usr/bin/env bash
# PASS when the Keycloak container mounts a volume at /opt/keycloak/themes/inventory.
set -uo pipefail

NAMESPACE="themes-demo"

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

MOUNTS="$(kubectl -n "$NAMESPACE" get deployment keycloak \
  -o jsonpath='{range .spec.template.spec.containers[0].volumeMounts[*]}{.mountPath}{"\n"}{end}' 2>/dev/null)"
if ! printf '%s\n' "$MOUNTS" | grep -qx '/opt/keycloak/themes/inventory'; then
  echo "FAIL: the keycloak container mounts nothing at /opt/keycloak/themes/inventory."
  exit 1
fi
echo "PASS: the theme is mounted at /opt/keycloak/themes/inventory."
exit 0
