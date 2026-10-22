# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Custom Authenticators

## Scenario

The `inventory` team has a new rule: only users with a department may sign in to the command-line client `inventory-cli`. A developer already wrote the authenticator `require-department-attribute`, built it, and loaded it into Keycloak in the namespace `authenticator-demo`. Nobody has put it into a flow yet, so today every user with a valid password gets a token.

The realm `inventory` holds two users with complete profiles:

| User | Password | `department` |
| --- | --- | --- |
| `alice` | `alice-password` | `warehouse` |
| `bob` | `bob-password` | none |

## Helpers

Paste these into your terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `get_user_token USER PASSWORD` signs a user in through `inventory-cli` with the password grant and prints the access token or the error. The password grant is used here only to sign in from a terminal; OAuth 2.1 drops it, and a real application uses the authorization code flow.

```sh
NAMESPACE=authenticator-demo

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

In the realm `inventory`:

1. Create the flow `direct-grant-with-department`: a copy of the built-in `direct grant` flow with one more step that runs `require-department-attribute` as `REQUIRED`.
2. Make `inventory-cli` use this flow for the direct grant.
3. Prove the rule: `alice` gets a token through `inventory-cli`, and `bob` is refused.

## Constraints

- The realm's own direct grant binding must stay `direct grant`. Only `inventory-cli` uses the new flow.
- Do not change the built-in `direct grant` flow.
- Do not change, disable or delete `bob`, and do not change his password. The flow must refuse him.

## Done when

- The flow `direct-grant-with-department` has the step `require-department-attribute` with the requirement `REQUIRED`.
- `inventory-cli` overrides the direct grant flow with `direct-grant-with-department`, and the realm still binds `direct grant`.
- `alice` gets an access token through `inventory-cli`, and `bob` gets none.
