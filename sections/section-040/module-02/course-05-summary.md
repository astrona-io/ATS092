# Summary

Keycloak sends emails such as the password reset link, the email verification link and the notice after a required action. Each email has a template name, an HTML template, a plain-text template and message keys for its subject and body. An email theme is a folder with the subfolder `email`. It holds `theme.properties` with a `parent`, `messages/messages_<language>.properties`, `html/<template>.ftl` and `text/<template>.ftl`. A realm chooses the theme with `emailTheme`, and the mail server settings in `smtpServer` are separate.

A theme delivered as a mounted directory must have its files at those paths. A ConfigMap volume without `items` puts all keys in one flat folder, so Keycloak finds no theme. The `items` list gives each key a path, and the mount point is `/opt/keycloak/themes/<theme name>`. The list `kcadm get serverinfo` shows the themes that Keycloak found, by type, and a realm that names a theme that is not in the list falls back to the default.

Changing a message key is the smallest change. Changing the structure of a mail needs both templates, because every mail is sent as HTML and as plain text. A template prints messages with `msg("key", arguments)` and passes HTML bodies through `kcSanitize` and `?no_esc`. The account console is a single-page application in the theme `keycloak.v3`, so an account theme changes messages, style and resources and not page templates.

Languages are a realm setting. The key facts to remember are these:

- Email files go under `email/`, not `login/`.
- Write both the HTML and the text template of a mail.
- `emailTheme` and `accountTheme` select a theme per realm; a missing theme falls back to the default.
- `internationalizationEnabled`, `supportedLocales` and `defaultLocale` turn on languages for every theme type.

<!-- astrona:playground:destroy -->
