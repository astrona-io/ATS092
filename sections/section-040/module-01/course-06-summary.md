# Summary

Every page Keycloak shows comes from a theme: a set of FreeMarker templates, message files and static files. A theme has a type, such as `login`, `account`, `email`, `admin` or `welcome`, and a realm selects one theme per type with settings such as `loginTheme`. Keycloak 26 ships `base`, which holds the templates and messages, and `keycloak` and `keycloak.v2`, which build on it.

A theme's `theme.properties` names a `parent`, and Keycloak looks up every file it needs in the theme first, then in each parent in turn. Messages are merged the same way. A template prints a message with `${msg("key")}`, so the template decides where text goes and the message file decides what it says. Overriding one message, such as `loginAccountTitle`, is the smallest change that alters a page, and it survives Keycloak upgrades far better than a copied template.

A theme reaches Keycloak in one of two ways. As a directory, it lives at `/opt/keycloak/themes/<theme name>/<type>/`; in Kubernetes a ConfigMap mounted with `items` builds that layout, and in development mode, which does not cache themes, a change to the ConfigMap shows without a restart. As a JAR in the providers directory, it holds `META-INF/keycloak-themes.json`, whose names must match the folders under `theme/`, and Keycloak reads it only when it starts. The same JAR can also hold providers, registered in `META-INF/services/`. The key facts to remember are these:

- A theme changes nothing until a realm selects it.
- Mount a theme ConfigMap at `/opt/keycloak/themes/<theme name>` with `items`, never at the whole themes folder.
- The name in `keycloak-themes.json` must match the folder under `theme/`.
- Prove a theme with the page itself, fetched from inside the cluster.

<!-- astrona:playground:destroy -->
