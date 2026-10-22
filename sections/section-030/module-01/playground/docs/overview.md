# Overview: Send Keycloak Events To Your Own Listener (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Keycloak and the build setup, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`events-demo`** with **Keycloak 26.8.1** in development mode. The lab-only administrator is `admin` / `admin`.
- The realm **`inventory`** with the user `alice` (password `alice-password`) and the public client `inventory-cli` with direct access grants on. Its only event listener is `jboss-logging`.
- The PVC **`keycloak-providers`**, empty at the start, mounted read-only at `/opt/keycloak/providers`.
- The PVC **`maven-cache`**, already filled, and the ConfigMap **`build-provider-job`** with the build Job's definition.
- The `tester` pod, with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `get_user_token USER PASSWORD` signs a user in through `inventory-cli` with the password grant; it is used only so you can sign in from a terminal, and a real application uses the authorization code flow. `upload_source DIR`, `download_source DIR` and `build_provider` move source in and out of the ConfigMap `provider-source` and build it.

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

Use them like this: `get_user_token alice alice-password`, then `kubectl -n events-demo logs deploy/keycloak --since=1m`.

## Practice tasks

- Sign in with a wrong password and find the `LOGIN_ERROR` warning that `jboss-logging` writes. Name every field it contains.
- After you build `audit-log`, change it to also write `LOGIN_ERROR` events with the error, rebuild, and test with a wrong password.
- Set the realm's listeners to only `audit-log`, sign in with a wrong password, and see what is missing from the log. Put `jboss-logging` back.
- Turn admin events on, update a client's description with `kcadm update`, and read the `AUDIT-LOG admin` line for the `UPDATE` operation.
- Turn `eventsEnabled` on and read the saved user events with `kcadm get events -r inventory`.
