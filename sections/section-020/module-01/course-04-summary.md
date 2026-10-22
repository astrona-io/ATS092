# Summary

Keycloak signs a user in by running an authentication flow, an ordered list of steps called executions. Each execution runs one authenticator, the Java code that checks one thing, and has a requirement. `REQUIRED` makes the flow fail when the step fails, `ALTERNATIVE` lets one of several steps succeed, `CONDITIONAL` runs a sub-flow under a condition, and `DISABLED` never runs the step at all. A realm binds one flow per purpose, such as `browser` and `direct grant`, and a client can override a binding for itself.

An authenticator implements `Authenticator`. Keycloak calls `authenticate()` with an `AuthenticationFlowContext`, and the method ends with `success()` or `failure()`. A step that reads the user returns `true` from `requiresUser()`. In a direct grant, a failure sends a JSON body in the OAuth 2.0 error format, because the client expects JSON. The factory implements `AuthenticatorFactory`: its id is the name a flow uses, `getRequirementChoices()` limits what an administrator may pick, and `getConfigProperties()` declares settings that an execution's configuration can change without a new build.

A loaded authenticator changes nothing until it is wired in. You copy a built-in flow instead of changing it, add an execution with the authenticator's provider id, and set the execution to `REQUIRED`, because a new execution starts `DISABLED`. You then bind the copy to one client through `authenticationFlowBindingOverrides`, with the flow's id, so the realm's own binding stays the same for every other client. In Keycloak 26, a user attribute that the user profile does not declare is dropped unless the realm allows unmanaged attributes. The key facts to remember are these:

- Code, flow and binding are three separate places; check all three when a rule does nothing.
- A new execution is `DISABLED`; set it to `REQUIRED` on purpose.
- A client override takes the flow's id under the key `direct_grant` or `browser`.
- Prove a rule with one user who passes and one who is refused.

<!-- astrona:playground:destroy -->
