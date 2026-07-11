# code-server-claude

Container image for a remotely-accessible **[code-server](https://github.com/coder/code-server)** (browser VS Code) workspace with the **[Claude Code](https://docs.claude.com/en/docs/claude-code)** CLI and a **[mise](https://mise.jdx.dev/)**-driven polyglot dev toolchain baked in.

Deployed on the `qcluster` Talos Kubernetes cluster and consumed by
[`talos-cluster/applications/code-server/`](https://github.com/arne-de-both/talos-cluster).

## What's in the image

| Component | Detail |
|---|---|
| Base | `codercom/code-server:4.127.0` (user `coder`, uid 1000) |
| CLI | `@anthropic-ai/claude-code` (global, on system Node 22 LTS) |
| Runtimes | none baked — installed per-project via `mise` onto the persistent PVC |
| Build toolchain | `build-essential`, `python3`, `pkg-config`, classic `-dev` libs |
| Version manager | `mise` v2026.7.5 (activated system-wide via `/etc/bash.bashrc`) |

Language runtimes (Node, Java, Python, Go, …) are **not** baked in — run
`mise use <tool>@<version>` inside the workspace; they install to `~/.local/share/mise`
on the persistent volume.

## Build

Built automatically by a **github-arc** self-hosted runner scale set
(`runs-on: code-server-builders`, `containerMode: dind`) on push to `main` and
pushed to `ghcr.io/arne-de-both/code-server-claude`. The Kubernetes Deployment
pins the image **by digest** (printed in each run's summary).

Trigger manually: **Actions → build → Run workflow**.
