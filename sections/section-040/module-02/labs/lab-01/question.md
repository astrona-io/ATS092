# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Themes With FreeMarker

## Scenario

The `inventory` team wants the password reset email of the realm `inventory` to have the subject `Reset your Inventory password`. A colleague already wrote the email theme and stored its two files in the ConfigMap `inventory-email-theme`, in the namespace `themes-demo`. The ConfigMap is mounted into the `keycloak` container at `/opt/keycloak/themes/inventory`. Yet Keycloak does not list an email theme named `inventory`, and the realm still sends the default subject.

## Helpers

Paste this into your terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator.

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

## Your task

In the namespace `themes-demo`:

1. Find why Keycloak does not list the email theme `inventory`.
2. Fix the mount, so the files are where Keycloak reads an email theme, and wait for Keycloak to start again.
3. Make the realm `inventory` use the email theme, and prove that Keycloak lists it.

## Constraints

- Keep the ConfigMap `inventory-email-theme` and its two keys, `theme.properties` and `messages_en.properties`. Do not copy the files into the image or a new ConfigMap.
- Mount the theme at `/opt/keycloak/themes/inventory`. Do not mount anything at `/opt/keycloak/themes`.
- Do not build a JAR.

## Done when

- The files `/opt/keycloak/themes/inventory/email/theme.properties` and `/opt/keycloak/themes/inventory/email/messages/messages_en.properties` exist in the Keycloak pod.
- `kcadm get serverinfo` lists an email theme named `inventory`.
- The realm `inventory` has the email theme `inventory`.
- The mounted messages file sets `passwordResetSubject=Reset your Inventory password`.
