---
name: agentic-token-optimization
description: Use in repos installed with agentic-dev-kit when coding tasks may involve large files, logs, tests, dependency output, external docs, or token/cost measurement. Prefer local project tools over global installs.
---

# Agentic Token Optimization

Use this skill to keep coding-agent context focused and local-first.

## Local Tool Paths

- RTK: `__TARGET__/.agent-tools/rtk/bin/rtk`
- Serena: `__TARGET__/.agent-tools/serena-venv/bin/serena`
- Headroom: `__TARGET__/.agent-tools/headroom-venv/bin/headroom`
- Context7 MCP: `__TARGET__/node_modules/.bin/context7-mcp`
- ccusage: `__TARGET__/node_modules/.bin/ccusage`

## Workflow

1. Start with targeted repo discovery.
2. Use Serena for symbol search, references, and code navigation before reading full files.
3. Use Context7 before changing code that depends on external libraries, frameworks, SDKs, APIs, or config.
4. Use RTK for noisy shell commands and long output. Preserve exact errors, file paths, failing tests, and stack frames.
5. Use ccusage to compare token/cost usage before and after workflow changes.
6. Use Headroom only through the local venv for diagnostics or explicit compression experiments.

## Local-Only Rules

- Do not run `brew install`.
- Do not run `npm install -g`.
- Do not run `uv tool install`.
- Do not run `rtk init -g`.
- Do not configure global Claude or Codex hooks.
- Do not globally wrap Claude, Codex, or another agent with Headroom.

If a needed integration cannot be fully automated locally, explain the manual local step and keep all generated files inside the target repo whenever possible.

