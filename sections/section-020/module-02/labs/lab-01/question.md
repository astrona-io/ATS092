# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Required actions

## Scenario

The `outpost` crew must accept the terms of use before they use the inventory. A colleague wrote the required action `accept-terms`, built it and put the JAR in Keycloak's providers directory. Keycloak starts without an error, but the action does not show up. The source is in the ConfigMap `provider-source` in the namespace `actions-demo`. Each key is a file path with `/` written as `__`.

Make the action work: the server must load it, the realm `inventory` must have it registered and enabled, and the user `bob` must have it in the list of required actions.

## Helpers

```sh
NAMESPACE=actions-demo

# kcadm runs kcadm.sh inside the Keycloak pod as the lab-only administrator.
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}
```

`download_source DIR`, `upload_source DIR` and `build_provider` work as in the playground: they move the source between the ConfigMap and a folder, and build it and restart Keycloak. The definitions are the same as in the playground overview.

## Requirements

- Keycloak is running and ready.
- The server info lists `accept-terms` under the SPI `required-action`.
- The realm `inventory` has the required action `accept-terms`, enabled.
- The user `bob` has `accept-terms` in `requiredActions`. The user `alice` is unchanged.

## Hints

- A JAR in the directory and a clean start do not prove the factory was found.
- A required action that Keycloak loaded is still unregistered in the realm.
