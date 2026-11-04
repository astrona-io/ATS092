# Solution: Register A Required Action

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: Keycloak is ready, the server info lists `accept-terms`, the realm has the enabled action, and `bob` has it.

## Step 1: Ask the server what it loaded

```sh
kcadm get serverinfo | jq '.providers["required-action"].providers | keys'
```

`accept-terms` is not in the list. The JAR is in the directory and Keycloak started, so the registration file is the suspect.

## Step 2: Read the services file

Download the source and list the files:

```sh
download_source accept-terms
find accept-terms/src/main/resources -type f
```

The file is named `org.keycloak.authentication.RequiredActionProvider`. Keycloak looks for the factory interface, `org.keycloak.authentication.RequiredActionFactory`, so it never opened this file.

## Step 3: Rename the file and rebuild

Move the file to the right name, keeping its content, which is the class name of the factory. Then upload and build:

```sh
mv accept-terms/src/main/resources/META-INF/services/org.keycloak.authentication.RequiredActionProvider \
   accept-terms/src/main/resources/META-INF/services/org.keycloak.authentication.RequiredActionFactory
upload_source accept-terms
build_provider
```

Run the server info again. The id `accept-terms` is now in the list. Because the ConfigMap is rebuilt from the folder, the old key disappears with the old file.

## Step 4: Register and enable the action

```sh
kcadm create authentication/register-required-action -r inventory -s providerId=accept-terms -s name="Accept the terms"
kcadm update authentication/required-actions/accept-terms -r inventory -s enabled=true
```

## Step 5: Assign it to bob

```sh
kcadm get users -r inventory -q username=bob --fields id
kcadm update users/<USER_ID> -r inventory -s 'requiredActions=["accept-terms"]'
```

Then run `astrona submit`.
