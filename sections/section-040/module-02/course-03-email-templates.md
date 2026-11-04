# Email Templates

A message override changes words. It cannot add a line, a link or a footer to the mail, because the structure of the mail is in a template. This part reads the two templates of one email, explains the layout macro and the objects a template can use, and adds a footer line to the password reset mail.

## Two templates for one mail

Every email has an HTML template in `email/html/` and a plain-text template in `email/text/`, with the same file name. The password reset mail uses `password-reset.ftl` in both folders. Both are FreeMarker templates, the template language of Keycloak pages: `${expression}` prints a value, and `msg("key", arguments)` prints the message with that key, with the arguments filled in at `{0}`, `{1}` and so on.

The plain-text template starts with a directive that sets the output format, so that special characters are not escaped as HTML:

```ftl
<#ftl output_format="plainText">
${msg("passwordResetBody",link, linkExpiration, realmName, linkExpirationFormatter(linkExpiration))}
```

The HTML template imports the layout of the email theme and calls its macro `emailLayout`, which draws the frame of the mail. The message of the HTML body contains markup, so the template passes it through `kcSanitize`, which removes unsafe markup, and then `?no_esc`, which tells FreeMarker not to escape the markup a second time:

```ftl
<#import "template.ftl" as layout>
<@layout.emailLayout>
${kcSanitize(msg("passwordResetBodyHtml",link, linkExpiration, realmName, linkExpirationFormatter(linkExpiration)))?no_esc}
</@layout.emailLayout>
```

The exact arguments of `msg` and the macros differ between Keycloak versions. Copy the template from the parent theme of the version you run, and change only what you need.

## The objects in an email template

Keycloak gives an email template a small set of objects:

- `link`: the address the user must open, for example the reset link.
- `linkExpiration`: the lifetime of the link in minutes, and `linkExpirationFormatter(linkExpiration)`, which turns it into text such as "5 minutes".
- `realmName`: the display name of the realm.
- `user`: the user who gets the mail, with fields such as `user.firstName`.
- `msg("key", ...)`: the message function, which uses the language of the user.

A value that is missing stops the template with an error, so give an optional value a default with `!`, as in `${user.firstName!""}`.

## Add a footer to the mail

Add a new message key `inventoryFooter`, then print it in both templates. Change the message file and add two template files. Save this as `inventory-email-theme/messages_en.properties`:

<!-- astrona:playground:renew -->

```properties
passwordResetSubject=Reset your Inventory password
inventoryFooter=Sent by the Inventory team.
```

Save this as `inventory-email-theme/password-reset-html.ftl`:

```ftl
<#import "template.ftl" as layout>
<@layout.emailLayout>
${kcSanitize(msg("passwordResetBodyHtml",link, linkExpiration, realmName, linkExpirationFormatter(linkExpiration)))?no_esc}
<p>${msg("inventoryFooter")}</p>
</@layout.emailLayout>
```

Save this as `inventory-email-theme/password-reset-text.ftl`:

```ftl
<#ftl output_format="plainText">
${msg("passwordResetBody",link, linkExpiration, realmName, linkExpirationFormatter(linkExpiration))}

${msg("inventoryFooter")}
```

Put all three files in the ConfigMap, keeping the key `theme.properties` from before. Then add two entries to the `items` of the volume `inventory-email-theme` with a JSON patch. A ConfigMap key cannot contain a slash, so the key is a flat name and the `path` gives the folder:

```sh
kubectl -n themes-demo create configmap inventory-email-theme \
  --from-file=theme.properties=inventory-email-theme/theme.properties \
  --from-file=inventory-email-theme/messages_en.properties \
  --from-file=inventory-email-theme/password-reset-html.ftl \
  --from-file=inventory-email-theme/password-reset-text.ftl \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n themes-demo patch deployment keycloak --type=json -p '[
  {"op":"add","path":"/spec/template/spec/volumes/2/configMap/items/-","value":{"key":"password-reset-html.ftl","path":"email/html/password-reset.ftl"}},
  {"op":"add","path":"/spec/template/spec/volumes/2/configMap/items/-","value":{"key":"password-reset-text.ftl","path":"email/text/password-reset.ftl"}}
]'
kubectl -n themes-demo rollout status deployment/keycloak --timeout=10m
```

The number `2` is the position of the theme volume in the Deployment from the previous steps: `providers`, `data`, then the theme. Check that both templates are in place:

```sh
kubectl -n themes-demo exec deploy/keycloak -- find /opt/keycloak/themes/inventory -type f
```

The listing shows the two templates under `email/html` and `email/text`, next to the message file. Because the theme is in the realm's `emailTheme`, the next password reset mail ends with the footer line, in both versions.

You can now read the templates of a mail and change them. The open question is what the account theme, the page where users manage their own data, lets you change.

## Common pitfalls

> [!WARNING]
> - **Changing only one of the two templates.** A mail client that shows the other version displays the old text.
> - **Printing a message that contains HTML without `?no_esc`.** The user sees the markup as text.
> - **Removing `kcSanitize`.** A message value that holds unsafe markup then reaches the mail unchanged.
> - **Copying the template of another Keycloak version.** The macros and message arguments can differ.
