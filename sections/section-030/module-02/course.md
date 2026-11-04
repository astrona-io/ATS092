# Store, Query And Expire Keycloak Events

The security team can read the server log, but the log is not a good place to search. They need to ask Keycloak itself: which sign-ins failed for `alice` today, which client was changed yesterday, and who changed it. Keycloak can answer, if the realm stores its events and keeps them for a defined time.

The **event store** is the part of Keycloak that saves events in its database. It is a different thing from an event listener. A listener receives each event once, at the moment it happens. The store keeps an event so that you can read it later through the Admin REST API (the HTTP interface that `kcadm.sh` and the admin console use). This module sets up the store for the realm `inventory`, reads from it with filters, and removes old events.

Keep one sentence in mind: **a realm stores only the event types it lists, and it keeps them until they expire or someone deletes them.** An event of a type that is not on the list is sent to the listeners and then forgotten.

The module has four parts. **What The Event Store Holds** reads the realm's event configuration and separates storing from listening. **Choosing What To Store** turns on the event types and admin event details that the team needs. **Querying Stored Events** reads events with filters for type, user, client, date and resource. A graded lab follows the third part. **Expiring And Clearing Events** sets the lifetime of events and deletes them.

## Learning objectives

After this module you can:

- Explain the difference between storing events and sending them to a listener.
- Read and change the fields of a realm's event configuration with `kcadm.sh`.
- Choose which user event types a realm stores, and turn on admin events with details.
- Query user events and admin events with filters.
- Set the expiration of stored events, and delete stored events.

## Before you start

You need Kubernetes basics and `kubectl exec`. You should know what a user event and an admin event are, and be able to read JSON. You do not need Java or Maven.

Your playground is a single-node `kind` cluster in the namespace **`events-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode, with the lab-only administrator `admin` / `admin` |
| realm `inventory` | The user `alice` (password `alice-password`) and the public client `inventory-cli` with direct access grants on. The realm stores no events at the start |
| `tester` | A client pod with `curl` and `jq` |

The pages sign `alice` in with the password grant through `inventory-cli`, because that works from a terminal and produces real events. OAuth 2.1 drops the password grant, and a real application uses the authorization code flow. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

The commands in the parts use two helpers. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `get_user_token USER PASSWORD` signs a user in. Paste them once in each new terminal:

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
