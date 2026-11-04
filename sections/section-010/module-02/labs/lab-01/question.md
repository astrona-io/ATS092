# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Provider configuration

## Scenario

The `inventory-status` provider of the `outpost` stores is built and loaded. Its factory reads the setting `mode` and the endpoint reports it: the answer ends with `mode=<value>`. The outpost team set the mode to `audit` in the Deployment, yet the endpoint still answers `mode=standard`.

```sh
kubectl -n config-demo exec deploy/tester -- curl -s http://keycloak:8080/realms/inventory/inventory-status
```

Make the endpoint answer `inventory-status ok realm=inventory mode=audit`. Do not change the Java source and do not rebuild the JAR.

## Helpers

```sh
NAMESPACE=config-demo

# kcadm runs kcadm.sh inside the Keycloak pod as the lab-only administrator.
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}
```

## Requirements

- Keycloak is running and ready.
- The server info lists the provider `inventory-status`.
- The endpoint answers with `mode=audit`.
- The setting reaches Keycloak through the environment of the Deployment, with its correct name, and the wrong variable is gone.

## Hints

- Look at the environment names of the Deployment, and at the SPI name and provider id in the server info.
- A changed environment makes Kubernetes start a new pod. Wait for it before you test.
