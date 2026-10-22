# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Themes With FreeMarker

## Scenario

The `inventory` team wants its login page to say who it belongs to. Today the realm `inventory` in the namespace `themes-demo` shows Keycloak's default login page, with the heading `Sign in to your account`. The team wants the heading `Sign in to Inventory`, and everything else on the page unchanged.

The team does not want a build for this. The theme must be a directory that comes from a ConfigMap, so they can change the text later without a new JAR.

## Helpers

Paste these into your terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `login_page_title` fetches the login page of the realm `inventory` from the `tester` pod, through the client `inventory-web`, and prints its heading.

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

## Your task

In the namespace `themes-demo`:

1. Create a login theme named `inventory` that inherits from the theme `keycloak` and changes only the heading to `Sign in to Inventory`.
2. Store the theme's files in a ConfigMap named `inventory-theme`, and mount it into the `keycloak` container so the theme lives at `/opt/keycloak/themes/inventory`.
3. Make the realm `inventory` use the theme for its login pages, and prove the heading with `login_page_title`.

## Constraints

- Override the message that prints the heading. Do not copy or change a template.
- Keep everything else in the `keycloak` Deployment as it is, including the providers volume.
- Do not build a JAR for the theme.

## Done when

- The `keycloak` container mounts a volume at `/opt/keycloak/themes/inventory`, and Keycloak is running and ready.
- The realm `inventory` uses the login theme `inventory`.
- The login page of the realm `inventory` shows `Sign in to Inventory`.
