# Solution: Ship A Theme And A Listener In One JAR

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks six things: Keycloak is ready, the theme comes from the one JAR, the realm uses the theme, the login page shows the heading, both listeners are listed, and a sign-in writes the audit line.

## Step 1: Ask Keycloak what it found in the JAR

Paste the helpers from the task page. Then list the login themes and the event listeners Keycloak loaded:

```sh
kcadm get serverinfo | jq '.themes.login | map(.name)'
kcadm get serverinfo | jq '.providers.eventsListener.providers | keys'
login_page_title
```

The login themes include no `inventory`, and the listeners include no `audit-log`. The heading is Keycloak's default. Both halves of the JAR are invisible, so check each half's registration on its own.

## Step 2: Check the theme descriptor

```sh
download_source extensions
cat extensions/src/main/resources/META-INF/keycloak-themes.json
find extensions/src/main/resources/theme -type f
```

The descriptor names the theme `inventory-theme`, but its files live under `theme/inventory/`. Keycloak looks for the files under `theme/<name>/`, so the name must be `inventory`, both for the folder and for the realm setting.

## Step 3: Check the listener's registration

```sh
find extensions/src/main/resources/META-INF -type f
find extensions/src/main/java -name '*Factory.java'
```

The JAR has the factory `AuditLogEventListenerProviderFactory`, but no file under `META-INF/services/`. Without `META-INF/services/org.keycloak.events.EventListenerProviderFactory`, Keycloak never sees the factory.

## Step 4: Fix both, build once

Change `"name": "inventory-theme"` to `"name": "inventory"` in `keycloak-themes.json` with your editor. Then add the services file and build:

```sh
mkdir -p extensions/src/main/resources/META-INF/services
printf 'io.astrona.keycloak.inventory.AuditLogEventListenerProviderFactory\n' \
  > extensions/src/main/resources/META-INF/services/org.keycloak.events.EventListenerProviderFactory
upload_source extensions
build_provider
```

`build_provider` replaces the JAR in the providers volume and restarts Keycloak, which reads the descriptor and the services file when it starts.

## Step 5: Turn the listener on for the realm

The realm already selects the theme `inventory`. It still has to list the listener, next to `jboss-logging`:

```sh
kcadm update events/config -r inventory -s 'eventsListeners=["jboss-logging","audit-log"]'
```

## Step 6: Prove both parts

```sh
login_page_title
get_user_token alice alice-password
kubectl -n themescapstone-demo logs deploy/keycloak --since=1m | grep AUDIT-LOG
kubectl -n themescapstone-demo exec deploy/keycloak -- ls /opt/keycloak/providers
```

The heading is `Sign in to Inventory`, the log has `AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice`, and the providers directory holds one JAR.

## Step 7: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Mount the theme as a directory from a ConfigMap | The heading appears, but the theme no longer ships in the JAR; the grader checks for theme mounts |
| Rename the folder to `theme/inventory-theme/` | The theme loads as `inventory-theme`, but the realm selects `inventory`, and the task keeps that name |
| Turn on the listener in the realm before the services file exists | Keycloak does not know `audit-log`, so the change cannot work |
| Build the listener as a second JAR | Both parts work, but the task requires one JAR |

## Common mistakes

- Checking only the theme. One JAR can fail in two independent ways; check the theme list and the provider list.
- Forgetting `upload_source` after the edits. The Job builds the ConfigMap, not your folder.
- Setting `eventsListeners` to only `audit-log`. The list is replaced; keep `jboss-logging`.
