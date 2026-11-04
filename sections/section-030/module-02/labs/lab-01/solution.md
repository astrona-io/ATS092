# Solution: Make Failed Sign-Ins Searchable

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the user event settings, a stored `LOGIN_ERROR` event from a new failed sign-in, and a stored admin event with its representation.

## Step 1: Read the event configuration

Paste the helpers from the task page. Then read the configuration:

```sh
kcadm get events/config -r inventory
```

The output shows `eventsEnabled` set to `true`, so the realm stores user events. The list `enabledEventTypes` holds only `LOGIN`. A failed sign-in is the type `LOGIN_ERROR`, which is not in the list, so the realm does not store it. `eventsExpiration` is not set, and `adminEventsEnabled` is `false`.

## Step 2: Prove that a failed sign-in is missing

```sh
get_user_token alice wrong-password
kcadm get events -r inventory -q type=LOGIN_ERROR
```

The second command prints an empty list. The realm sent the event to its listeners, but it did not store it.

## Step 3: Change the settings

Setting `enabledEventTypes` replaces the whole list, so name both types. Set the expiration in seconds, and turn on admin events with details:

```sh
kcadm update events/config -r inventory \
  -s eventsEnabled=true \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR"]' \
  -s eventsExpiration=86400 \
  -s adminEventsEnabled=true \
  -s adminEventsDetailsEnabled=true
```

The change is active at once. Keycloak needs no restart.

## Step 4: Prove both kinds of event

```sh
get_user_token alice wrong-password
kcadm get events -r inventory -q type=LOGIN_ERROR
```

The list now holds an event with `"type" : "LOGIN_ERROR"` and `"error" : "invalid_user_credentials"`. Then change a client and read the admin event:

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes)
kcadm update clients/$CLIENT_ID -r inventory -s description="Command-line client"
kcadm get admin-events -r inventory -q resourceTypes=CLIENT -q operationTypes=UPDATE
```

The admin event has `"operationType" : "UPDATE"`, `"resourceType" : "CLIENT"`, the `resourcePath`, who made the change in `authDetails`, and the changed object in `representation`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set `enabledEventTypes` to `["LOGIN_ERROR"]` only | Failed sign-ins are stored, and successful ones are lost again |
| Leave `adminEventsDetailsEnabled` off | Admin events are stored, but without the representation of the change |
| Skip `eventsExpiration` | Events stay in the database until someone deletes them |
| Replace `eventsListeners` while changing the settings | The realm stops writing events to the server log |

## Common mistakes

- Testing with a user that does not exist. The event is still stored, but it has no `userId`; the name is in `details.username`.
- Reading the events before making the failed sign-in. Only events that happen after the change are stored.
- Using a day count for `eventsExpiration`. The value is in seconds.
