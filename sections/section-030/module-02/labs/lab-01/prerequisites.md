# Prerequisites

Before starting this lab you should be able to:

- Use `kcadm.sh` to read and change a realm's event settings.
- Read the JSON that `kcadm.sh` prints.
- Read the Keycloak log with `kubectl logs`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in the namespace **`events-demo`**, in development mode, with
  the realm `inventory` and the lab-only administrator `admin` / `admin`.
- The `tester` pod, with `curl` and `jq`.

You do not need Java or Maven on your machine. This lab builds nothing.

## Working rules

- Everything is graded on the **final state** of Keycloak and the cluster, so
  check the result yourself at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made on a guess
  makes the first one hard to prove.
- A change to a realm's event configuration is active at once. Keycloak needs no restart.
