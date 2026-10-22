# Overview: Build And Load Your First Keycloak Provider (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Keycloak and the build setup, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`spi-demo`** with **Keycloak 26.8.1** in development mode (`start-dev`). The realm `inventory` holds the user `alice` and the client `inventory-cli`. The lab-only administrator is `admin` / `admin`.
- The PVC **`keycloak-providers`**, mounted read-only at `/opt/keycloak/providers` in the Keycloak pod. It is empty at the start.
- The PVC **`maven-cache`**, already filled with the Keycloak 26.8.1 artifacts, so a build does not wait for downloads.
- The ConfigMap **`build-provider-job`**, which holds the definition of the build Job. The Job reads source files from the ConfigMap `provider-source` (each key is a file path with `/` written as `__`), runs Maven, and writes the JAR into `keycloak-providers`.
- The `tester` pod, with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `upload_source DIR` stores a folder in the ConfigMap `provider-source`, `download_source DIR` writes it back to a folder, and `build_provider` runs the build Job and restarts Keycloak.

```sh
NAMESPACE=spi-demo

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
NAMESPACE=spi-demo

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

Use them like this: `kcadm get serverinfo | jq '.providers | keys'`, `upload_source inventory-status`, `build_provider`.

## Practice tasks

- List the providers of the SPI `eventsListener` and of the SPI `authenticator`. Pick one built-in provider id and find it in the server info.
- After you build `inventory-status`, rename its services file to `...RealmResourceProvider`, rebuild, and compare the server info and the log with a working build.
- Change the class name inside the services file to one that does not exist, rebuild, and read `kubectl -n spi-demo logs deploy/keycloak --previous`. Put it back afterwards.
- Change the text the endpoint returns, rebuild, and confirm that the new text appears only after Keycloak restarts.
- Call the endpoint in the realm `master` and explain why it answers there too.
