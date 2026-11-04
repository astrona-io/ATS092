# Choosing What To Store

A busy realm sends thousands of token and refresh events an hour. Stored in full, they fill the database and bury the few events a security team reads. This part turns on the event types that matter and the admin event details, and shows how a change of the list works.

## Pick event types

The list `enabledEventTypes` names the user event types that the realm saves. Choose the types that answer a question. Failed sign-ins answer who tried to get in, so keep `LOGIN_ERROR`. Successful sign-ins answer who is active, so keep `LOGIN`. Password changes are `UPDATE_PASSWORD` and `RESET_PASSWORD`. Skip high-volume types such as `REFRESH_TOKEN` and `INTROSPECT_TOKEN` unless you need them.

The update replaces the whole list. If you send `["LOGIN_ERROR"]`, the realm stops saving `LOGIN`. Always send every type you want.

## Turn on storing

Set the fields in one command. The option `-s` sets one field. A JSON array is written in single quotes, so that the shell passes it unchanged:

<!-- astrona:playground:renew -->

```sh
kcadm update events/config -r inventory \
  -s eventsEnabled=true \
  -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR","UPDATE_PASSWORD"]'
kcadm get events/config -r inventory
```

The realm now saves these three types. Keycloak applies the change at once. It needs no restart, because the configuration is realm data.

Do not replace `eventsListeners` while you do this. The command above leaves the field alone, so `jboss-logging` stays in the list. A command that sets `eventsListeners` replaces the list, which stops the log lines of the listeners you leave out.

## Turn on admin events

Admin events need two fields. `adminEventsEnabled` saves each change. `adminEventsDetailsEnabled` also saves the representation, so you can see what the change set. The representation can contain personal data, such as an email address, so turn it on only when you need it:

```sh
kcadm update events/config -r inventory \
  -s adminEventsEnabled=true \
  -s adminEventsDetailsEnabled=true
```

From this moment, every change through the Admin REST API is saved, including changes that `kcadm.sh` makes.

## Make some events

Sign `alice` in with a wrong password and then with the right one, so the store holds a `LOGIN_ERROR` and a `LOGIN`. Then change a client, so it holds an admin event:

```sh
get_user_token alice wrong-password
get_user_token alice alice-password > /dev/null
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes)
kcadm update clients/$CLIENT_ID -r inventory -s description="Command-line client"
```

The first call prints the error text for the wrong password. The events are now in the store, ready to be read.

You can now choose which user events and admin events a realm saves, and change the list without losing a listener. The open question is how to find one event among thousands.

## Common pitfalls

> [!WARNING]
> - **Sending a short list and losing types.** `enabledEventTypes` is replaced, not extended.
> - **Turning on details everywhere.** The representation of an admin event can hold personal data and secrets in the changed object.
> - **Setting `eventsListeners` to change storing.** That field changes who receives events, not what is saved.
> - **Using a wrong password and expecting `LOGIN`.** A failed sign-in is `LOGIN_ERROR`.
