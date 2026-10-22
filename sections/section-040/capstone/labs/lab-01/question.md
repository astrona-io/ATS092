# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Themes With FreeMarker

## Scenario

The `inventory` team ships its Keycloak extensions as one JAR: the login theme `inventory`, which changes the heading to `Sign in to Inventory`, and the event listener `audit-log`, which writes one line for every successful sign-in:

```
AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice
```

In the namespace `themescapstone-demo`, the JAR builds and Keycloak starts. The realm `inventory` already selects the login theme `inventory`. Yet the login page still shows Keycloak's default heading, and the realm cannot use the listener. The JAR's source is in the ConfigMap `provider-source`. Each key is a file path with `/` written as `__`.

## Helpers

Paste these into your terminal. They work as the module described: `kcadm`, `login_page_title`, `get_user_token USER PASSWORD`, `download_source DIR`, `upload_source DIR` and `build_provider`. The password grant in `get_user_token` is used only so you can sign in from a terminal; a real application uses the authorization code flow.

```sh
NAMESPACE=themescapstone-demo

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
NAMESPACE=themescapstone-demo

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

In the namespace `themescapstone-demo`, make the one JAR deliver both parts: the login page shows `Sign in to Inventory`, and a sign-in by `alice` (password `alice-password`) through `inventory-cli` writes the `AUDIT-LOG` line. Find each fault from what Keycloak lists and logs.

## Constraints

- Keep both parts in the one JAR. Do not mount a theme directory, and do not build a second JAR.
- Keep the theme name `inventory`, the provider id `audit-log` and the line format.
- The realm must keep the built-in listener `jboss-logging` as well.

## Done when

- The providers directory holds exactly one JAR, and no theme directory is mounted under `/opt/keycloak/themes`.
- The realm `inventory` uses the login theme `inventory`, and its login page shows `Sign in to Inventory`.
- The realm lists both `jboss-logging` and `audit-log`, and a sign-in by `alice` writes the `AUDIT-LOG type=LOGIN` line.
