# Changing Email Text From A ConfigMap

The `inventory` team wants the password reset mail to say "Reset your Inventory password". That text is one message key. This part writes an email theme with only that message, mounts it from a ConfigMap and selects it for the realm. It uses the same mounting method as a login theme, with the folder `email`.

## Two files are a whole theme

The theme needs `theme.properties` for the parent and one message file. Create a folder for them:

<!-- astrona:playground:renew -->

```sh
mkdir -p inventory-email-theme
```

Save this as `inventory-email-theme/theme.properties`:

```properties
parent=base
```

Save this as `inventory-email-theme/messages_en.properties`:

```properties
passwordResetSubject=Reset your Inventory password
```

Store both files in one ConfigMap. Each file becomes a key with its file name:

```sh
kubectl -n themes-demo create configmap inventory-email-theme \
  --from-file=inventory-email-theme/theme.properties \
  --from-file=inventory-email-theme/messages_en.properties
```

## Mount the files at the paths Keycloak reads

Keycloak expects `/opt/keycloak/themes/inventory/email/theme.properties` and `/opt/keycloak/themes/inventory/email/messages/messages_en.properties`. A ConfigMap volume without `items` puts every key in one flat folder, so the volume needs an `items` list that gives each key a path. A key name cannot contain a slash, which is why the paths are set in `items` and not in the keys.

The Deployment below is the playground's `keycloak` Deployment with one more volume and one more mount, both named `inventory-email-theme`. Save this as `deployment-keycloak.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: themes-demo
  labels:
    app: keycloak
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:26.8.1
          args: ["start-dev"]
          env:
            - name: KC_BOOTSTRAP_ADMIN_USERNAME
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: username
            - name: KC_BOOTSTRAP_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-admin
                  key: password
            - name: KC_HEALTH_ENABLED
              value: "true"
          ports:
            - name: http
              containerPort: 8080
            - name: management
              containerPort: 9000
          startupProbe:
            httpGet:
              path: /health/started
              port: management
            periodSeconds: 5
            failureThreshold: 60
          readinessProbe:
            httpGet:
              path: /health/ready
              port: management
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health/live
              port: management
            periodSeconds: 10
          resources:
            requests:
              memory: 768Mi
              cpu: 250m
            limits:
              memory: 1536Mi
          volumeMounts:
            - name: providers
              mountPath: /opt/keycloak/providers
              readOnly: true
            - name: data
              mountPath: /opt/keycloak/data/h2
            - name: inventory-email-theme
              mountPath: /opt/keycloak/themes/inventory
              readOnly: true
      volumes:
        - name: providers
          persistentVolumeClaim:
            claimName: keycloak-providers
            readOnly: true
        - name: data
          persistentVolumeClaim:
            claimName: keycloak-data
        - name: inventory-email-theme
          configMap:
            name: inventory-email-theme
            items:
              - key: theme.properties
                path: email/theme.properties
              - key: messages_en.properties
                path: email/messages/messages_en.properties
```

Apply it:

```sh
kubectl apply -f deployment-keycloak.yaml
```

Then check the result. The Deployment uses the strategy `Recreate`, so the old pod stops before the new one starts:

```sh
kubectl -n themes-demo rollout status deployment/keycloak --timeout=10m
kubectl -n themes-demo exec deploy/keycloak -- find /opt/keycloak/themes/inventory -type f
```

The `find` lists the two files below `email/`.

## Select the theme for the realm

Keycloak found the theme when it started, but the realm still uses the default. Check that the server lists it, then select it:

```sh
kcadm get serverinfo | jq '.themes.email | map(.name)'
kcadm update realms/inventory -s emailTheme=inventory
kcadm get realms/inventory --fields emailTheme
```

The list of email themes now includes `inventory`, and the realm names it. From now on, the password reset mail of the realm gets its subject from `passwordResetSubject` in this theme. Every other message still comes from the parent theme `base`.

The playground has no mail server, so it cannot show the mail itself. In a real realm, set the mail server in `smtpServer`, then use the test button of the email settings in the admin console. The test mail uses the same theme.

You can now deliver an email theme as a directory, mount it at the right paths and select it for a realm. The open question is what to do when a message is not enough and the layout of the mail itself must change.

## Common pitfalls

> [!WARNING]
> - **Mounting the ConfigMap without `items`.** The files land in one flat folder, and Keycloak finds no `email/theme.properties`.
> - **Mounting at `/opt/keycloak/themes`.** That hides every other theme directory; mount at `/opt/keycloak/themes/<theme name>`.
> - **Using `subPath` for theme files.** A `subPath` mount never receives ConfigMap updates.
> - **Selecting the theme before Keycloak lists it.** A realm that names a missing theme falls back to the default.

## Your mission: Fix An Email Theme That Keycloak Cannot Find

You can now mount an email theme and select it for a realm. The graded lab gives you a realm and a ConfigMap with an email theme that is mounted the wrong way, and asks you to find why Keycloak does not list the theme, fix the mount and select the theme.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-092-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-092-lab-040-02
astrona start ats-092-playground-040-02
```
