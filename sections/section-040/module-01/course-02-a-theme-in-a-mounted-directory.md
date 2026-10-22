# A Theme In A Mounted Directory

The quickest way to give Keycloak a theme is a directory under `/opt/keycloak/themes`. In Kubernetes, that directory comes from a ConfigMap mounted as a volume. This part writes the `inventory` login theme, mounts it into the Keycloak pod, and makes the realm use it.

## Two files are a whole theme

The theme needs only two files, because it inherits everything else from its parent. `theme.properties` names the parent; the message file overrides one key. Create a folder for them:

<!-- astrona:playground:renew -->

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

Store both files in one ConfigMap. Each file becomes a key with its file name:

```sh
kubectl -n themes-demo create configmap inventory-theme \
  --from-file=inventory-theme/theme.properties \
  --from-file=inventory-theme/messages_en.properties
```

## Mount the ConfigMap as a theme directory

Keycloak expects the files at `/opt/keycloak/themes/inventory/login/theme.properties` and `/opt/keycloak/themes/inventory/login/messages/messages_en.properties`. A ConfigMap volume puts every key in one flat folder, so the volume uses `items`: each item maps a key to a `path` below the mount point, and the path may contain folders. The volume is mounted at `/opt/keycloak/themes/inventory`, which makes `inventory` the theme's name.

The Deployment below is the playground's `keycloak` Deployment with one more volume and one more mount, both named `inventory-theme`. Everything else, including the providers volume, stays as it was.

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
            - name: inventory-theme
              mountPath: /opt/keycloak/themes/inventory
              readOnly: true
      volumes:
        - name: providers
          persistentVolumeClaim:
            claimName: keycloak-providers
            readOnly: true
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

Then check the result. The Deployment uses the strategy `Recreate`, so the old pod stops before the new one starts:

```sh
kubectl -n themes-demo rollout status deployment/keycloak --timeout=10m
kubectl -n themes-demo exec deploy/keycloak -- find /opt/keycloak/themes/inventory -name '*.properties'
```

The `find` lists the two files at the paths Keycloak expects.

## Select the theme for the realm

Keycloak found the theme when it started, but the realm still uses the default. Select `inventory` as the realm's login theme, and read the heading again:

```sh
kcadm get serverinfo | jq '.themes.login | map(.name)'
kcadm update realms/inventory -s loginTheme=inventory
login_page_title
```

The list of login themes now includes `inventory`, and the heading is `Sign in to Inventory`. The rest of the page is unchanged, because every other file and message still comes from `keycloak` and `base`.

Because development mode does not cache themes, you can change the text without a restart. Change the message in the ConfigMap with `kubectl -n themes-demo edit configmap inventory-theme`, wait about a minute until the kubelet updates the mounted file, and run `login_page_title` again. The kubelet is the Kubernetes agent on the node; it refreshes the files of a ConfigMap volume after the ConfigMap changes.

You can now write a theme as a directory, mount it from a ConfigMap at the right path, and select it for a realm. The open question is how a theme ships when it is not a loose directory but part of a JAR next to your providers.

## Common pitfalls

> [!WARNING]
> - **Mounting the ConfigMap without `items`.** The files land in one flat folder, and Keycloak finds no `login/theme.properties`.
> - **Mounting at `/opt/keycloak/themes`.** That hides every other theme directory; mount at `/opt/keycloak/themes/<theme name>`.
> - **Using `subPath` for theme files.** A `subPath` mount never receives ConfigMap updates.
> - **Forgetting to select the theme.** A theme that Keycloak found changes nothing until a realm uses it.

## Your mission: Brand The Login Page With A Mounted Theme

You can now deliver a login theme as a mounted directory and prove it with the login page. The graded lab gives you a realm that uses Keycloak's default login page, and asks you to create the `inventory` theme, mount it from a ConfigMap and make the login page show "Sign in to Inventory".

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-092-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-092-lab-040-01
astrona start ats-092-playground-040-01
```
