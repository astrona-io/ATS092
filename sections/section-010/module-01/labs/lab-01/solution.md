# Solution: Make Keycloak Load A Provider

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: Keycloak is ready, the server info lists `inventory-status`, and the endpoint returns the provider's text.

## Step 1: Rule out the build and the restart

Paste the helpers from the task page first. Then check that the JAR is in the providers directory, and that Keycloak started cleanly:

```sh
kubectl -n spi-demo exec deploy/keycloak -- ls -l /opt/keycloak/providers
kubectl -n spi-demo get pods -l app=keycloak
```

The JAR `inventory-status-1.0.0.jar` is there, and the Keycloak pod is `Running` and ready, with no restarts. So the build worked, and no class name broke the start.

## Step 2: Ask Keycloak what it loaded

```sh
kcadm get serverinfo | jq '.providers["realm-restapi-extension"].providers | keys'
```

`inventory-status` is not in the list. A JAR in the directory, a clean start and a missing provider point at the services file: Keycloak never found a factory to load.

## Step 3: Read the services file

Download the source and list the registration files:

```sh
download_source inventory-status
find inventory-status/src/main/resources/META-INF -type f
```

The services file is named `org.keycloak.services.resource.RealmResourceProvider`. That is the name of the **provider** interface. `ServiceLoader` looks for a file named after the **factory** interface, `org.keycloak.services.resource.RealmResourceProviderFactory`, so it never opens this one. The class name inside the file is correct.

## Step 4: Rename the file, build and restart

```sh
mv inventory-status/src/main/resources/META-INF/services/org.keycloak.services.resource.RealmResourceProvider \
   inventory-status/src/main/resources/META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory
upload_source inventory-status
build_provider
```

`upload_source` replaces the whole ConfigMap, so the old key with the wrong name is gone. `build_provider` builds the JAR, prints the Job's log and restarts Keycloak, which loads the JAR during its build at start.

## Step 5: Prove the fix

```sh
kcadm get serverinfo | jq '.providers["realm-restapi-extension"].providers | keys'
kubectl -n spi-demo exec deploy/tester -- curl -s http://keycloak:8080/realms/inventory/inventory-status
```

The list now contains `inventory-status`, and the endpoint answers `inventory-status ok realm=inventory`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Restart Keycloak again | Nothing changes; the JAR is the same, and the services file is still ignored |
| Copy the JAR into the pod with `kubectl cp` | The volume is mounted read-only, and the JAR has the same wrong services file |
| Add a second services file and keep the wrong one | It works, but the JAR now carries a file nobody can explain; rename the file instead |

## Common mistakes

- Checking only that the JAR is in the directory. A JAR with a misnamed services file is there and does nothing.
- Renaming the file on your machine and forgetting `upload_source`. The build Job reads the ConfigMap, not your folder.
- Building without restarting Keycloak. The build at start is the only step that loads providers.
