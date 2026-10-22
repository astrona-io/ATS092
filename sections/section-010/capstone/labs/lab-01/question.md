# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Service Provider Interfaces

## Scenario

The `inventory` team wants a status endpoint in Keycloak: `GET /realms/inventory/inventory-status` should answer `inventory-status ok realm=inventory`. A colleague wrote the provider and ran the build Job once before going on leave. The build failed, and nobody has looked at it since.

The source is in the ConfigMap `provider-source` in the namespace `spicapstone-demo`. Each key is a file path with `/` written as `__`. Keycloak is running, without the provider.

## Helpers

Paste these into your terminal. They work as the module described: `kcadm`, `download_source DIR`, `upload_source DIR` and `build_provider`.

```sh
NAMESPACE=spicapstone-demo

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
NAMESPACE=spicapstone-demo

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

In the namespace `spicapstone-demo`, get the `inventory-status` provider built, loaded and answering. There is more than one fault, and the second one only shows itself once the first is fixed. Use the logs to find each one.

## Constraints

- Keep the provider id `inventory-status`, the package `io.astrona.keycloak.inventory` and the class names.
- Build with the build Job. Do not change the `keycloak` Deployment.
- Fix the source; do not remove the provider to make Keycloak start.

## Done when

- The last run of the Job `build-provider` succeeded.
- Keycloak is running and ready.
- `kcadm get serverinfo` lists `inventory-status` under `realm-restapi-extension`.
- `GET http://keycloak:8080/realms/inventory/inventory-status` from the `tester` pod returns `inventory-status ok realm=inventory`.
