# Solution: Fix An Email Theme That Keycloak Cannot Find

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the files are at the paths Keycloak reads, Keycloak lists the theme and the realm uses it, and the subject message is set.

## Step 1: Look at what the pod has

Paste the helper from the task page. Then list the mounted folder and ask Keycloak for its email themes:

```sh
kubectl -n themes-demo exec deploy/keycloak -- find /opt/keycloak/themes/inventory
kcadm get serverinfo | jq '.themes.email | map(.name)'
```

The folder holds `theme.properties` and `messages_en.properties` next to each other. A ConfigMap volume without `items` puts every key in one flat folder. Keycloak looks for `email/theme.properties` and `email/messages/messages_en.properties` below the theme folder, so it finds no theme, and the list of email themes has no `inventory`.

## Step 2: Mount the keys at the right paths

Save this as `deployment-keycloak.yaml`. It is the `keycloak` Deployment with one change: the `items` of the volume `inventory-email-theme` give each key a path.

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

Apply it and wait for the new pod:

```sh
kubectl apply -f deployment-keycloak.yaml
kubectl -n themes-demo rollout status deployment/keycloak --timeout=10m
```

## Step 3: Check that Keycloak found the theme

```sh
kubectl -n themes-demo exec deploy/keycloak -- find /opt/keycloak/themes/inventory -type f
kcadm get serverinfo | jq '.themes.email | map(.name)'
```

The two files are now under `email/`, and the list of email themes includes `inventory`.

## Step 4: Select the theme for the realm

```sh
kcadm update realms/inventory -s emailTheme=inventory
kcadm get realms/inventory --fields emailTheme
```

The realm now uses the email theme `inventory`. Its password reset email gets the subject from `passwordResetSubject`.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Select the theme with `emailTheme` before fixing the mount | The realm names a theme that Keycloak does not have, and it falls back to the default |
| Mount the ConfigMap at `/opt/keycloak/themes` | Every other theme directory is hidden |
| Rename the keys in the ConfigMap to `email/theme.properties` | A ConfigMap key cannot contain a slash |
| Use `subPath` for the files | The files never receive later updates of the ConfigMap |

## Common mistakes

- Putting the files under `login/` because the earlier login theme did. The folder name is the theme type, `email` here.
- Checking `serverinfo` before the new pod is ready.
- Expecting the subject to change without a theme. The default subject comes from the parent theme.
