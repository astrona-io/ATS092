# Overview: Change The Login Page With A Theme (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Keycloak and the build setup, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`themes-demo`** with **Keycloak 26.8.1** in development mode, which does not cache themes and templates. The lab-only administrator is `admin` / `admin`.
- The realm **`inventory`** with the user `alice` (password `alice-password`), the public client `inventory-cli`, and the public client `inventory-web` with the standard flow and the redirect URI `http://localhost/*`. The realm uses the default login theme.
- The PVC **`keycloak-providers`**, empty at the start, the PVC **`maven-cache`**, already filled, and the ConfigMap **`build-provider-job`** with the build Job's definition.
- The `tester` pod, with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `login_page_title` fetches the login page of the realm `inventory` from the `tester` pod and prints its heading. `upload_source DIR`, `download_source DIR` and `build_provider` move source in and out of the ConfigMap `provider-source` and build it.

```sh
NAMESPACE=themes-demo

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
# login_page_title: fetches the login page of the realm inventory from the
# tester pod, through the client inventory-web, and prints its heading.
login_page_title() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    'http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Flocalhost%2Fcallback' \
  | grep -o 'Sign in to[^<]*' | head -n 1
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
NAMESPACE=themes-demo

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

Use them like this: `login_page_title`, `kcadm get serverinfo | jq '.themes.login | map(.name)'`.

## Practice tasks

- Find the message key for the "Username or email" label on the login page, and override it in your `inventory` theme.
- Add a German message file, `messages_de.properties`, to the ConfigMap and its `items`, and fetch the login page with the header `Accept-Language: de`.
- Change the text in the ConfigMap with `kubectl edit`, and time how long it takes until `login_page_title` shows it.
- Set the realm's login theme to a name that does not exist and see what the login page shows. Put it back.
- Build the theme JAR, then select `keycloak.v2`, `keycloak` and your themes in turn, and compare the headings.
