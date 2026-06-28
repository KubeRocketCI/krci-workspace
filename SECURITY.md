# Security Policy

## What this repository is

`krci-workspace` is a **development workspace meta-repo**. It contains only a
manifest (`repos.yaml`), helper shell scripts, and documentation. It does not
ship runtime code or deploy anything; `bootstrap.sh` clones KubeRocketCI
component repositories over your own authenticated git remotes into a local
(git-ignored) `sources/` directory.

Because it executes git clones and shell scripts on your machine, treat it like
any other tooling you run locally: review `repos.yaml` and the scripts before
running, and only clone over remotes you trust.

## Reporting a vulnerability

- **A vulnerability in this repo** (e.g. a script flaw, or a manifest pointing
  at an unexpected remote): please report it privately via
  [GitHub Security Advisories](https://github.com/KubeRocketCI/krci-workspace/security/advisories/new)
  or by email to **SupportEPMD-EDP@epam.com**. Please do not open a public issue
  for undisclosed vulnerabilities.
- **A vulnerability in KubeRocketCI itself**: report it through the
  [KubeRocketCI project](https://docs.kuberocketci.io) channels.
- **A vulnerability in a cloned component** (edp-tekton, krci-portal, the
  operators, etc.): report it to that component's upstream repository.

We aim to acknowledge reports within 5 business days.

## Supported versions

Only the latest `main` is maintained; there are no backports.
