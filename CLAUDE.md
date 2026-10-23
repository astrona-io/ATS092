# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS092 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Keycloak Development & SPI Customization** domain
  of the **Keycloak** training path (`ATP018`). It is 15% of the path. There is
  no official Keycloak certification exam; the path's domains and weights are
  Astrona's own, set in `ATP018/path.yaml`.
- **What the domain really tests:** extending a running Keycloak with your own
  code, not remembering interface names. The student must *do* things (write a
  provider and its factory, register it in `META-INF/services`, build a JAR,
  load it into Keycloak, prove it is loaded, wire an authenticator into a flow,
  enable an event listener, set a theme). Every explanation should lead to
  something they build or run, and every fix should be proved with Keycloak's
  behaviour: an endpoint that answers, a token that is issued or refused, a
  log line, a login page that shows the new text.
- **The four topics:** Service Provider Interfaces and how Keycloak loads
  providers, custom authenticators, event listeners, and themes. The README
  table maps each section to its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Service Provider Interfaces | Providers, factories, loading |
  | 020 | Custom Authenticators | Authentication flows |
  | 030 | Event Listeners | User and admin events |
  | 040 | Themes With FreeMarker | Login theme |

- **The version:** everything is written for **Keycloak 26.8.1**, image
  `quay.io/keycloak/keycloak:26.8.1`, on a single-node `kind` cluster. Java is
  compiled against the 26.8.1 artifacts from Maven Central. Do not teach
  interfaces, fields or output from other versions without saying so. The
  SPIs used here (except the theme layout) are internal Keycloak APIs that can
  change in any release; say so where a page introduces one.
- **The main sources:** the Server Developer Guide,
  <https://www.keycloak.org/docs/latest/server_development/index.html>, the
  UI customization guide for themes, <https://www.keycloak.org/ui-customization/themes>,
  and the Keycloak quickstarts repository. Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Keycloak 26.8.1
documentation **without a live run**. The Java sources were compiled with
`javac --release 17` against the 26.8.1 JARs from Maven Central
(`keycloak-server-spi`, `keycloak-server-spi-private`, `keycloak-core`,
`jakarta.ws.rs-api` 3.1.0, `jboss-logging` 3.6.1.Final), so the signatures are
right. Nothing else has been run: no playground or lab has been started, no
Maven build has run in the cluster, and no `astrona test` has passed yet. Until
a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

### Terms, not metaphors

Explanations use Keycloak's, Java's and Kubernetes' own words. Define each one
in plain technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Service Provider Interface (SPI) | A Java interface Keycloak defines for one kind of extension, for example `EventListener` or `Authenticator`; code that implements it plugs into the server |
| Provider | One implementation of an SPI. Keycloak creates provider objects while it handles a request |
| Provider factory | The class Keycloak loads at start for each provider; it has an id (`getId()`) and creates the provider objects (`create()`) |
| `KeycloakSession` | The object that gives a provider access to the current request, realm, users and other providers |
| `META-INF/services/<factory interface>` | A text file in the JAR, named after the factory interface, that lists the factory classes; Java's `ServiceLoader` reads it |
| `providers` directory | `/opt/keycloak/providers`; every JAR in it is loaded when Keycloak builds itself |
| `kc.sh build` | Builds an optimized server with the current providers and build options; `start-dev` and a non-optimized `start` do this on every start |
| Realm resource provider | The SPI `realm-restapi-extension`: a provider that adds an HTTP endpoint under `/realms/<realm>/<provider id>` |
| Authentication flow / execution | An ordered list of steps Keycloak runs to sign a user in / one step in that list, backed by one authenticator |
| Requirement | How an execution counts: `REQUIRED`, `ALTERNATIVE`, `CONDITIONAL` or `DISABLED` |
| `Authenticator` / `AuthenticatorFactory` | The step's code (`authenticate()`, `action()`) / its factory, which also gives the display name, requirement choices and configuration properties |
| `AuthenticationFlowContext` | The object an authenticator receives; it holds the user and the request and takes the result (`success()`, `failure()`) |
| Event listener | A provider (`EventListenerProvider`) that Keycloak calls for every user event and admin event in the realms that enable it |
| User event / admin event | `Event`, for example `LOGIN` or `LOGIN_ERROR` / `AdminEvent`, a change made through the Admin REST API, for example `CREATE` on a `USER` |
| Theme / theme type | A set of templates, messages and static files / which pages it styles: `login`, `account`, `email`, `admin`, `welcome` |
| FreeMarker | The template language of Keycloak's pages (`.ftl` files); `${msg("key")}` prints a message from the theme's message files |
| `theme.properties` | The theme's settings file; `parent=` names the theme it inherits every file it does not override from |

