# Solution: Brand The Login Page With A Mounted Theme

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: Keycloak is ready, the theme volume is mounted at `/opt/keycloak/themes/inventory`, the realm uses the theme, and the login page shows the heading.

## Step 1: Read the current state

Paste the helpers from the task page. Then read the heading and the realm's theme:

```sh
login_page_title
kcadm get realms/inventory --fields loginTheme
```

The heading is `Sign in to your account`, and the realm has no login theme set. The heading is the message `loginAccountTitle`, which the template `login.ftl` prints, so one message override is enough.

## Step 2: Write the theme's two files

```sh
mkdir -p inventory-theme
```

Save this as `inventory-theme/theme.properties`:

```properties
parent=keycloak
```

Save this as `inventory-theme/messages_en.properties`:

```properties
loginAccountTitle=Sign in to Inventory
```

## Step 3: Store them in a ConfigMap

```sh
kubectl -n themes-demo create configmap inventory-theme \
  --from-file=inventory-theme/theme.properties \
  --from-file=inventory-theme/messages_en.properties
```

The keys are the file names, `theme.properties` and `messages_en.properties`.

## Step 4: Mount the ConfigMap as the theme directory

The volume maps each key to its place in the theme with `items`, and is mounted at `/opt/keycloak/themes/inventory`. The rest of the Deployment stays as it was.

Save this as `deployment-keycloak.yaml`:

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
  # Recreate: the old pod stops before the new one starts, so a restart
  # always loads the JAR that is in the volume now.
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
            - name: inventory-theme
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
        - name: inventory-theme
          configMap:
            name: inventory-theme
            items:
              - key: theme.properties
                path: login/theme.properties
              - key: messages_en.properties
                path: login/messages/messages_en.properties
```

Apply it:

```sh
kubectl apply -f deployment-keycloak.yaml
```

Then check the result:

```sh
kubectl -n themes-demo rollout status deployment/keycloak --timeout=10m
kubectl -n themes-demo exec deploy/keycloak -- find /opt/keycloak/themes/inventory -name '*.properties'
```

The files are at `login/theme.properties` and `login/messages/messages_en.properties` below the mount point.

## Step 5: Select the theme and prove it

```sh
kcadm update realms/inventory -s loginTheme=inventory
login_page_title
```

The heading is `Sign in to Inventory`.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Mount the ConfigMap without `items` | Both files land in one flat folder; Keycloak finds no `login/theme.properties` |
| Mount it at `/opt/keycloak/themes` | It hides every other theme directory, and the theme has no name folder |
| Copy `login.ftl` into the theme and change the heading there | It works today, but breaks the constraint and must be checked on every upgrade |
| Select the theme before the new pod is ready | The old pod has no theme `inventory` |

## Common mistakes

- Naming the message file `messages.properties`. Keycloak looks for the language suffix, for example `messages_en.properties`.
- Leaving out the providers volume when you rewrite the Deployment. Keep every existing volume and mount.
- Testing with a browser through a port-forward and the wrong client. `login_page_title` uses `inventory-web`, which allows the redirect URI it sends.
