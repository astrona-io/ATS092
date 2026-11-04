# Overview: Store, Query And Expire Keycloak Events (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Keycloak and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`events-demo`** with **Keycloak 26.8.1** in development mode. The lab-only administrator is `admin` / `admin`.
- The realm **`inventory`** with the user `alice` (password `alice-password`) and the public client `inventory-cli` with direct access grants on. Its only event listener is `jboss-logging`, and it stores no events at the start.
- The `tester` pod, with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `get_user_token USER PASSWORD` signs a user in through `inventory-cli` with the password grant; it is used only so you can sign in from a terminal, and a real application uses the authorization code flow.

```sh
NAMESPACE=events-demo

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

Use them like this: `kcadm get events/config -r inventory`, then `get_user_token alice alice-password`, then `kcadm get events -r inventory`.

## Practice tasks

- Read the realm's event configuration. Name the fields that control user events and the fields that control admin events.
- Turn `eventsEnabled` on with the type list `["LOGIN","LOGIN_ERROR"]`, sign in with a wrong password, and read the stored `LOGIN_ERROR` with its `error` field.
- Query the same events with `-q type=LOGIN_ERROR`, then with `-q user=<alice's id>`, then with `-q max=1`.
- Turn `adminEventsEnabled` and `adminEventsDetailsEnabled` on, update a client's description, and read it with `kcadm get admin-events -r inventory`.
- Set `eventsExpiration` to a small number of seconds, wait for the time to pass, and see what Keycloak does with older events.
- Delete the stored events with `kcadm delete events -r inventory` and read the list again.
