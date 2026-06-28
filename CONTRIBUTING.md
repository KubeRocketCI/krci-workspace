# Contributing to krci-workspace

Thanks for your interest in improving **krci-workspace** — the development
workspace meta-repo for the [KubeRocketCI](https://docs.kuberocketci.io)
platform! Contributions of all kinds are welcome: bug reports, fixes, manifest
updates, documentation, and tooling improvements.

By participating you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## What this repo is

This repo is **orchestration**, not application code. It assembles a multi-repo
development workspace by cloning KubeRocketCI component repositories into a
(git-ignored) `sources/` directory. It tracks only:

| Path               | What lives here                                                   |
|--------------------|-------------------------------------------------------------------|
| `repos.yaml`       | Manifest — single source of truth for the component set           |
| `bootstrap.sh`     | Clones manifest repos into `sources/<name>/` (clone-or-skip)      |
| `git-pull-all.sh`  | Fast-forwards every repo under `sources/`                         |
| `CLAUDE.md`        | Workspace provisioning context for AI agents                      |
| `sources/CLAUDE.md`| Cross-component reference (tracked; the rest of `sources/` is not) |

## Ways to contribute

- **Report a bug** — open a [bug report](https://github.com/KubeRocketCI/krci-workspace/issues/new/choose)
  with your OS, `git`/`bash` versions, and the failing command.
- **Add or update a component** — edit `repos.yaml` only; `bootstrap.sh` and
  `.gitignore` are generic and should not need per-component changes.
- **Improve docs** — `CLAUDE.md`, `sources/CLAUDE.md`, and `README.md` are
  first-class; clarity fixes are very welcome.

## Development workflow

1. **Fork** the repo and create a topic branch off `main`.
2. **Make your change.** Keep `bootstrap.sh` idempotent — it must be safe to
   re-run, skipping repos that already exist.
3. **Validate locally:**

   ```bash
   ./bootstrap.sh --list        # manifest parses, all components listed
   ./bootstrap.sh               # clones into sources/ (or skips existing)
   git status                   # only meta files tracked; sources/ ignored
   ```
4. **Lint your shell.** Please run [`shellcheck`](https://www.shellcheck.net/) on
   any script you touch and keep YAML valid.
5. **Update docs.** If you change the manifest schema, scripts, or layout,
   update `CLAUDE.md` and `README.md`.

## Pull requests

- Keep PRs focused; one logical change per PR.
- Use clear, imperative commit messages (Conventional Commits style is
  appreciated, e.g. `feat:`, `fix:`, `docs:`, `chore:`).
- Fill in the PR template, including how you validated.
- By submitting a contribution you agree it is licensed under the
  [Apache License 2.0](LICENSE), consistent with the rest of this project.

## Reporting security issues

Please do **not** file public issues for vulnerabilities. Follow the
[Security Policy](SECURITY.md) instead.

## Questions

Open an [issue](https://github.com/KubeRocketCI/krci-workspace/issues),
or learn more about the platform at <https://docs.kuberocketci.io>.
