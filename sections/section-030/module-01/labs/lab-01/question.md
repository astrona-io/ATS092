# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Event Listeners

## Scenario

The security team asked for one log line for every successful sign-in to the realm `inventory`, in this exact format:

```
AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice
```

A developer wrote the event listener `audit-log` for it. It is built, and Keycloak in the namespace `events-demo` has loaded it. Yet when `alice` signs in, no `AUDIT-LOG` line appears. The listener's source is in the ConfigMap `provider-source`. Each key is a file path with `/` written as `__`.

## Helpers

Paste these into your terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `get_user_token USER PASSWORD` signs a user in through `inventory-cli` with the password grant; it is used only so you can sign in from a terminal, and a real application uses the authorization code flow. `download_source DIR`, `upload_source DIR` and `build_provider` move the source in and out of the ConfigMap and build it.

```sh
NAMESPACE=events-demo

# kcadm runs kcadm.sh inside the Keycloak pod. It signs in to the realm
# master as the lab-only administrator on every call, so it keeps working
# after Keycloak restarts.
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}
```

```sh
# get_user_token USER PASSWORD: signs the user in through inventory-cli with
# the password grant and prints the access token, or the error. The password
# grant is used only to sign in from a terminal.
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      --data-urlencode username="$1" --data-urlencode password="$2" \
    | jq -r ".access_token // .error_description // .error"' sh "$1" "$2"
}
```

```sh
# download_source DIR: writes every file of the ConfigMap provider-source
# into DIR, turning "__" in each key back into "/".
download_source() {
  local target_dir="$1" key file
  kubectl -n "$NAMESPACE" get configmap provider-source \
    -o go-template='{{range $key, $value := .data}}{{$key}}{{"\n"}}{{end}}' |
  while IFS= read -r key; do
    file="$target_dir/$(printf '%s' "$key" | sed 's|__|/|g')"
    mkdir -p "$(dirname "$file")"
    kubectl -n "$NAMESPACE" get configmap provider-source \
      -o go-template="{{index .data \"$key\"}}" > "$file"
  done
}
```

```sh
NAMESPACE=events-demo

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

# build_provider: runs the build Job from the ConfigMap build-provider-job,
# prints its log, and restarts Keycloak so it loads the new JAR.
build_provider() {
  kubectl -n "$NAMESPACE" delete job build-provider --ignore-not-found
  kubectl -n "$NAMESPACE" get configmap build-provider-job -o jsonpath='{.data.job\.yaml}' \
    | kubectl apply -f -
  until [ -n "$(kubectl -n "$NAMESPACE" get job build-provider -o jsonpath='{.status.succeeded}{.status.failed}')" ]; do
    sleep 5
  done
  kubectl -n "$NAMESPACE" logs job/build-provider
  if [ "$(kubectl -n "$NAMESPACE" get job build-provider -o jsonpath='{.status.succeeded}')" != "1" ]; then
    echo "The build failed. Read the log above."
    return 1
  fi
  kubectl -n "$NAMESPACE" rollout restart deployment/keycloak
  kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=10m
}
```

## Your task

In the namespace `events-demo` and the realm `inventory`:

1. Find every reason why a sign-in by `alice` (password `alice-password`) produces no `AUDIT-LOG` line.
2. Fix them, so that each successful sign-in through `inventory-cli` writes the line above.
3. Prove it with a real sign-in and the Keycloak log.

## Constraints

- Keep the provider id `audit-log` and the line format exactly as shown.
- The realm must keep the built-in listener `jboss-logging` as well.
- Build with the build Job. Do not change the `keycloak` Deployment.

## Done when

- The realm `inventory` lists both `jboss-logging` and `audit-log` as event listeners.
- A sign-in by `alice` through `inventory-cli` writes `AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice` to the Keycloak log.
