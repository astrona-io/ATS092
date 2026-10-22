# Solution: Log Every Login With A Custom Listener

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the realm lists both listeners, and a sign-in by `alice` writes the expected line.

## Step 1: Confirm the listener is loaded

Paste the helpers from the task page. Then check the server info and the realm's event configuration:

```sh
kcadm get serverinfo | jq '.providers.eventsListener.providers | keys'
kcadm get events/config -r inventory --fields eventsListeners
```

Keycloak lists `audit-log`, so it loaded the JAR. The realm lists only `jboss-logging`. That is the first reason: no event of the realm reaches `audit-log`.

## Step 2: Turn the listener on, and test

```sh
kcadm update events/config -r inventory -s 'eventsListeners=["jboss-logging","audit-log"]'
get_user_token alice alice-password
kubectl -n events-demo logs deploy/keycloak --since=1m | grep AUDIT-LOG
```

The sign-in works, and still no `AUDIT-LOG` line appears. The listener now receives the `LOGIN` event and decides to write nothing, so the second reason is in the code.

## Step 3: Read the code

```sh
download_source audit-log
grep -n 'EventType' audit-log/src/main/java/io/astrona/keycloak/inventory/AuditLogEventListenerProvider.java
```

The first line of `onEvent(Event event)` reads `if (event.getType() != EventType.REGISTER) { return; }`. The listener only writes `REGISTER` events, which Keycloak sends when a user creates their own account. A sign-in is `LOGIN`.

## Step 4: Fix the event type and build

Change `EventType.REGISTER` to `EventType.LOGIN` in that line with your editor. Then upload and build:

```sh
upload_source audit-log
build_provider
```

`build_provider` restarts Keycloak, which loads the corrected JAR. The realm's event configuration is realm data, so it survives the restart.

## Step 5: Prove the fix

```sh
get_user_token alice alice-password
kubectl -n events-demo logs deploy/keycloak --since=1m | grep AUDIT-LOG
```

The log has `AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set the realm's listeners to `["audit-log"]` only | The line appears, but failed sign-ins are no longer logged by `jboss-logging`; the grader checks both |
| Fix only the realm configuration | The listener receives `LOGIN` and still writes nothing |
| Fix only the code | The listener writes `LOGIN` lines, but no realm sends it any event |
| Raise the log level of `jboss-logging` | Successful sign-ins appear, but in another format; the team's tools search for `AUDIT-LOG` |

## Common mistakes

- Stopping after the first fix. A loaded listener that receives events and writes nothing points at the code.
- Testing with a wrong password. That sends `LOGIN_ERROR`, which this listener ignores on purpose.
- Restarting Keycloak after changing the event configuration and thinking the restart fixed it. Only the JAR needs a restart.
