# Showing A Form From An Authenticator

An authenticator does not only accept or refuse. It can also stop the flow, show the user a page, and read the answer. This is how a one-time code, a question or a consent page works. This part explains the methods an authenticator uses to talk to the user and the six outcomes it can report to the flow.

## The two methods

An `Authenticator` has an `authenticate(AuthenticationFlowContext context)` method and an `action(AuthenticationFlowContext context)` method. Keycloak calls `authenticate` when the flow reaches the step. If the step needs input from the user, `authenticate` builds a page and returns it with `context.challenge(response)`. The browser shows the page. When the user submits the form, Keycloak calls `action` of the same authenticator, and `action` reads the submitted values and decides.

Two more methods tell Keycloak when the step applies. `requiresUser()` returns true when the step needs a user to be known already. `configuredFor(session, realm, user)` returns true when this user can use the step, for example when a one-time password device exists. `setRequiredActions(session, realm, user)` runs when `configuredFor` is false and the step is required, so the authenticator can add a required action to the user.

## The outcomes of a step

The context offers a fixed set of outcomes. Each one tells the flow what to do next:

- `context.success()` accepts the step and the flow continues.
- `context.challenge(response)` shows a page and waits for a form post.
- `context.failureChallenge(error, response)` shows the page again with an error, for example after a wrong code.
- `context.failure(error)` ends the flow with an error and no page.
- `context.attempted()` marks the step as not applicable, and the flow tries the next alternative.
- `context.forceChallenge(response)` shows a page even in a flow that would otherwise not stop.

The error is a value of `AuthenticationFlowError`, for example `INVALID_CREDENTIALS`, `INVALID_USER`, `USER_DISABLED` or `ACCESS_DENIED`. For a direct grant request, which has no page, a `failure` becomes the error response of the token endpoint.

## Building a page with LoginFormsProvider

The authenticator gets the form builder from the context, `context.form()`, which is a `LoginFormsProvider`. Its calls return the builder, so you chain them. `setAttribute(name, value)` makes a value available in the FreeMarker template. `setError(messageKey)` adds an error message that the template shows. `createForm("department.ftl")` renders the template with that file name from the realm's login theme and returns the `Response`. `createLoginUsernamePassword()` renders the standard username and password page.

```java
@Override
public void authenticate(AuthenticationFlowContext context) {
    Response page = context.form()
            .setAttribute("username", context.getUser().getUsername())
            .createForm("department.ftl");
    context.challenge(page);
}

@Override
public void action(AuthenticationFlowContext context) {
    MultivaluedMap<String, String> form =
            context.getHttpRequest().getDecodedFormParameters();
    String department = form.getFirst("department");
    if (department == null || department.isBlank()) {
        Response page = context.form()
                .setError("missingDepartment")
                .createForm("department.ftl");
        context.failureChallenge(AuthenticationFlowError.INVALID_CREDENTIALS, page);
        return;
    }
    context.getUser().setSingleAttribute("department", department);
    context.success();
}
```

The template `department.ftl` must exist in the login theme of the realm, and the message key `missingDepartment` must exist in its message file. A missing template is not found at build time; the user gets an error page when the step runs.

## Browser flows and direct grant flows

A page can only be shown in a flow that has a browser. In the browser flow, `challenge` works. The direct grant flow answers a plain HTTP request from a client, so it has no page: an authenticator in that flow reads the values from the request and calls `success` or `failure`. Write an authenticator for the flow it will run in, and note that the same class can be put in both only when it handles both cases.

You now know the two methods, the six outcomes and how a page is built. The open question is how an administrator changes the behaviour of an authenticator without a new JAR.

## Common pitfalls

> [!WARNING]
> - **Calling `challenge` in a direct grant flow.** There is no browser to show the page. Use `success` or `failure`.
> - **Using `failure` for a wrong value on a page.** Use `failureChallenge`, so the user sees the form again with an error.
> - **Forgetting the template or message key.** The class builds and loads; the page fails when the step runs.
> - **Changing the user and expecting an immediate write.** The change is saved when the request's transaction commits.
