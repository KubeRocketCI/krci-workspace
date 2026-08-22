# KubeRocketCI Source Workspace

This workspace contains the full source code for the KubeRocketCI platform — a cloud-agnostic CI/CD platform built on Kubernetes. Use this file to orient yourself before scanning any individual repository.

> **Layout:** component repos live under `sources/<name>/`, each its own git repo. `sources/` is git-ignored so the meta-repo stays thin.
> **Searching across components:** `.ignore` re-includes `sources/` for ripgrep (`Grep`/`Glob`), so a root-level `rg "<pattern>"` covers every component while each component's own `.gitignore` still filters its subtree. Scope to a path — `rg "<pattern>" sources/krci-portal/` — to narrow it. Add `--hidden` to reach repo-root dotfiles such as `.golangci.yaml`.
> **List components:** `./bootstrap.sh --list`.

## Workspace Commands

```bash
./bootstrap.sh                 # clone all components into sources/
./bootstrap.sh krci-portal cli # clone only named components
./bootstrap.sh --group devops  # clone a manifest group
./bootstrap.sh --list          # list components, clone nothing
./git-pull-all.sh              # git pull --ff-only every repo in sources/
```

Components & groups are defined in `repos.yaml` (single source of truth).

## Component Reference

Deep-dive descriptions of every component — platform architecture, per-repo details, CRD groups, data flow, and agent tips — live in **`sources/CLAUDE.md`** (auto-loaded when working under `sources/`).

For a fresh engagement: after `./bootstrap.sh`, run `/init` (or the CLAUDE.md improver) inside `sources/` to populate that file with the cloned components' descriptions.
