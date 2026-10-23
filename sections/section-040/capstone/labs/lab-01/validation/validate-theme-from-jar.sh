#!/usr/bin/env bash
# PASS when no theme directory is mounted and the providers directory holds exactly one JAR.
set -uo pipefail
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

NAMESPACE="themescapstone-demo"

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
if printf '%s\n' "$MOUNTS" | grep -q '^/opt/keycloak/themes'; then
  echo "FAIL: a theme directory is mounted under /opt/keycloak/themes. The task asks for the theme in the JAR."
  exit 1
fi
JARS="$(kubectl -n "$NAMESPACE" exec deploy/keycloak -- sh -c 'ls /opt/keycloak/providers/*.jar 2>/dev/null' | wc -l | tr -d ' ')"
if [ "$JARS" != "1" ]; then
  echo "FAIL: the providers directory holds $JARS JAR files; the theme and the listener must ship in one JAR."
  exit 1
fi
echo "PASS: the theme ships in the one provider JAR."
exit 0
