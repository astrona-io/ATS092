# Authentication Flows, Executions And Requirements

Before you add a step to a sign-in, you need to see the sign-in Keycloak already runs. Every way into a realm, from the browser login to a token request from a terminal, runs one authentication flow. This part reads the realm's flows, the flow behind the password grant, and the rules that decide whether a step's result counts.

## The realm's flows and bindings

An authentication flow is an ordered list of steps that Keycloak runs to sign a user in. A realm comes with several built-in flows, and it **binds** some of them to a purpose: one flow for browser logins, one for direct grants, one for client authentication, and a few more. A direct grant is a token request where the client sends the user's password itself, the password grant.

Paste the helpers first. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. `get_user_token` signs a user in with the password grant through `inventory-cli` and prints the access token, or the error Keycloak returns.

<!-- astrona:playground:renew -->

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

List the realm's flows and the two bindings this module cares about:

```sh
kcadm get authentication/flows -r inventory --fields alias,builtIn
kcadm get realms/inventory --fields browserFlow,directGrantFlow
```

The first list holds the built-in flows, such as `browser`, `direct grant`, `registration` and `clients`, each with `builtIn` set to `true`. The second command shows that the realm binds `browser` for browser logins and `direct grant` for direct grants. Note the space in `direct grant`: it is part of the flow's alias.

## The executions of one flow

Each step of a flow is an **execution**. An execution runs one authenticator, or it is a sub-flow that holds more executions. An **authenticator** is the Java code behind a step; Keycloak knows it by its provider id. Read the executions of the direct grant flow. The alias contains a space, so the path writes it as `%20`:

```sh
kcadm get "authentication/flows/direct%20grant/executions" -r inventory \
  --fields displayName,providerId,requirement,level
```

The flow has three top-level steps. The first checks the username (`direct-grant-validate-username`), the second checks the password (`direct-grant-validate-password`), and the third is a sub-flow for a one-time password that runs only under a condition. The steps at `level` 1 belong to that sub-flow.

## Requirements decide what counts

Every execution has a **requirement**, and it decides how the step's result affects the whole flow:

| Requirement | What Keycloak does |
| --- | --- |
| `REQUIRED` | Runs the step; if it fails, the flow fails |
| `ALTERNATIVE` | Runs the step; the level succeeds if this step or another alternative succeeds |
| `CONDITIONAL` | Only for sub-flows: runs them when their condition steps say so |
| `DISABLED` | Does not run the step at all |

A `DISABLED` step is never run, so it can never refuse anyone. That makes `DISABLED` the quietest way to switch a check off, and the first thing to look for when a check "does nothing".

Now see the flow at work. Sign in as both users:

```sh
get_user_token alice alice-password
get_user_token bob bob-password
```

Both commands print a long access token: the direct grant flow checks the username and the password, and both users pass. Nothing in the flow looks at the attribute `department` yet.

## One flow for one client

A realm binds one flow per purpose, so changing the realm's `direct grant` binding changes every client in the realm. A client can instead **override** a binding for itself: the client setting `authenticationFlowBindingOverrides` maps a purpose, such as `direct_grant`, to the id of another flow. Read the overrides of `inventory-cli`:

```sh
CLIENT_ID="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes)"
kcadm get "clients/$CLIENT_ID" -r inventory --fields clientId,authenticationFlowBindingOverrides
```

The overrides are empty, so `inventory-cli` uses the realm's `direct grant` flow. A flow override is how you give one client a stricter sign-in without touching the others.

You can now read a realm's flows, their bindings, the executions of a flow and their requirements, and a client's overrides. The open question is what the Java code behind a step looks like, and how Keycloak learns about a new one.

## Common pitfalls

> [!WARNING]
> - **Changing a built-in flow.** Copy it and change the copy; a built-in flow is shared by every client that uses the binding.
> - **Forgetting the space in `direct grant`.** In a path, write it as `direct%20grant`.
> - **Missing a `DISABLED` step.** It is never run, so a check that is `DISABLED` silently lets everyone through.
> - **Changing the realm binding when one client needs a rule.** Use the client's flow override instead.
