# Email Theme Anatomy

When Keycloak sends an email, the realm must have a mail server, and Keycloak must know what the email says. Both the wording and the layout come from the realm's email theme. Before you change any text, you need to know which emails exist, which files make one, and where the theme inherits the rest from.

## The emails Keycloak sends

Each email has a template name and message keys. The template name is the name of two files, one HTML and one plain text. The message keys hold the subject and the body text. The ones you meet most often are these:

- `email-verification`: the link that confirms an email address. Subject key `emailVerificationSubject`.
- `password-reset`: the link to reset a forgotten password. Subject key `passwordResetSubject`, body keys `passwordResetBody` and `passwordResetBodyHtml`.
- `executeActions`: the link that lets a user complete required actions, sent when an administrator asks for it. Subject key `executeActionsSubject`.
- `email-test`: the message sent by the test button of the realm's email settings. Subject key `emailTestSubject`.
- `event-...` mails, such as `event-login_error`: a notice to the user about an event on their account, when the realm turns it on. The name carries the event type in lower case.
- `identity-provider-link`: the link that connects an external identity provider account.

## The files of an email theme

An email theme is a folder named after the theme, with a subfolder `email`. These paths are the ones Keycloak reads:

- `email/theme.properties`: the properties of the theme. The line `parent=base` makes the theme inherit from the `base` email theme.
- `email/messages/messages_en.properties`: the messages of one language, here English. The suffix is the language code; `messages_da.properties` holds Danish.
- `email/html/<template>.ftl`: the HTML version of an email.
- `email/text/<template>.ftl`: the plain-text version of an email.

Keycloak sends every email as both HTML and plain text, so a mail client picks the one it can show. A theme needs only the files it changes, because it inherits the rest from its parent.

## Parent themes and the realm setting

The built-in themes are in the Keycloak distribution. To see which email themes your Keycloak knows, ask the server for its themes:

<!-- astrona:playground:renew -->

```sh
kcadm get serverinfo | jq '.themes | keys'
kcadm get serverinfo | jq '.themes.email | map(.name)'
```

The first command lists the theme types, such as `account`, `admin`, `email`, `login` and `welcome`. The second lists the names of the email themes. Use one of these names as `parent`.

A realm chooses its email theme with the field `emailTheme`. Read it for the realm `inventory`:

```sh
kcadm get realms/inventory --fields emailTheme
```

When the field is not set, the realm uses the default email theme. The theme only changes the content of the mail. The mail server settings of the realm, `smtpServer`, hold the host, port and sender address, and they are a separate setting.

You now know which emails exist, which files make an email theme and how a realm selects one. The open question is how to put such a theme into the Keycloak pod so that Keycloak finds it.

## Common pitfalls

> [!WARNING]
> - **Putting email files under `login/`.** The folder name is the theme type, and Keycloak reads `email/` for emails.
> - **Writing only the HTML template.** Keycloak also needs the plain-text version for the same mail.
> - **Confusing the theme with the mail server.** `emailTheme` changes the content; `smtpServer` decides whether a mail can be sent.
> - **Using a parent name that does not exist.** Take the name from the `serverinfo` list.