Do not invent friendly names for these (no "plug-in slot", "the hook", "the
skin"). The product's names are what the student meets in the code, the
console and the logs.

### The example workloads

Every module deploys the same setup into its own namespace (`spi-demo`,
`authenticator-demo`, `events-demo`, `themes-demo`; capstones use
`spicapstone-demo`, `authcapstone-demo`, `eventscapstone-demo` and
`themescapstone-demo`).

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `keycloak` (Deployment and Service) | `quay.io/keycloak/keycloak:26.8.1` | One Keycloak pod in development mode (`start-dev`), strategy `Recreate`. Mounts the PVC `keycloak-providers` read-only at `/opt/keycloak/providers`. Service ports `8080` and `9000` |
| `keycloak-admin` (Secret) | | Bootstrap administrator `admin` / `admin`. Lab-only credentials; say so when a page uses them |
| `keycloak-providers` (PVC, 1 GiB) | | Holds the provider JAR. The build Job writes it, Keycloak reads it |
| `maven-cache` (PVC, 2 GiB) | | Maven's local repository (`/root/.m2`), so a second build does not download everything again |
| `provider-source` (ConfigMap) | | The provider's source tree. A key is the file path with `/` written as `__`, for example `src__main__java__io__astrona__keycloak__inventory__InventoryStatusResource.java` |
| `build-provider-job` (ConfigMap) | | The `build-provider` Job's definition (key `job.yaml`), so the `build_provider` helper needs no file on the reader's machine |
| `build-provider` (Job) | `maven:3.9.15-eclipse-temurin-21` | Copies the ConfigMap back into a source tree, runs `mvn -B -q package`, and replaces the JAR in `keycloak-providers` |
| `tester` | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Every test request is sent from here |

Inside Keycloak, every module uses the same names:

| Keycloak name | What it is |
| --- | --- |
| realm `inventory` | The application realm |
| user `alice` | Password `alice-password`, complete profile; in section 020 she has the attribute `department=warehouse` |
| user `bob` | Password `bob-password`, complete profile, no `department` attribute (section 020 only) |
| client `inventory-cli` | Public client with direct access grants on; used for password-grant token requests |
| client `inventory-report-cli` | A second public client with direct access grants on; the section 020 capstone uses it to prove a flow is bound to one client only |
| client `inventory-web` | Public client with the standard flow and redirect URI `http://localhost/*`; used to fetch the login page (section 040 only) |

The Java package is `io.astrona.keycloak.inventory`. The provider ids are
`inventory-status` (realm resource provider), `require-department-attribute`
(authenticator) and `audit-log` (event listener); the theme is `inventory`.
The audit listener writes lines that start with `AUDIT-LOG`, for example
`AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice`.

The password grant is used **only** so a grader and the reader can sign a user
in from a terminal. Say every time it is used that OAuth 2.1 drops it and a
real application uses the authorization code flow.

### Environment facts the text must respect

- **The build runs in the cluster.** The reader needs no Java or Maven on
  their machine. The reader saves source files from the page, uploads them
  with `upload_source`, and runs `build_provider`. The first build downloads
  the Keycloak artifacts and Maven plugins from Maven Central, so it needs
  outbound internet and takes a few minutes; later builds reuse `maven-cache`.
  Playgrounds warm the cache at start with a `warm-maven-cache` Job.
- **The reader-side helpers** are the same everywhere. Define them on the first
  page of a module that needs them, with these names: `kcadm` (signs in on
  every call, so it survives Keycloak restarts), `upload_source DIR`,
  `download_source DIR` (labs that start from existing source),
  `build_provider` (runs the Job, shows its log, restarts Keycloak), and
  `get_user_token USER PASSWORD`.
- **Loading needs a restart.** Keycloak reads the providers directory only
  when it builds itself at start. `start-dev` builds on every start, so a
  restart (`kubectl rollout restart deployment/keycloak`) loads a new JAR. In
  production the image runs `kc.sh build` once and starts with `--optimized`.
- **A wrong `META-INF/services` file is silent.** A services file with the
  wrong name means Keycloak never sees the factory; nothing is logged. A
  services file that names a class that does not exist makes the build at
  start fail, and the pod restarts. Pages must say which symptom belongs to
  which mistake.
- **`kcadm get --fields` and maps (seen on a live run, 2026-10-23).** A
  map field such as `authenticationFlowBindingOverrides` or `attributes`
  prints `{}` unless the filter names its keys:
  `--fields 'authenticationFlowBindingOverrides(direct_grant)'`,
  `--fields 'attributes(department)'`. A key with dots cannot be named;
  read the whole object and use `jq`. Arrays (`eventsListeners`) print fine.
- **Keycloak 26.8.1 facts (from the documentation and the compiled API, not
  yet seen on a run):**
  - `RealmResourceProvider`, `RealmResourceProviderFactory`, `Authenticator`,
    `AuthenticatorFactory`, `EventListenerProvider` and
    `EventListenerProviderFactory` are all in `keycloak-server-spi-private`.
    `OAuth2ErrorRepresentation` is in `keycloak-core`.
  - A realm resource provider's resource class needs the
    `jakarta.ws.rs.ext.Provider` annotation, and the JAR needs an empty
    `META-INF/beans.xml`.
  - `AdminEvent` has `getRealmName()`; `Event` has `getRealmName()` too, but
    the listener looks the realm up by id when the name is missing.
  - User attributes: Keycloak 26 keeps only attributes that the realm's user
    profile declares. Section 020 sets the realm's
    `unmanagedAttributePolicy` to `ENABLED` so `department` is kept; pages say
    so.
  - Theme archive: `META-INF/keycloak-themes.json` lists
    `{"themes": [{"name": ..., "types": [...]}]}`, and the files live under
    `theme/<name>/<type>/` in the JAR. A theme directory lives at
    `/opt/keycloak/themes/<name>/<type>/`.
  - Theme caching is switched off with `--spi-theme--cache-themes=false`,
    `--spi-theme--cache-templates=false` and `--spi-theme--static-max-age=-1`.
  - The theme in this course uses `parent=keycloak`; its login page prints
    the message `loginAccountTitle` as the page heading.
- **Many environments start broken on purpose.** A lab uploads faulty source,
  builds it, and starts Keycloak with the result, or leaves a flow or realm
  setting wrong. The fault is the material. Never "fix" it in the bootstrap.
- **The proof is Keycloak's behaviour.** A fix is proven with a request from
  `tester` (the endpoint answers, a token is issued or refused, the login page
  shows the text) or a line in `kubectl logs deploy/keycloak`, plus
  `kcadm get serverinfo` listing the provider where that matters.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-deploy-keycloak.sh`, `02-seed-state.sh` | Keycloak, the PVCs and the realm, then the starting state (often a faulty build) |
| `manifests/` | `lab-start.yaml`, `job-build-provider.yaml`, and `provider-source/` (the starting source tree) where the lab has one |
| `solution/apply.sh`, `solution/provider-source/` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-keycloak.sh` | Waits until Keycloak answers before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS092`, domain
`Keycloak Development & SPI Customization`, weight `15`) and one entry per
section under `modules:` (`module-010` to `module-040`). Each section's
`content` lists, in order: the section `README.md`, then for each module its
landing page, its parts, and right after the part a lab tests, a `Question`
reading followed by the `type: lab` entry; the module's closing page comes
last. The section capstone closes the section. Playgrounds are not listed.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, including one build.
- `topic`: exactly one of `spi-basics`, `authenticators`, `event-listeners`,
  `themes`, `packaging`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `keycloak.org`, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- SPI: `spi`, `provider-factory`, `meta-inf-services`, `providers-directory`,
  `kc-build`, `serverinfo`, `realm-resource-provider`, `maven-build`
- Authentication: `authenticator`, `authentication-flow`, `direct-grant-flow`,
  `execution-requirement`, `flow-binding`, `authenticator-config`,
  `user-attributes`, `password-grant`
- Events: `event-listener`, `user-events`, `admin-events`, `events-config`,
  `jboss-logging`
- Themes: `login-theme`, `freemarker`, `theme-properties`, `messages`,
  `theme-jar`, `theme-directory`
- Kubernetes: `configmap`, `kubernetes-job`, `persistent-volume`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-010/module-01/playground
astrona destroy ats-092-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-092-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-092-playground-<section>-<module>`, a module lab
is `ats-092-lab-<section>-<module>` and a capstone is
`ats-092-capstone-<section>`; keep those names. Lab bootstrap scripts do not
pin a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**: the endpoint answers, the right user gets a token
and the wrong one does not, the log line appears, the login page shows the
text. Graders also reject the plausible but wrong fix (changing the users'
attributes to fit a bug in the code, removing the default `jboss-logging` listener,
mounting a theme directory when the task asks for a JAR). A lab's
`question.md` and `solution.md` must match what its `validation/` scripts
actually check.

Test clusters on the maintainer's machine: one at a time. Keycloak needs
about 1 GiB of memory, and a build Job about 1 GiB more while it runs.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Extending the server:**
  [Server Developer Guide](https://www.keycloak.org/docs/latest/server_development/index.html)
  (Service Provider Interfaces, authentication SPI, event listener SPI, custom
  REST endpoints)
- **Themes:** [UI customization: themes](https://www.keycloak.org/ui-customization/themes)
- **Java API:** [Keycloak Javadoc](https://www.keycloak.org/docs-api/latest/javadocs/),
  and the 26.8.1 artifacts on Maven Central (`org.keycloak:keycloak-server-spi-private`)
- **Configuration:** [all configuration options](https://www.keycloak.org/server/all-config),
  [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html)
  (authentication flows, events)
- **Examples:** the `keycloak/keycloak-quickstarts` repository on GitHub
  (`extension/` folder)

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
