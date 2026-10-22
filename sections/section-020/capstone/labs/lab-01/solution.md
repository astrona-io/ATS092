# Solution: Fix An Authenticator That Blocks The Wrong Users

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the flow is bound to `inventory-cli` only with the step `REQUIRED`, `alice` gets a token, `bob` is refused, `inventory-report-cli` is not affected, and the users' departments are unchanged.

## Step 1: Reproduce the complaints

Paste the helpers from the task page. Then sign in as both users through `inventory-cli`, and as `bob` through the second client:

```sh
get_user_token alice alice-password
get_user_token bob bob-password
kubectl -n authcapstone-demo exec deploy/tester -- sh -c '
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-report-cli \
    -d username=bob -d password=bob-password | jq -r ".access_token // .error_description"'
```

Through `inventory-cli`, `alice` gets the authenticator's error message and `bob` gets a token: the exact opposite of the rule. Through `inventory-report-cli`, `alice` would be refused as well, because the same rule runs there. Two kinds of symptom, so expect two causes: one decides *who* is refused, the other decides *where* the rule runs.

## Step 2: Find where the flow runs

```sh
kcadm get realms/inventory --fields directGrantFlow
CLIENT_ID="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes)"
kcadm get "clients/$CLIENT_ID" -r inventory --fields authenticationFlowBindingOverrides
```

The realm binds `direct-grant-with-department` as its direct grant flow, and `inventory-cli` has no override. So every client in the realm runs the department check, including `inventory-report-cli`. The rule was meant for `inventory-cli` only.

## Step 3: Find why the wrong user is refused

The step runs for every client, and it refuses the user who has a department. Read the check in the code:

```sh
download_source department-check
grep -n 'value' department-check/src/main/java/io/astrona/keycloak/inventory/RequireDepartmentAuthenticator.java
```

The condition before `context.failure(...)` reads `if (value != null && !value.isBlank())`: it fails the flow when the user **has** a department. The check is inverted.

## Step 4: Fix the code

Change the condition to `if (value == null || value.isBlank())` with your editor, then upload and build:

```sh
upload_source department-check
build_provider
```

`build_provider` restarts Keycloak, which loads the corrected JAR.

## Step 5: Fix the binding

Put the realm's binding back to the built-in flow, and bind the copy to `inventory-cli` only:

```sh
kcadm update realms/inventory -s "directGrantFlow=direct grant"
FLOW_ID="$(kcadm get authentication/flows -r inventory --fields id,alias --format csv --noquotes \
  | awk -F, '$2=="direct-grant-with-department"{print $1}')"
kcadm update "clients/$CLIENT_ID" -r inventory -s "authenticationFlowBindingOverrides.direct_grant=$FLOW_ID"
```

## Step 6: Prove the fix

Run the three sign-ins from step 1 again. Through `inventory-cli`, `alice` gets a token and `bob` gets the error. Through `inventory-report-cli`, `bob` gets a token, because that client now uses the realm's `direct grant` flow without the department check.

## Step 7: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Give `bob` a department and remove `alice`'s | The inverted code now lets `alice` in and refuses `bob`, but the bug stays for every other user; the grader rejects changed users |
| Set the step to `DISABLED` | Nobody is refused anywhere; the rule is gone |
| Fix only the code | `inventory-cli` behaves, but `inventory-report-cli` still refuses users without a department |
| Fix only the binding | `inventory-report-cli` behaves, but `inventory-cli` still refuses `alice` and lets `bob` in |

## Common mistakes

- Treating opposite symptoms as one fault. "The wrong user is refused" and "the rule runs in the wrong place" have different causes.
- Editing the source and forgetting `upload_source`. The Job builds the ConfigMap, not your folder.
- Using the flow's alias in `authenticationFlowBindingOverrides`. It needs the flow's id.
