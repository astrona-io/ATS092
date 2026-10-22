# Solution: Audit Admin Changes With A Custom Listener

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: both listeners are listed, admin events are saved with details, creating a user writes the admin line, and a sign-in writes the `LOGIN` line.

## Step 1: Read the realm's event settings

Paste the helpers from the task page. Then read the event configuration:

```sh
kcadm get events/config -r inventory
```

`eventsListeners` holds only `audit-log`: the hurried change replaced the list, so `jboss-logging` is gone, and with it the warnings for failed sign-ins. `adminEventsEnabled` and `adminEventsDetailsEnabled` are `false`.

## Step 2: Restore the listeners and turn on admin events

```sh
kcadm update events/config -r inventory -s 'eventsListeners=["jboss-logging","audit-log"]' \
  -s adminEventsEnabled=true -s adminEventsDetailsEnabled=true
```

Then make an admin change and look for the line:

```sh
kcadm create users -r inventory -s username=dave -s enabled=true \
  -s email=dave@example.com -s firstName=Dave -s lastName=Example
kubectl -n eventscapstone-demo logs deploy/keycloak --since=1m | grep 'AUDIT-LOG admin'
```

Nothing. The realm now records the admin event and hands it to `audit-log`, so the listener itself must ignore it.

## Step 3: Read the admin event method

```sh
download_source audit-log
grep -n -A3 'AdminEvent event' audit-log/src/main/java/io/astrona/keycloak/inventory/AuditLogEventListenerProvider.java
```

`onEvent(AdminEvent event, boolean includeRepresentation)` holds only the comment `// Admin events are not handled yet.` The listener receives admin events and drops them.

## Step 4: Write the admin event method

Replace the body of that method with your editor, so it reads:

```java
    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
        String realmName = event.getRealmName();
        if (realmName == null) {
            RealmModel realm = session.realms().getRealm(event.getRealmId());
            realmName = realm == null ? event.getRealmId() : realm.getName();
        }
        LOG.infof("AUDIT-LOG admin operation=%s resourceType=%s realm=%s path=%s",
                event.getOperationType(), event.getResourceType(), realmName,
                event.getResourcePath());
    }
```

The class already imports `RealmModel` and has the `session` field and the `LOG` logger. Then upload and build:

```sh
upload_source audit-log
build_provider
```

## Step 5: Prove the fix

```sh
kcadm create users -r inventory -s username=erin -s enabled=true \
  -s email=erin@example.com -s firstName=Erin -s lastName=Example
get_user_token alice alice-password
kubectl -n eventscapstone-demo logs deploy/keycloak --since=1m | grep AUDIT-LOG
```

The log has a line that starts with `AUDIT-LOG admin operation=CREATE resourceType=USER realm=inventory` and ends with `path=users/` and the new user's id, and the line `AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice`. A sign-in with a wrong password writes a `LOGIN_ERROR` warning again, because `jboss-logging` is back.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn on admin events only | The realm records them and hands them to `audit-log`, which drops them |
| Write the code only | The listener can write admin lines, but the task also requires the realm to save admin events with details |
| Leave `jboss-logging` out of the list | The audit lines appear, but failed sign-ins are still not logged |
| Read the stored admin events with `kcadm get admin-events` instead | That proves Keycloak saved them, not that the listener writes them |

## Common mistakes

- Creating the test user in the realm `master`. The event belongs to the realm that was changed; create it in `inventory`.
- Forgetting `upload_source` after editing the code. The Job builds the ConfigMap, not your folder.
- Setting `eventsListeners` to only `["jboss-logging"]` while fixing. The list is replaced every time; write both names.
