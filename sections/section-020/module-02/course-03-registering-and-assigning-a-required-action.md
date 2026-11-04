# Registering And Assigning A Required Action

Loading the JAR makes the action known to the server. Each realm then decides to use it. This part registers `accept-terms` in the realm `inventory`, enables it and assigns it to a user.

## Unregistered actions

A realm keeps its own list of required actions. A custom action that Keycloak loaded but the realm did not register is in the realm's list of unregistered actions. Ask for it:

<!-- astrona:playground:renew -->

```sh
kcadm get authentication/unregistered-required-actions -r inventory
```

The answer lists each unregistered action with its `providerId` and `name`. The entry for `accept-terms` has the provider id `accept-terms` and the name `Accept the terms`.

## Register and enable

Register it with the provider id and a name:

```sh
kcadm create authentication/register-required-action -r inventory -s providerId=accept-terms -s name="Accept the terms"
```

The new entry has the alias `accept-terms`. For a custom action, the alias equals the provider id. Check that it is enabled and look at its priority:

```sh
kcadm get authentication/required-actions/accept-terms -r inventory
```

The fields that matter are `enabled`, `defaultAction` and `priority`. If `enabled` is false, turn it on:

```sh
kcadm update authentication/required-actions/accept-terms -r inventory -s enabled=true
```

The `priority` sets the order when a user has several actions: lower numbers run first. Setting `defaultAction=true` adds the action to every new user. Leave it false for now.

## Assign it to a user

Put the action on the user `bob`:

```sh
kcadm get users -r inventory -q username=bob --fields id
kcadm update users/<USER_ID> -r inventory -s 'requiredActions=["accept-terms"]'
```

The `requiredActions` attribute is a list of aliases, and setting it replaces the old list. To add one action without removing others, first read the list and send it back with the new alias included. Confirm the result:

```sh
kcadm get users/<USER_ID> -r inventory --fields username,requiredActions
```

The answer shows `accept-terms`. When `bob` signs in through a browser, Keycloak calls your `requiredActionChallenge`, which records the acceptance and removes the action from the list.

## When the action does not run

Check these in order: the provider id is in the server info, the action is registered in the realm, it is enabled, and the user has its alias in the list. A disabled action stays in the list but Keycloak skips it, so the user signs in without seeing it.

You now know how a loaded action becomes a working one: register, enable, assign. The open question is how an action decides by itself which users need it.

## Your mission: Register A Required Action

You can now load, register and assign a required action. The graded lab gives you a required action whose JAR is built but not found by Keycloak. You must fix the registration of the factory, then register the action in the realm, enable it and assign it to `bob`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-092-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-092-lab-020-02
astrona start ats-092-playground-020-02
```

## Common pitfalls

> [!WARNING]
> - **Registering with a different provider id.** Use the id the factory returns.
> - **Forgetting `enabled`.** A disabled action is skipped silently.
> - **Overwriting the user's other actions.** `requiredActions` replaces the whole list.
> - **Making an action a default action by mistake.** Every new user gets it.
