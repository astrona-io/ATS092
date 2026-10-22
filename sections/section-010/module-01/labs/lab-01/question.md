# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Service Provider Interfaces

## Scenario

A colleague wrote the `inventory-status` provider: an HTTP endpoint that should answer `GET /realms/inventory/inventory-status` with `inventory-status ok realm=inventory`. The build Job succeeded, the JAR is in Keycloak's providers directory, and Keycloak was restarted after the build. Keycloak starts without an error.

Yet the endpoint answers with HTTP status `404`:

```sh
kubectl -n spi-demo exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:8080/realms/inventory/inventory-status
```

The source of the provider is in the ConfigMap `provider-source` in the namespace `spi-demo`. Each key is a file path with `/` written as `__`.

## Helpers

Paste these into your terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `download_source DIR` writes the source from the ConfigMap into a folder on your machine, and `upload_source DIR` stores a folder back into the ConfigMap. `build_provider` runs the build Job, prints its log and restarts Keycloak.

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

## Your task

In the namespace `spi-demo`:

1. Find out whether Keycloak loaded the provider `inventory-status`, and why not.
2. Fix the source, build it again with the build Job, and make Keycloak load the new JAR.
3. Prove the fix: the provider is listed in the server info, and the endpoint answers.

## Constraints

- Keep the provider id `inventory-status` and the class names as they are.
- Build the JAR with the build Job; do not copy files into the Keycloak pod by hand.
- Do not change the `keycloak` Deployment.

## Done when

- `kcadm get serverinfo` lists the provider `inventory-status` under `realm-restapi-extension`.
- `GET http://keycloak:8080/realms/inventory/inventory-status` from the `tester` pod returns `inventory-status ok realm=inventory`.
- Keycloak is running and ready.
