#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md: if one changes, change the other.
set -euo pipefail

NAMESPACE="events-demo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# kcadm runs kcadm.sh inside the Keycloak pod. It signs in to the master realm
# on every call, so it keeps working after Keycloak restarts.
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}

# wait_for_keycloak: waits for the rollout, then until the administrator can
# sign in (the Admin REST API answers a moment after /health/ready).
wait_for_keycloak() {
  kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
  for _ in $(seq 1 60); do
    if kcadm get realms/master --fields realm >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  echo "Keycloak did not accept the administrator in time." >&2
  return 1
}

kcadm update events/config -r inventory \
  -s eventsEnabled=true \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR"]' \
  -s eventsExpiration=86400 \
  -s adminEventsEnabled=true \
  -s adminEventsDetailsEnabled=true
