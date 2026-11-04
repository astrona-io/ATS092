# Email And Account Themes

The login page is only one of the pages a user sees. Keycloak also sends emails: the link to reset a password, the link to verify an email address, and the message after a required action. The user also opens the account console to change their own profile and password. Each of these has a theme type of its own. The `inventory` team wants the password reset email to say "Reset your Inventory password" and to use its own wording.

The **email theme** holds the templates and messages of every email Keycloak sends. The **account theme** styles the account console, the page where a user manages their own account. A theme type is chosen per realm, so one realm can use a custom login theme, a custom email theme and the default account theme at the same time. This module writes an email theme as a mounted directory, reads its templates, and then looks at the account theme and the languages of a realm.

Keep one sentence in mind: **a theme type is looked up by name in its own folder, so the files of an email theme must be under `email/` and not under `login/`.** A correct file in the wrong folder is a theme that Keycloak does not see.

The module has four parts. **Email Theme Anatomy** lists the emails Keycloak sends and the files that make an email theme. **Changing Email Text From A ConfigMap** mounts an email theme, changes a subject and selects the theme for the realm. A graded lab follows the second part. **Email Templates** covers the HTML and text templates of one email and the layout macro. **The Account Theme And Languages** covers the account console, its parent theme and the realm's locales.

## Learning objectives

After this module you can:

- Name the emails Keycloak sends and the message keys of their subjects and bodies.
- Describe the folders and files of an email theme and its parent theme.
- Mount an email theme from a ConfigMap at the right paths and select it for a realm.
- Read the HTML and text templates of an email and explain the layout macro.
- Select an account theme and add a language to a realm.

## Before you start

You need Kubernetes basics: ConfigMaps, Deployments, volumes and `kubectl apply`. You need the `kcadm` habits of this course. The playground has no outgoing mail server, so the pages prove a theme by what Keycloak lists and by the files in the pod. You do not need Java or Maven on your machine.

Your playground is a single-node `kind` cluster in the namespace **`themes-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode, with the lab-only administrator `admin` / `admin`. In development mode Keycloak does not cache themes and templates |
| realm `inventory` | The user `alice` and the public clients `inventory-cli` and `inventory-web`. It uses the default themes |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

The commands in the parts use one helper. `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator. Paste it once in each new terminal:

```sh
NAMESPACE=themes-demo

# kcadm runs kcadm.sh inside the Keycloak pod. It signs in to the realm
# master as the lab-only administrator on every call, so it keeps working
# after Keycloak restarts.
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- bash -c '
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
      --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null &&
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config' kcadm "$@"
}
```
