# Overview: Email And Account Themes (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Keycloak and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`themes-demo`** with **Keycloak 26.8.1** in development mode, which does not cache themes and templates. The lab-only administrator is `admin` / `admin`.
- The realm **`inventory`** with the user `alice` (password `alice-password`), the public client `inventory-cli`, and the public client `inventory-web`. The realm uses the default themes and has no outgoing mail server.
- The PVC **`keycloak-providers`**, empty at the start, and the PVC **`maven-cache`**.
- The `tester` pod, with `curl` and `jq`.

## Helpers

Paste this once in each new terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator.

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

Use it like this: `kcadm get serverinfo | jq '.themes.email | map(.name)'`.

## Practice tasks

- List the themes of the types `email` and `account` that Keycloak knows.
- Create an email theme `inventory` with `parent=base` and a changed `passwordResetSubject`, mount it from a ConfigMap, and select it with `kcadm update realms/inventory -s emailTheme=inventory`.
- Add the template `email/html/password-reset.ftl` and the matching `email/text/password-reset.ftl` to the same theme.
- Create an account theme with `parent=keycloak.v3`, select it with `accountTheme`, and open the account console of the realm from the `tester` pod to see that the page is served.
- Turn on `internationalizationEnabled`, add a second locale to `supportedLocales`, and add a message file for it to the theme.
