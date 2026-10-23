#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md: if one changes, change the other.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

# Upload the corrected source, build it, and restart Keycloak to load it.
upload_source "$SCRIPT_DIR/provider-source"
build_provider
restart_keycloak

# wire_flow REQUIREMENT [client|realm]: copies the direct grant flow, adds the
# authenticator as one more step with the given requirement, and binds the new
# flow to inventory-cli for the direct grant (or, with "realm", to the realm).
wire_flow() {
  local requirement="$1" binding="${2:-client}" execution_id flow_id client_id
  if ! kcadm get authentication/flows -r inventory --fields alias --format csv --noquotes \
       | grep -qx direct-grant-with-department; then
    kcadm create "authentication/flows/direct%20grant/copy" -r inventory \
      -s newName=direct-grant-with-department
  fi
  execution_id="$(kcadm get authentication/flows/direct-grant-with-department/executions -r inventory \
    --fields id,providerId --format csv --noquotes | awk -F, '$2=="require-department-attribute"{print $1}')"
  if [ -z "$execution_id" ]; then
    kcadm create authentication/flows/direct-grant-with-department/executions/execution -r inventory \
      -s provider=require-department-attribute
    execution_id="$(kcadm get authentication/flows/direct-grant-with-department/executions -r inventory \
      --fields id,providerId --format csv --noquotes | awk -F, '$2=="require-department-attribute"{print $1}')"
  fi
  # --no-merge replaces the whole execution: send its current priority too, or
  # it drops to 0 and the step moves before the username and password steps.
  execution_priority="$(kcadm get authentication/flows/direct-grant-with-department/executions -r inventory \
    --fields id,priority --format csv --noquotes | awk -F, -v id="$execution_id" '$1==id{print $2}')"
  kcadm update authentication/flows/direct-grant-with-department/executions -r inventory --no-merge \
    -b "{\"id\":\"$execution_id\",\"requirement\":\"$requirement\",\"priority\":${execution_priority:-0}}"
  flow_id="$(kcadm get authentication/flows -r inventory --fields id,alias --format csv --noquotes \
    | awk -F, '$2=="direct-grant-with-department"{print $1}')"
  if [ "$binding" = "realm" ]; then
    kcadm update realms/inventory -s directGrantFlow=direct-grant-with-department
  else
    client_id="$(client_uuid inventory-cli)"
    kcadm update "clients/$client_id" -r inventory \
      -s "authenticationFlowBindingOverrides.direct_grant=$flow_id"
  fi
}

kcadm update realms/inventory -s "directGrantFlow=direct grant"
wire_flow REQUIRED client
