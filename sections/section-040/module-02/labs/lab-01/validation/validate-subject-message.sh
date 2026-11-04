#!/usr/bin/env bash
# PASS when the email theme sets the password reset subject to "Reset your Inventory password".
set -uo pipefail

NAMESPACE="themes-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}

if ! kubectl -n "$NAMESPACE" exec deploy/keycloak -- cat /opt/keycloak/themes/inventory/email/messages/messages_en.properties 2>/dev/null \
     | grep -qxF 'passwordResetSubject=Reset your Inventory password'; then
  echo "FAIL: the mounted messages_en.properties does not contain passwordResetSubject=Reset your Inventory password."
  exit 1
fi
echo "PASS: the email theme sets the password reset subject."
exit 0
