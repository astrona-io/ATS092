# Triggers, Forms And Completing An Action

An action that every user must accept is rarely enough. Often it should apply only to some users, or ask for input. This part shows how an action adds itself to a user, how it shows a form and how it finishes.

## Add the action from a condition

`evaluateTriggers` runs on every sign-in, for every user, before Keycloak shows the actions. The provider checks a condition and adds its own alias to the user:

```java
@Override
public void evaluateTriggers(RequiredActionContext context) {
    String accepted = context.getUser().getFirstAttribute("termsAccepted");
    if (!"true".equals(accepted)) {
        context.getUser().addRequiredAction("accept-terms");
    }
}
```

With this method, no administrator has to assign the action: every user who did not accept the terms gets it at the next sign-in. The action must still be registered and enabled in the realm. Keep this method fast, because it runs on every sign-in.

## Show a form

To ask for input, `requiredActionChallenge` builds a page with the form provider and returns it as a challenge. `processAction` reads the answer:

```java
@Override
public void requiredActionChallenge(RequiredActionContext context) {
    context.challenge(context.form().createForm("accept-terms.ftl"));
}

@Override
public void processAction(RequiredActionContext context) {
    var form = context.getHttpRequest().getDecodedFormParameters();
    if ("yes".equals(form.getFirst("accept"))) {
        context.getUser().setSingleAttribute("termsAccepted", "true");
        context.success();
        return;
    }
    context.challenge(context.form().setError("termsRequired").createForm("accept-terms.ftl"));
}
```

The template `accept-terms.ftl` belongs to the login theme of the realm, and the message key `termsRequired` to its message file. The template needs a form that posts to `${url.loginAction}` with a field named `accept`.

## The ways to finish

The context offers these results: `success()` removes the action and continues. `challenge(response)` shows a page. `failure()` ends the sign-in with an error. `ignore()` leaves the action in the user's list and goes on to the next one, so the user sees it again at the next sign-in.

## Check the user afterwards

After the user completed the action, read the user and the stored attribute:

<!-- astrona:playground:renew -->

```sh
kcadm get users/<USER_ID> -r inventory --fields username,requiredActions,attributes
```

The list `requiredActions` no longer contains `accept-terms`, and the attribute `termsAccepted` holds `true`. An attribute is only kept if the realm's user profile allows unmanaged attributes, which the playground realm does.

You now know how an action adds itself, how it asks for input and how it ends. The open question for a real project is where to keep the proof of acceptance, because a user attribute can be changed by an administrator.

## Common pitfalls

> [!WARNING]
> - **Heavy work in `evaluateTriggers`.** It runs on every sign-in of every user.
> - **Adding an alias that is not registered.** The action is skipped.
> - **Using `ignore()` for a mandatory action.** The user is not blocked and the action returns next time.
> - **Reading the form in `requiredActionChallenge`.** The submitted values arrive in `processAction`.
