# Solution: Get A Broken Provider Build Running

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the last build succeeded, Keycloak is ready, the server info lists `inventory-status`, and the endpoint answers.

## Step 1: Read why the build failed

Paste the helpers from the task page. Then read the Job's log:

```sh
kubectl -n spicapstone-demo logs job/build-provider
```

Maven reports a compilation error in `InventoryStatusResource.java`: it cannot find the symbol `GET`. The annotation `@GET` is used, but the class does not import it.

## Step 2: Fix the import

Download the source and look at the imports of the resource class:

```sh
download_source inventory-status
grep -n '^import' inventory-status/src/main/java/io/astrona/keycloak/inventory/InventoryStatusResource.java
```

The imports list `Produces`, `MediaType` and `Provider`, but not `GET`. Add the line `import jakarta.ws.rs.GET;` above `import jakarta.ws.rs.Produces;` in that file, with your editor. Then upload and build:

```sh
upload_source inventory-status
build_provider
```

This time the build succeeds and Keycloak restarts. But `build_provider` keeps waiting at the rollout: the new Keycloak pod does not become ready.

## Step 3: Read why Keycloak does not start

Press Ctrl-C to stop waiting, then look at the pod and the log of the container that crashed:

```sh
kubectl -n spicapstone-demo get pods -l app=keycloak
kubectl -n spicapstone-demo logs deploy/keycloak --previous | tail -n 40
```

The pod restarts again and again. The log of the failed container has a `ServiceConfigurationError` that names the class `io.astrona.keycloak.inventory.InventoryStatusResourceProviderFactry`. That class does not exist; the factory is called `InventoryStatusResourceProviderFactory`. This is the second registration mistake: the services file has the right name, but the class name inside it is misspelled, so the build at start fails.

## Step 4: Fix the services file

```sh
cat inventory-status/src/main/resources/META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory
printf 'io.astrona.keycloak.inventory.InventoryStatusResourceProviderFactory\n' \
  > inventory-status/src/main/resources/META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory
upload_source inventory-status
build_provider
```

The build succeeds again, and this time Keycloak becomes ready.

## Step 5: Prove the fix

```sh
kcadm get serverinfo | jq '.providers["realm-restapi-extension"].providers | keys'
kubectl -n spicapstone-demo exec deploy/tester -- curl -s http://keycloak:8080/realms/inventory/inventory-status
```

The list contains `inventory-status`, and the endpoint answers `inventory-status ok realm=inventory`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the services file so Keycloak starts | Keycloak starts, but the provider is never loaded and the endpoint answers `404` |
| Rename the factory class to `...Factry` | It works, but the class name no longer says what it is, and the constraint forbids it |
| Remove the JAR from the volume | Keycloak starts without the provider; the task is to load it |

## Common mistakes

- Reading the log of the new container instead of the crashed one. Use `--previous`.
- Fixing both faults at once on a guess. Read each log, so you know which change fixed what.
- Forgetting `upload_source` after an edit. The Job builds what is in the ConfigMap.
