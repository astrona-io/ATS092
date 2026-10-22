# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Event Listeners

## Scenario

The `audit-log` listener has written one line per sign-in in the namespace `eventscapstone-demo` for a while. Now the audit team also wants every administrator change in the realm `inventory` in the log, in this format, followed by the resource path:

```
AUDIT-LOG admin operation=CREATE resourceType=USER realm=inventory
```

Someone changed the realm's event settings in a hurry last night, and the help desk says that failed sign-ins no longer show up in the server log either. The listener's source is in the ConfigMap `provider-source`. Each key is a file path with `/` written as `__`.

## Helpers

Paste these into your terminal. They work as the module described: `kcadm`, `get_user_token USER PASSWORD`, `download_source DIR`, `upload_source DIR` and `build_provider`. The password grant is used here only to sign in from a terminal; a real application uses the authorization code flow.

```sh
NAMESPACE=eventscapstone-demo

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
NAMESPACE=eventscapstone-demo

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

In the namespace `eventscapstone-demo` and the realm `inventory`, make the audit work for both kinds of event, and restore the logging of failed sign-ins:

1. A change made through the Admin REST API, such as creating a user, writes an `AUDIT-LOG admin` line in the format above.
2. A successful sign-in by `alice` still writes `AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice`.
3. The realm saves admin events with their details, as the audit team's policy requires.

## Constraints

- Keep the provider id `audit-log` and both line formats exactly as shown.
- Build with the build Job. Do not change the `keycloak` Deployment.

## Done when

- The realm `inventory` lists both `jboss-logging` and `audit-log` as event listeners.
- The realm saves admin events and admin event details.
- Creating a user in `inventory` with `kcadm` writes a line that starts with `AUDIT-LOG admin operation=CREATE resourceType=USER realm=inventory`.
- A sign-in by `alice` writes the `AUDIT-LOG type=LOGIN` line.
