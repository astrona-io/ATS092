# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Event Listeners

## Scenario

The security team wants to search the failed sign-ins of the realm `inventory` for the last 24 hours. They also want to see who changed a client, and what the change was. A developer turned event storing on in a hurry. The realm in the namespace `events-demo` stores events, but a failed sign-in by `alice` is not found, nothing limits how long events stay in the database, and changes made through the Admin REST API are not recorded.

## Helpers

Paste these into your terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `get_user_token USER PASSWORD` signs a user in through `inventory-cli` with the password grant; it is used only so you can sign in from a terminal, and a real application uses the authorization code flow.

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

## Your task

In the namespace `events-demo` and the realm `inventory`:

1. Read the realm's event configuration and find why a failed sign-in is not stored.
2. Store the user event types `LOGIN` and `LOGIN_ERROR`, and delete stored user events after 24 hours (86400 seconds).
3. Store admin events together with the representation of each change.
4. Prove it: sign in with a wrong password, and read the stored `LOGIN_ERROR` event. Update the description of the client `inventory-cli`, and read the stored admin event.

## Constraints

- Keep the built-in listener `jboss-logging` in the realm's listeners.
- Use `kcadm.sh` only. Do not change the `keycloak` Deployment, and do not restart Keycloak.

## Done when

- The realm stores `LOGIN` and `LOGIN_ERROR` events and sets `eventsExpiration` to 86400.
- The realm stores admin events with their details.
- A failed sign-in by `alice` appears with `kcadm get events -r inventory -q type=LOGIN_ERROR`.
- An update of a client appears with `kcadm get admin-events -r inventory -q resourceTypes=CLIENT`.
