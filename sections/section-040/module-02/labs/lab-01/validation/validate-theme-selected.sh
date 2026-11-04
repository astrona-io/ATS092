#!/usr/bin/env bash
# PASS when Keycloak lists the email theme inventory and the realm inventory uses it.
set -uo pipefail

NAMESPACE="themes-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}

if ! kcadm get serverinfo 2>/dev/null | tr -d ' \n' | grep -q '"email":\[[^]]*"name":"inventory"'; then
  echo "FAIL: Keycloak does not list an email theme named inventory."
  exit 1
fi
if ! kcadm get realms/inventory --fields emailTheme 2>/dev/null | tr -d ' ' | grep -q '"emailTheme":"inventory"'; then
  echo "FAIL: the realm inventory does not use the email theme inventory."
  exit 1
fi
echo "PASS: the realm uses the email theme inventory."
exit 0
