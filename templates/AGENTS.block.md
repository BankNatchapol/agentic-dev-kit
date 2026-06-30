# Agentic Dev Kit: Local Token Optimization

This project uses local agent tooling installed under `__TARGET__/.agent-tools`.
Prefer those local binaries and configs over global tools.

- Use Serena for symbol search, references, and targeted code navigation before reading whole files.
- Use Context7 for external libraries, frameworks, SDKs, APIs, and configuration before guessing from memory.
- Use local RTK for noisy terminal output, especially tests, dependency installs, Git output, Docker output, and long logs.
- Use local Headroom diagnostics only through `__TARGET__/.agent-tools/headroom-venv/bin/headroom`.
- Use local ccusage through `npx ccusage@latest` or `__TARGET__/node_modules/.bin/ccusage` to measure token/cost usage.
- Preserve exact failing test names, error messages, file paths, and stack frames when summarizing compressed output.
- Do not use global installs, global hooks, `rtk init -g`, or global Headroom wrapping for this project.

