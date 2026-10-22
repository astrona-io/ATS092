# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Custom Authenticators

## Scenario

The department check for `inventory-cli` went live last week in the namespace `authcapstone-demo`. Since then the help desk has three complaints. `alice`, who works in the warehouse, cannot sign in to `inventory-cli`. `bob`, who has no department, signs in to `inventory-cli` without a problem. And the reporting team says their own command-line client, `inventory-report-cli`, suddenly refuses some users too, although nobody asked for a rule there.

The authenticator `require-department-attribute` is built, loaded, and a step of the flow `direct-grant-with-department`. Its source is in the ConfigMap `provider-source`. Each key is a file path with `/` written as `__`.

| User | Password | `department` |
| --- | --- | --- |
| `alice` | `alice-password` | `warehouse` |
| `bob` | `bob-password` | none |

## Helpers

Paste these into your terminal. They work as the module described: `kcadm`, `get_user_token USER PASSWORD` (through `inventory-cli`), `download_source DIR`, `upload_source DIR` and `build_provider`. The password grant is used here only to sign in from a terminal; a real application uses the authorization code flow.

```sh
NAMESPACE=authcapstone-demo

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
NAMESPACE=authcapstone-demo

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

In the realm `inventory`, make the department check do what it was meant to do, for the client it was meant for. There is one fault in the code and one fault in how the flow is bound.

## Constraints

- Do not change the users to fit the code: `alice` keeps `department` = `warehouse`, and `bob` gets no department.
- Do not change, disable or delete `bob`, and do not change his password.
- Keep the flow `direct-grant-with-department` with the step `require-department-attribute` as `REQUIRED`.

## Done when

- Through `inventory-cli`, `alice` gets an access token and `bob` gets none.
- Through `inventory-report-cli`, `bob` gets an access token: the rule does not apply there.
- The realm's own direct grant binding is `direct grant`, and `inventory-cli` overrides it with `direct-grant-with-department`.
