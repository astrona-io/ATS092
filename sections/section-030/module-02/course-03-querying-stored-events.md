# Querying Stored Events

A store with thousands of events is useful only if you can ask a narrow question. The Admin REST API takes filters as query parameters, and `kcadm.sh` passes them with `-q name=value`. This part reads user events and admin events with filters and explains the fields that each answer has.

## Filter user events

The path `events` returns the stored user events of a realm, newest first. These parameters narrow the answer:

- `type`: an event type. Repeat the parameter to ask for several types.
- `user`: the id of a user (not the name).
- `client`: the client id, such as `inventory-cli`.
- `ipAddress`: the address of the caller.
- `dateFrom` and `dateTo`: a date in the form `yyyy-MM-dd`, inclusive.
- `first` and `max`: the position of the first result and the number of results. The default is 100 results.

Ask for the failed sign-ins of the client:

<!-- astrona:playground:renew -->

```sh
kcadm get events -r inventory -q type=LOGIN_ERROR -q client=inventory-cli
```

Each result is a JSON object with `time` (milliseconds since 1970), `type`, `realmId`, `clientId`, `userId`, `ipAddress`, an `error` for error events, and `details`. For the wrong password of `alice`, `error` is `invalid_user_credentials`. For a name that does not exist, `error` is `user_not_found`, there is no `userId`, and the name is in `details`.

To filter by user, first read the user's id, then pass it:

```sh
USER_ID=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes)
kcadm get events -r inventory -q user=$USER_ID -q max=5
```

The answer holds at most the five newest events of `alice`.

## Filter admin events

The path `admin-events` returns the stored admin events. Its filters are `operationTypes` (`CREATE`, `UPDATE`, `DELETE` or `ACTION`), `resourceTypes` (for example `CLIENT`, `USER` or `REALM_ROLE`), `resourcePath` (for example `clients/*`, where `*` matches one path segment), `authRealm`, `authClient`, `authUser` and `authIpAddress` (who made the change), `dateFrom`, `dateTo`, `first` and `max`:

```sh
kcadm get admin-events -r inventory -q resourceTypes=CLIENT -q operationTypes=UPDATE
```

An admin event has `operationType`, `resourceType`, `resourcePath`, and `authDetails` with the realm, client, user and address of the caller. Because the administrator `admin` signed in to the realm `master`, `authDetails.realmId` names the master realm, while `realmId` names `inventory`, the realm that changed. When details are on, `representation` holds the JSON of the change as text.

## Read the answer with jq

`kcadm.sh` prints JSON. Pipe it to `jq` on your own machine to reduce it to the fields you need. For example, to list the time, type and error of the stored failed sign-ins:

```sh
kcadm get events -r inventory -q type=LOGIN_ERROR | jq -r '.[] | [.time, .type, .error] | @tsv'
```

Use `date -r` on macOS or `date -d @` on Linux with the time divided by 1000 to turn a time into a date.

You can now ask the store a narrow question for both kinds of events. The open question is how long the answers stay available.

## Common pitfalls

> [!WARNING]
> - **Passing a user name to `user`.** The filter takes the id of the user.
> - **Forgetting `max`.** The answer is limited to 100 events by default, so an old event may be missing.
> - **Using a time as a date.** `dateFrom` and `dateTo` take `yyyy-MM-dd`.
> - **Confusing the two realm ids of an admin event.** `realmId` is the realm that changed; `authDetails.realmId` is the realm of the administrator.

## Your mission: Make Failed Sign-Ins Searchable

You can now set the realm's event storing and query user events and admin events. The graded lab gives you a realm that stores only successful sign-ins and no admin events, and asks you to store the failed sign-ins and the admin changes, limit the lifetime of the events, and prove it with queries.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-092-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-092-lab-030-02
astrona start ats-092-playground-030-02
```
