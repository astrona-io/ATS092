# Solution: Fix A Provider Setting That Is Ignored

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: Keycloak is ready, the server info lists `inventory-status`, the endpoint reports `mode=audit`, and the Deployment has the correctly named variable.

## Step 1: Read the environment of the Deployment

```sh
kubectl -n config-demo get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].env[*].name}'
```

The list contains `KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODES`. The name ends with `MODES`, but the factory reads the key `mode`.

## Step 2: Check the name against the rule

```sh
kcadm get serverinfo | jq '.providers["realm-restapi-extension"].providers | keys'
```

The SPI is `realm-restapi-extension` and the provider id is `inventory-status`. The variable must therefore be `KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE`. Keycloak ignored the wrong name, which is why the provider kept its default.

## Step 3: Set the right variable and remove the wrong one

```sh
kubectl -n config-demo set env deploy/keycloak KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE=audit KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODES-
kubectl -n config-demo rollout status deploy/keycloak --timeout=10m
```

The trailing dash removes the wrong variable. Kubernetes starts a new pod, which reads the setting in `init`.

## Step 4: Prove it

```sh
kubectl -n config-demo exec deploy/tester -- curl -s http://keycloak:8080/realms/inventory/inventory-status
```

The answer is `inventory-status ok realm=inventory mode=audit`. Then run `astrona submit`.
