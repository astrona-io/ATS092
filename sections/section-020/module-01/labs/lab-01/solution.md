# Solution: Require A Department For Password Sign-In

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the flow has the step as `REQUIRED` and is bound to `inventory-cli` only, `alice` gets a token, and `bob` is refused.

## Step 1: Confirm the authenticator is loaded and unused

Paste the helpers from the task page. Then check the server info and sign in as `bob`:

```sh
kcadm get serverinfo | jq '.providers.authenticator.providers | keys | map(select(startswith("require")))'
get_user_token bob bob-password
```

The list contains `require-department-attribute`, so Keycloak loaded it. `bob` still gets a token, because no flow runs the step yet.

## Step 2: Copy the direct grant flow

```sh
kcadm create "authentication/flows/direct%20grant/copy" -r inventory \
  -s newName=direct-grant-with-department
```

The alias of the built-in flow contains a space, written as `%20` in the path.

## Step 3: Add the step and make it required

```sh
kcadm create authentication/flows/direct-grant-with-department/executions/execution -r inventory \
  -s provider=require-department-attribute
EXECUTION_ID="$(kcadm get authentication/flows/direct-grant-with-department/executions -r inventory \
  --fields id,providerId --format csv --noquotes | awk -F, '$2=="require-department-attribute"{print $1}')"
EXECUTION_PRIORITY="$(kcadm get authentication/flows/direct-grant-with-department/executions -r inventory \
  --fields id,priority --format csv --noquotes | awk -F, -v id="$EXECUTION_ID" '$1==id{print $2}')"
kcadm update authentication/flows/direct-grant-with-department/executions -r inventory --no-merge \
  -b "{\"id\":\"$EXECUTION_ID\",\"requirement\":\"REQUIRED\",\"priority\":$EXECUTION_PRIORITY}"
```

The new execution goes to the end of the flow's top level, after the username and password steps, and starts as `DISABLED`. The update sets it to `REQUIRED`.

`--no-merge` replaces the whole execution with the body you send. Keycloak orders the steps of a flow by their `priority`, so the body carries the step's current priority too. Without it, the priority drops to `0`, the step moves before the username and password steps, and every sign-in fails with `unknown_error`: the authenticator runs before Keycloak knows the user. Check it with `kcadm get authentication/flows/direct-grant-with-department/executions -r inventory --fields displayName,requirement`.

## Step 4: Bind the flow to inventory-cli

```sh
FLOW_ID="$(kcadm get authentication/flows -r inventory --fields id,alias --format csv --noquotes \
  | awk -F, '$2=="direct-grant-with-department"{print $1}')"
CLIENT_ID="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes)"
kcadm update "clients/$CLIENT_ID" -r inventory -s "authenticationFlowBindingOverrides.direct_grant=$FLOW_ID"
```

The override takes the flow's id. The realm's `directGrantFlow` stays `direct grant`.

## Step 5: Prove the rule

```sh
get_user_token alice alice-password
get_user_token bob bob-password
kcadm get realms/inventory --fields directGrantFlow
```

`alice` gets an access token. `bob` gets the authenticator's error message instead. The realm still binds `direct grant`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add the step to the built-in `direct grant` flow | Every client in the realm gets the rule, and the built-in flow is no longer the default |
| Set the realm's `directGrantFlow` to the copy | Same result: the rule applies to every client; the grader checks the realm binding |
| Disable `bob` | `bob` is refused for the wrong reason; the grader checks that he is enabled and that his password works |
| Leave the step `DISABLED` | The flow never runs the step, so `bob` still gets a token |

## Common mistakes

- Using the flow's alias in `authenticationFlowBindingOverrides`. It needs the flow's id.
- Forgetting `%20` in `direct%20grant`.
- Testing only `alice`. A rule is proven when the user who should fail does fail.
