# ATS092 — Development & SPI Customization (Keycloak)

Course material for the **Keycloak Development & SPI Customization** domain of
the Astrona Keycloak training path ([ATP018](https://github.com/astrona-io/ATP018)),
which is **15% of the path**. Written for **Keycloak 26.8.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Keycloak 26.8.1 documentation. The Java sources compile against the
> 26.8.1 artifacts, but no environment has been started on a cluster, no
> in-cluster build has run, and no lab has passed `astrona test` yet. See
> `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **A module** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining the section into a single
  scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Service Provider Interfaces | 1 | 1 + capstone | Providers, factories, loading |
| [020](sections/section-020) | Custom Authenticators | 1 | 1 + capstone | Authentication flows |
| [030](sections/section-030) | Event Listeners | 1 | 1 + capstone | User and admin events |
| [040](sections/section-040) | Themes With FreeMarker | 1 | 1 + capstone | Login theme |

The order starts with the mechanism and then builds on it. Section 010 teaches
how Keycloak finds and loads any provider, because every later extension fails
in the same quiet ways when that step is wrong. Sections 020 and 030 build the
two Java extensions teams write most often. Section 040 ends with themes, which
need no Java when mounted as a directory, and shows how they ship in the same
JAR as providers.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Build And Load Your First Keycloak Provider](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Add A Custom Step To An Authentication Flow](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Send Keycloak Events To Your Own Listener](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Change The Login Page With A Theme](sections/section-040/module-01/course.md) | 3 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Get A Broken Provider Build Running | a missing import, then a misspelled factory class in the services file |
| [020](sections/section-020/capstone/labs/lab-01) | Fix An Authenticator That Blocks The Wrong Users | an inverted check, and a flow bound to the whole realm instead of one client |
| [030](sections/section-030/capstone/labs/lab-01) | Audit Admin Changes With A Custom Listener | an empty admin event method, admin events off, `jboss-logging` removed |
| [040](sections/section-040/capstone/labs/lab-01) | Ship A Theme And A Listener In One JAR | a wrong theme name in `keycloak-themes.json`, a missing services file |

---

## How the builds work

No learner needs Java or Maven. Every environment has:

- the PVC `keycloak-providers`, mounted read-only at `/opt/keycloak/providers`
  in the Keycloak pod (`start-dev`, strategy `Recreate`);
- the PVC `maven-cache` for Maven's local repository;
- the ConfigMap `provider-source` with the source tree (a key is a file path
  with `/` written as `__`);
- the ConfigMap `build-provider-job` with the definition of the Job
  `build-provider` (`maven:3.9.15-eclipse-temurin-21`), which rebuilds the tree,
  runs `mvn -B -q package` and replaces the JAR in `keycloak-providers`.

Pages give the reader the helpers `upload_source`, `download_source` and
`build_provider`; `build_provider` also restarts Keycloak, which loads the JAR
when it starts. The reference sources were compiled with
`javac --release 17` against the Keycloak 26.8.1 JARs from Maven Central.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

The environment name is the playground's `metadata.name` in its `config.yaml`,
for example `ats-092-playground-010-01`. A playground fills the Maven cache when
it starts, so it takes several minutes the first time.

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades Keycloak's behaviour with independent checks, and several of
them deliberately reject the plausible-but-wrong fix (changing the users to fit
the code, removing `jboss-logging`, mounting a theme directory when the task
asks for a JAR).
