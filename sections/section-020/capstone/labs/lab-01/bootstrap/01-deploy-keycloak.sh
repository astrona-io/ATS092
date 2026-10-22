#!/usr/bin/env bash
# Deploys Keycloak 26.8.1, the provider and Maven volumes and the tester pod
# for ats-092-capstone-020, then creates the realm inventory with its users and clients.
#
# Graded lab bootstrap: this prepares the environment ONLY. It never creates
# the objects the task asks for.
set -euo pipefail

NAMESPACE="authcapstone-demo"

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

# upload_source DIR: stores every file under DIR in the ConfigMap
# provider-source. A key is the file's path with "/" written as "__".
upload_source() {
  local source_dir="$1" file key
  local from_file_args=()
  while IFS= read -r file; do
    key="$(printf '%s' "$file" | sed 's|/|__|g')"
    from_file_args+=("--from-file=$key=$source_dir/$file")
  done < <(cd "$source_dir" && find . -type f | sed 's|^\./||' | sort)
  kubectl -n "$NAMESPACE" create configmap provider-source "${from_file_args[@]}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

# build_provider: runs the build Job once and waits for it to finish.
# Returns 1 when the build fails.
build_provider() {
  local succeeded failed
  kubectl -n "$NAMESPACE" delete job build-provider --ignore-not-found --wait=true
  kubectl apply -f "$MANIFEST_DIR/job-build-provider.yaml"
  for _ in $(seq 1 180); do
    succeeded="$(kubectl -n "$NAMESPACE" get job build-provider -o jsonpath='{.status.succeeded}' 2>/dev/null)"
    failed="$(kubectl -n "$NAMESPACE" get job build-provider -o jsonpath='{.status.failed}' 2>/dev/null)"
    if [ "${succeeded:-0}" -ge 1 ]; then
      return 0
    fi
    if [ "${failed:-0}" -ge 1 ]; then
      return 1
    fi
    sleep 5
  done
  return 1
}

restart_keycloak() {
  kubectl -n "$NAMESPACE" rollout restart deployment/keycloak
  wait_for_keycloak
}

# create_user USERNAME PASSWORD FIRST_NAME [DEPARTMENT]
create_user() {
  local username="$1" password="$2" first_name="$3" department="${4:-}"
  if [ -n "$(kcadm get users -r inventory -q username="$username" -q exact=true --fields id --format csv --noquotes)" ]; then
    return 0
  fi
  if [ -n "$department" ]; then
    kcadm create users -r inventory -s username="$username" -s enabled=true \
      -s email="$username@example.com" -s emailVerified=true \
      -s firstName="$first_name" -s lastName=Example \
      -s "attributes.department=[\"$department\"]"
  else
    kcadm create users -r inventory -s username="$username" -s enabled=true \
      -s email="$username@example.com" -s emailVerified=true \
      -s firstName="$first_name" -s lastName=Example
  fi
  kcadm set-password -r inventory --username "$username" --new-password "$password"
}

client_uuid() {
  kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes
}

echo "[lab] Applying starting workloads..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
# Keep the build Job's definition in the cluster, so the build_provider helper
# can start a new build without a file on the reader's machine.
kubectl -n "$NAMESPACE" create configmap build-provider-job \
  --from-file=job.yaml="$MANIFEST_DIR/job-build-provider.yaml" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Waiting for Keycloak (this can take a few minutes)..."
wait_for_keycloak
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s

echo "[lab] Creating the realm inventory..."
if ! kcadm get realms/inventory --fields realm >/dev/null 2>&1; then
  kcadm create realms -s realm=inventory -s enabled=true
fi
# Keycloak 26 keeps only the user attributes the user profile declares.
# Allow other attributes, so the attribute department is kept.
kcadm update users/profile -r inventory -s unmanagedAttributePolicy=ENABLED
create_user alice alice-password Alice warehouse
create_user bob bob-password Bob
if [ -z "$(client_uuid inventory-cli)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
    -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
fi

echo "[lab] Keycloak ready."
