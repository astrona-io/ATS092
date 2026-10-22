# Add A Custom Step To An Authentication Flow — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-092-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic. Nothing to submit.

> **Not yet run.** This playground was written from the Keycloak 26.8.1
> documentation and has not been started yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-092-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-092-playground-020-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Deploys Keycloak, creates the realm, fills the Maven cache |
| `manifests/lab-start.yaml` | Namespace `authenticator-demo`, Keycloak, the two PVCs, tester |
| `manifests/job-build-provider.yaml` | The build Job; `prepare.sh` stores it in the ConfigMap `build-provider-job` |
| `manifests/job-warm-maven-cache.yaml`, `manifests/warmup-pom.xml` | The cache-filling Job and the `pom.xml` it resolves |
| `docs/overview.md` | What the environment contains and ideas to try |
