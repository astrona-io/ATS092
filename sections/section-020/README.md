# Section 020: Custom Authenticators

Keycloak signs a user in by running an authentication flow: an ordered list of steps, where each step checks one thing. The built-in steps check a username, a password or a one-time code. When your organisation has a rule Keycloak does not know, for example "only users with a department may sign in to this application", you add a step of your own: a custom authenticator.

This section teaches the whole path, from the Java code to the user who is let in or refused. You first learn to read flows, executions and requirements, because a correct authenticator in the wrong place, or with the wrong requirement, does nothing. Then you write the authenticator and its factory, build it, and wire it into a flow that only one client uses.

## What you will learn

- What an authentication flow, an execution and a requirement are, and which built-in flows a realm binds.
- How to read a flow's executions and a client's flow overrides with `kcadm.sh`.
- How to write an `Authenticator` and an `AuthenticatorFactory`, with requirement choices and a configuration property.
- How to copy a built-in flow, add your authenticator as a step, and set its requirement.
- How to bind a flow to one client, so the rest of the realm keeps its default flows.
- How to prove the result with one user who gets a token and one who is refused.

## The learning path

Work through the module in order. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Add A Custom Step To An Authentication Flow

The playground runs Keycloak 26.8.1 in the namespace `authenticator-demo`, with the realm `inventory`, the users `alice` (department `warehouse`) and `bob` (no department), and the client `inventory-cli`.

1. Authentication Flows, Executions And Requirements
2. Writing An Authenticator And Its Factory
3. Wiring An Authenticator Into A Flow, followed by the lab **Require A Department For Password Sign-In**
4. Summary

## Section capstone: Fix An Authenticator That Blocks The Wrong Users

The capstone combines the whole section. The department check is built, loaded and part of a flow, and yet `alice`, who has a department, is refused, while `bob`, who has none, gets a token. A second client that should not have the rule refuses users as well. One fault is in the Java code and one is in how the flow is bound. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-092-capstone-020
```
