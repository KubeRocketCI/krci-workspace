<!-- Thanks for contributing to krci-workspace! -->

## What does this PR do?

<!-- A clear, concise description of the change and the motivation. -->

## Related issue

<!-- e.g. Closes #123. Remove if not applicable. -->

## Type of change

- [ ] Bug fix (non-breaking)
- [ ] Manifest change (add/update/remove a component in `repos.yaml`)
- [ ] Tooling / scripts (`bootstrap.sh`, `git-pull-all.sh`)
- [ ] Documentation (`CLAUDE.md`, `sources/CLAUDE.md`, `README.md`)
- [ ] Other (please describe)

## How was this validated?

```text
# paste relevant output / result here
```

- [ ] `./bootstrap.sh --list` parses the manifest and lists all components
- [ ] `./bootstrap.sh` clones into `sources/` (or skips existing) without error
- [ ] `git status` shows only meta files tracked; `sources/` stays ignored

## Checklist

- [ ] Change is idempotent (`bootstrap.sh` safe to re-run)
- [ ] `shellcheck` is clean on any modified scripts
- [ ] `CLAUDE.md` / `README.md` updated if the manifest schema, scripts, or layout changed
- [ ] I agree my contribution is licensed under Apache-2.0
