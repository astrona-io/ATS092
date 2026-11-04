# Supplying Settings In Kubernetes

In a cluster, nobody edits `kc.sh` arguments by hand. The settings come from the Deployment. This part shows the three ways to deliver them to the Keycloak pod: environment variables, a ConfigMap or Secret, and a `keycloak.conf` file.

## Environment variables in the Deployment

The simplest way is an `env` entry on the container. `kubectl set env` edits it, and a change makes Kubernetes create a new pod:

```sh
kubectl -n config-demo set env deploy/keycloak KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE=audit
```

To read the variables the container has now:

```sh
kubectl -n config-demo get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].env[*].name}'
```

The command prints the variable names, separated by spaces. Check the spelling of every name here when a setting seems to have no effect.

## Values from a ConfigMap or a Secret

A value that is not secret can come from a ConfigMap, so the Deployment does not change when the value does. A secret value, such as a password for an outside service, must come from a Secret. In the container spec, an entry looks like this:

```yaml
env:
  - name: KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE
    valueFrom:
      configMapKeyRef:
        name: inventory-settings
        key: mode
```

For a Secret, use `secretKeyRef` in the same place. A change in the ConfigMap does not restart the pod. The pod keeps the old value until it is restarted, for example with `kubectl rollout restart deploy/keycloak`.

## A keycloak.conf file

All settings can also live in one file. The file `/opt/keycloak/conf/keycloak.conf` holds `key=value` lines, without the leading dashes. Mount a ConfigMap on that path with `subPath`, so it replaces the file without hiding the rest of the `conf` directory:

```yaml
volumeMounts:
  - name: keycloak-conf
    mountPath: /opt/keycloak/conf/keycloak.conf
    subPath: keycloak.conf
```

The ConfigMap key `keycloak.conf` then contains lines such as `spi-realm-restapi-extension--inventory-status--mode=audit`. Use the file when you have many settings, and environment variables for the few that differ between environments.

## Which source wins

A command-line argument beats an environment variable, and an environment variable beats the file. If a setting seems to be ignored, look for the same setting in a higher source. The container arguments are in the Deployment:

<!-- astrona:playground:renew -->

```sh
kubectl -n config-demo get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].args}'
```

In the playground the argument list holds only `start-dev`, so no setting comes from the command line.

You now know three ways to deliver settings and which source wins. The open question is how quickly you can find a setting that has the wrong name.

## Common pitfalls

> [!WARNING]
> - **Putting a secret in a plain `env` value.** Use a Secret with `secretKeyRef`.
> - **Mounting a ConfigMap over the whole `conf` directory.** Use `subPath` to replace one file.
> - **Expecting a ConfigMap change to reach the pod at once.** Restart the Deployment.
> - **Setting the same value in two sources.** The higher source wins, and the lower one looks ignored.

## Your mission: Fix A Provider Setting That Is Ignored

You can now name a provider setting correctly and deliver it to the pod. The graded lab gives you the `inventory-status` provider, already built, and a Deployment that sets the mode with a wrong name. The endpoint must report `mode=audit` without a change to the Java source.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-092-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-092-lab-010-02
astrona start ats-092-playground-010-02
```
