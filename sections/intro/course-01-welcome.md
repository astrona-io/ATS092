# Welcome To The Course

This course trains you for the **Keycloak Development & SPI Customization** part of the Astrona **Keycloak** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You already run or administer Keycloak: you know realms, users, clients and tokens, and you have used the Admin Console or `kcadm.sh`. You know Kubernetes basics: Deployments, ConfigMaps, Jobs, volumes, `kubectl logs` and `kubectl exec`. You can read a short Java class and change a line in it. You do not need to be a Java developer, and you do not need Java or Maven on your machine: every build runs inside the cluster.

## What you can do at the end

Extending Keycloak means writing code that the server loads and runs, so this course does not ask you to remember interface names. It asks you to build an extension, load it, and prove with Keycloak's own behaviour that it works. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **Service Provider Interfaces**, the mechanism behind every extension. You will learn to:

- Explain what a Service Provider Interface (SPI), a provider and a provider factory are.
- Write a small provider, register it in `META-INF/services`, and build it into a JAR.
- Load the JAR into Keycloak, and prove that Keycloak loaded it.

The second topic is **custom authenticators**. You will learn to:

- Read authentication flows, executions and requirements.
- Write an authenticator and add it as a step to a flow that one client uses.

The third topic is **event listeners**. You will learn to:

- Explain user events and admin events.
- Write a listener that writes your own audit lines, and turn it on for a realm.

The fourth topic is **themes**. You will learn to:

- Change a login page by overriding one message in a theme that inherits the rest.
- Deliver a theme as a mounted directory and inside a JAR next to your providers.

Everything is written for **Keycloak 26.8.1**.

## The words this course uses

The pages use Keycloak's, Java's and Kubernetes' own terms, because those are the words you meet in the code, the console and the logs. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **Service Provider Interface (SPI)** is a Java interface that Keycloak defines for one kind of extension. A **provider** is one implementation of an SPI, and a **provider factory** is the class Keycloak loads at start to create providers. A **JAR** is the file that holds compiled Java classes and resource files; Keycloak loads JARs from its **providers directory**, `/opt/keycloak/providers`, only when it starts.

The course builds the same few things again and again:

| What you build | What it does |
| --- | --- |
| Realm resource provider `inventory-status` | Adds an HTTP endpoint that answers `inventory-status ok realm=inventory` |
| Authenticator `require-department-attribute` | Refuses a sign-in when the user has no department |
| Event listener `audit-log` | Writes an `AUDIT-LOG` line for every successful sign-in and every admin change |
| Login theme `inventory` | Changes the login page heading to `Sign in to Inventory` |

## The example setup in your playground

Every playground and lab runs the same setup. One Keycloak pod in development mode reads provider JARs from a volume. A Kubernetes Job builds those JARs with Maven: it reads your source files from a ConfigMap and writes the JAR into the volume. A second volume keeps Maven's downloads, so a rebuild is fast. You send test requests from the `tester` pod, a client with `curl` and `jq`.

Inside Keycloak, the realm is always `inventory`. The user `alice` signs in to it, through the command-line client `inventory-cli`. Each module puts this setup in its own namespace, for example `spi-demo` or `themes-demo`, so the pages always tell you the namespace to use. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with the mechanism every extension uses, then builds three kinds of extension on top of it.

| Section | What it covers |
| --- | --- |
| 010 | Service Provider Interfaces |
| 020 | Custom Authenticators |
| 030 | Event Listeners |
| 040 | Themes With FreeMarker |

Each section has one module, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command or the file to save, and then what the result shows. Run each step in your playground as you reach it.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea, and it removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type or save. Never change a command or a class name to make it "look right". If the result is different from what the page describes, that difference is the lesson.
