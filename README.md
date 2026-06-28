# krci-workspace

A thin **development workspace meta-repo** for the [KubeRocketCI](https://docs.kuberocketci.io)
platform. It clones all platform component repositories into one local workspace
so you can develop a feature across them at once.

It tracks only a manifest, two scripts, and docs — **not** the component source.
Each component is cloned as its own independent git repo (branch / commit / PR
per repo, no submodules).

## Quick start

```bash
git clone git@github.com:KubeRocketCI/krci-workspace.git
cd krci-workspace
./bootstrap.sh            # clone all components into sources/
```

## Commands

```bash
./bootstrap.sh                 # clone all components
./bootstrap.sh krci-portal cli # clone only named components
./bootstrap.sh --group devops  # clone a manifest group
./bootstrap.sh --list          # list components, clone nothing
./git-pull-all.sh              # git pull --ff-only every repo in sources/
```

## Layout

```
krci-workspace/
├── repos.yaml          # manifest — single source of truth for the component set
├── bootstrap.sh        # clones manifest repos into sources/ (clone-or-skip)
├── git-pull-all.sh     # fast-forwards every repo in sources/
├── CLAUDE.md           # workspace context for AI agents (provisioning)
└── sources/            # cloned components (git-ignored; tracked: sources/CLAUDE.md)
    ├── krci-portal/
    ├── edp-tekton/
    └── ...
```

Add or change a component by editing `repos.yaml`; nothing else needs to change.

## License

[Apache 2.0](LICENSE).
