# agentic-dev-kit

A local-first starter kit for agentic coding workflows.

`agentic-dev-kit` installs token and context optimization tools into a target project so Claude Code and Codex can work with less noisy context. Phase 1 excludes Caveman and focuses on local-only setup.

## What It Installs

| Tool | Purpose | Local install target |
| --- | --- | --- |
| RTK | Compress noisy terminal output before it enters agent context | `.agent-tools/rtk` |
| Headroom | Broader context/tool-output compression diagnostics | `.agent-tools/headroom-venv` |
| ccusage | Token and cost measurement | local npm dev dependency |
| Serena | Token-efficient symbol navigation and code retrieval | `.agent-tools/serena-venv` |
| Context7 | Current docs lookup for libraries and APIs | local npm dev dependency |

## Local-First Policy

Default install never runs:

- `brew install`
- `npm install -g`
- `uv tool install`
- global Claude hooks
- global Codex hooks
- `rtk init -g`
- global Headroom agent wrapping

Most files are written inside the target repo. Some agent CLIs may store project-scoped registration metadata outside the repo, tied to the project path. That is documented and avoided where possible.

## Quick Start

From this repo:

```bash
scripts/doctor.sh --target /path/to/your/project --agents claude,codex
scripts/install.sh --target /path/to/your/project --agents claude,codex
scripts/status.sh --target /path/to/your/project --agents claude,codex
```

`install.sh` is the main setup command. `doctor.sh` checks prerequisites before install, and `status.sh` verifies the result after install.

## Prerequisites

`doctor.sh` checks the tools needed for a complete local install:

- `git`
- `node`, `npm`, and `npx`
- `uv` for local Serena and Headroom virtual environments
- `cargo` for the local RTK source install
- `claude` when configuring Claude Code
- `codex` when configuring Codex

If `uv` or `cargo` is missing, the installer keeps the setup local and skips the affected tool instead of using a global package manager.

When prerequisites are missing, `doctor.sh` prints exact next-step commands. To opt into installing supported missing prerequisites, run:

```bash
scripts/doctor.sh --target /path/to/your/project --agents claude,codex --install-prereqs
```

This can install:

- `uv` with the official Astral installer
- Rust/Cargo with `rustup`

It does not automatically install Node.js, Git, Claude Code, or Codex because those depend more on your preferred system setup and login flow.

For the current directory:

```bash
scripts/install.sh
```

To remove the setup:

```bash
scripts/uninstall.sh --target /path/to/your/project --agents claude,codex
```

## Generated Target Layout

```text
your-project/
  .agent-tools/          # local binaries, venvs, and tool state
  .agents/
    skills/
      agentic-token-optimization/
        SKILL.md         # repo-scoped Codex/agent skill
  .claude/               # Claude local settings/templates
  .codex/
    config.toml          # project MCP config for Codex
  AGENTS.md              # Codex project guidance
  CLAUDE.md              # Claude Code project guidance
```

Generated guidance and config blocks are wrapped with `agentic-dev-kit` markers so uninstall can remove only what this kit created.

## Commands

```bash
scripts/install.sh [--target PATH] [--agents claude,codex] [--no-tools] [--no-agent-config]
scripts/uninstall.sh [--target PATH] [--agents claude,codex] [--no-tools] [--no-agent-config]
scripts/doctor.sh [--target PATH] [--agents claude,codex]
scripts/status.sh [--target PATH] [--agents claude,codex]
```

`--no-tools` writes guidance/config only. `--no-agent-config` skips agent CLI registration and only writes repo-local files. `doctor.sh --install-prereqs` opts into installing supported missing prerequisites.

## Claude Code Support

The installer writes `CLAUDE.md` and attempts to register local-scope MCP entries for:

- Serena, using the local venv binary
- Context7, using the target repo npm binary

Claude Code may store local-scope MCP metadata in user config tied to the project path. The installer never creates global hooks or global tool installs.

Verify inside Claude Code:

```text
/mcp
```

## Codex Support

The installer writes:

- `AGENTS.md` for project instructions
- `.codex/config.toml` for project MCP entries
- `.agents/skills/agentic-token-optimization/SKILL.md` as a repo-scoped skill

Codex project config loads for trusted projects. Verify from the target repo with:

```text
/mcp
```

## Local Usage Notes

Prefer local paths in generated guidance:

```bash
.agent-tools/rtk/bin/rtk --version
.agent-tools/headroom-venv/bin/headroom doctor
node_modules/.bin/ccusage
```

Do not run `rtk init -g` or `headroom wrap claude` as part of the default workflow. Those are future opt-in automation paths.

## Troubleshooting

Run:

```bash
scripts/doctor.sh --target /path/to/project
scripts/status.sh --target /path/to/project
```

Common issues:

- Missing `uv`: Serena and Headroom venv installs are skipped.
- Missing `cargo`: RTK local source install is skipped.
- Missing `claude`: Claude MCP registration is skipped, but repo files are still generated.
- Codex does not show MCP servers: confirm the project is trusted and inspect `.codex/config.toml`.
- Context7 binary missing: confirm `npm install` completed in the target repo.

## Future Phases

- Phase 2: optional local automation hooks for RTK and Headroom after the manual flow is trusted.
- Phase 3: broader coding-agent productivity stack with browser testing, GitHub/PR tooling, CI debugging, and security scanning.
- Phase 4: package this starter as a Codex plugin or distributable template.
- Phase 5: add dashboards and reports around ccusage and session-level token savings.
