#!/usr/bin/env bash
# PASS when the email theme files are at the paths Keycloak reads under /opt/keycloak/themes/inventory.
set -uo pipefail

NAMESPACE="themes-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}

for THEME_FILE in email/theme.properties email/messages/messages_en.properties; do
  if ! kubectl -n "$NAMESPACE" exec deploy/keycloak -- test -f "/opt/keycloak/themes/inventory/$THEME_FILE" 2>/dev/null; then
    echo "FAIL: the file /opt/keycloak/themes/inventory/$THEME_FILE does not exist in the Keycloak pod."
    exit 1
  fi
done
echo "PASS: the email theme files are at the paths Keycloak reads."
exit 0
