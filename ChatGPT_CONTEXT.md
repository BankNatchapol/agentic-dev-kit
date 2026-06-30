Yes — **Headroom and Caveman are not the same type of optimization**.

| Tool                  | Main target                         | What it does                                                                                                                                                                                          | Best for                                                       |
| --------------------- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| **Headroom**          | **Input/context tokens**            | Compresses what the agent reads before it reaches the LLM: tool outputs, logs, RAG chunks, files, conversation history. It can run as library, proxy, agent wrapper, or MCP server. ([PyPI][1])       | Long coding sessions, logs, large files, RAG, repeated context |
| **Caveman**           | **Output tokens**                   | Makes the agent answer much shorter. Its README says it mainly affects output tokens, not hidden thinking/reasoning tokens. ([GitHub][2])                                                             | Reducing verbose Claude/Codex replies                          |
| **RTK**               | **Terminal command output**         | A CLI proxy that filters/compresses command output before it enters LLM context; claims 60–90% reduction on common dev commands, with 100+ supported commands and low overhead. ([GitHub][3])         | `npm install`, tests, git logs, Docker logs, CI logs           |
| **code-review-graph** | **Codebase exploration tokens**     | Builds a Tree-sitter code graph so the agent reads targeted functions/classes/files instead of large parts of the repo. It reports ~82× median per-question reduction in its benchmark. ([GitHub][4]) | Large repos, PR review, “understand this codebase”             |
| **Serena MCP**        | **Semantic code retrieval/editing** | Gives the agent IDE-like symbol search, references, refactoring, and memory, so it can inspect code by structure instead of reading full files. ([GitHub][5])                                         | Long-term coding-agent workflow                                |
| **LLMLingua**         | **General prompt compression**      | Microsoft’s prompt compression project; uses smaller models to remove non-essential tokens and reports up to 20× compression with minimal performance loss. ([GitHub][6])                             | RAG, long prompts, custom apps                                 |
| **ccusage**           | **Monitoring, not compression**     | Reads local coding-agent usage logs and shows daily/weekly/monthly/session token and cost reports across Claude Code, Codex, OpenCode, Gemini CLI, etc. ([ccusage][7])                                | Knowing where tokens are spent                                 |

My practical recommendation for your coding-agent workflow:

**1. Start with Caveman** if your pain is “Claude talks too much.”
It is simple and low-risk because it mostly changes style/output. But it will not solve the biggest token cost if the agent is reading huge files/logs.

**2. Add RTK** if your sessions run many terminal commands.
This is probably one of the highest-value tools for Claude Code/Codex because raw test/build/log output can flood context.

**3. Add Headroom** if you want a broader compression layer.
Headroom is more general than RTK: not only shell output, but also logs, files, RAG chunks, and conversation history. It is closer to “context compression middleware.” ([PyPI][1])

**4. Add code-review-graph or Serena** if your repo is large.
These reduce the need to read full files in the first place, which is often better than compressing after reading.

**5. Use built-in context hygiene too.**
Claude Code docs recommend `/clear` between unrelated tasks and `/compact <instructions>` for controlled context summarization; long sessions can fill with irrelevant conversation, files, and commands, reducing performance. ([Claude][8])

**Good stack:**

```text
Caveman          = shorter agent replies
RTK              = cleaner terminal output
Headroom         = broader input/tool/context compression
Serena or code-review-graph = smarter code retrieval
ccusage          = measure token/cost usage
```

For you, I’d try this order:

```text
Caveman → RTK → ccusage → Serena/code-review-graph → Headroom
```

Why not Headroom first? Because RTK + Caveman are easier to reason about. Headroom is more powerful, but compression middleware can sometimes remove details you actually need for debugging, so I’d add it after you already know your token baseline.

[1]: https://pypi.org/project/headroom-ai/ "headroom-ai · PyPI"
[2]: https://github.com/juliusbrussee/caveman "GitHub - JuliusBrussee/caveman:  why use many token when few token do trick — Claude Code skill that cuts 65% of tokens by talking like caveman · GitHub"
[3]: https://github.com/rtk-ai/rtk "GitHub - rtk-ai/rtk: CLI proxy that reduces LLM token consumption by 60-90% on common dev commands. Single Rust binary, zero dependencies · GitHub"
[4]: https://github.com/tirth8205/code-review-graph "GitHub - tirth8205/code-review-graph: Local-first code intelligence graph for MCP and CLI. Builds a persistent map of your codebase so AI coding tools read only what matters, with benchmarked context reductions on reviews and large-repo workflows. · GitHub"
[5]: https://github.com/oraios/serena "GitHub - oraios/serena: A powerful MCP toolkit for coding, providing semantic retrieval and editing capabilities  - the IDE for your agent · GitHub"
[6]: https://github.com/microsoft/LLMLingua "GitHub - microsoft/LLMLingua: [EMNLP'23, ACL'24] To speed up LLMs' inference and enhance LLM's perceive of key information, compress the prompt and KV-Cache, which achieves up to 20x compression with minimal performance loss. · GitHub"
[7]: https://ccusage.com/guide/?utm_source=chatgpt.com "Introduction"
[8]: https://code.claude.com/docs/en/best-practices "Best practices for Claude Code - Claude Code Docs"

For your **agentic coding AI**, I’d install this stack:

```text
Core stack:
Headroom + RTK + Serena + Context7 + ccusage

Optional:
Caveman
```

### My recommended setup

| Install        | Why you need it                                                                                                                                                                                  |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Headroom**   | Main token optimizer. It compresses tool outputs, logs, files, RAG chunks, and conversation history before they hit the model. It can wrap Claude Code, Codex, Cursor, Aider, etc. ([GitHub][1]) |
| **RTK**        | Compresses terminal output from dev commands before the agent sees it. Very useful for `pytest`, `npm`, Docker logs, git logs, CI errors, etc. ([GitHub][2])                                     |
| **Serena MCP** | Gives the agent IDE-like semantic code search/editing at symbol level, so it reads less full-file context. Good for large repos. ([GitHub][3])                                                   |
| **Context7**   | Gives up-to-date library docs and version-specific examples, so the agent does not guess outdated APIs. It supports CLI + Skills or MCP mode. ([GitHub][4])                                      |
| **ccusage**    | Measures actual token/cost usage across Claude Code, Codex, OpenCode, Gemini CLI, etc. Use this to know whether optimization is working. ([ccusage][5])                                          |
| **Caveman**    | Optional. It makes the agent reply shorter and cuts output tokens, but I would not use it for complex debugging where explanation quality matters. ([GitHub][6])                                 |

### Best install order

```bash
# 1. Measure first
npx ccusage@latest

# 2. Compress terminal output
brew install rtk

# 3. Add docs retrieval
npx ctx7 setup

# 4. Add Headroom
# Use its official install/wrap command from the repo,
# then wrap your coding agent, e.g. Claude Code or Codex.

# 5. Add Serena MCP
# Follow Serena quick start, not random MCP marketplace install.

# 6. Optional: shorter replies
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

For your case, I would use:

```text
Claude Code / Codex
    ↓
Headroom wrap
    ↓
RTK for command output
    ↓
Serena for semantic code navigation
    ↓
Context7 for fresh docs
    ↓
ccusage to measure cost
```

The **highest value combo** is probably:

```text
RTK + Serena + ccusage
```

Then add **Headroom** after that if token usage is still high.

I would **not install too many MCP servers at first**. More MCP tools can mean more tool descriptions, more permission/security surface, and more ways for the agent to get distracted. There have also been real security concerns around MCP/Git/filesystem combinations, so keep it minimal and repo-scoped. ([techradar.com][7])

[1]: https://github.com/chopratejas/headroom "GitHub - headroomlabs-ai/headroom: Compress tool outputs, logs, files, and RAG chunks before they reach the LLM. 60-95% fewer tokens, same answers. Library, proxy, MCP server. · GitHub"
[2]: https://github.com/rtk-ai/rtk "GitHub - rtk-ai/rtk: CLI proxy that reduces LLM token consumption by 60-90% on common dev commands. Single Rust binary, zero dependencies · GitHub"
[3]: https://github.com/oraios/serena "GitHub - oraios/serena: A powerful MCP toolkit for coding, providing semantic retrieval and editing capabilities  - the IDE for your agent · GitHub"
[4]: https://github.com/upstash/context7 "GitHub - upstash/context7: Context7 Platform -- Up-to-date code documentation for LLMs and AI code editors · GitHub"
[5]: https://ccusage.com/guide/ "Introduction | ccusage"
[6]: https://github.com/juliusbrussee/caveman "GitHub - JuliusBrussee/caveman:  why use many token when few token do trick — Claude Code skill that cuts 65% of tokens by talking like caveman · GitHub"
[7]: https://www.techradar.com/pro/security/anthropics-official-git-mcp-server-had-some-worrying-security-flaws-this-is-what-happened-next?utm_source=chatgpt.com "Anthropic's official Git MCP server had some worrying security flaws - this is what happened next"

For **Claude Code**, it is **not fully automatic just because you installed the tools**.

There are 3 types:

```text
Automatic after setup:
- RTK hook
- Headroom wrapper

Available but Claude must choose to use it:
- Serena MCP
- Context7 MCP

Manual / prompt-triggered:
- Caveman
- ccusage
```

Claude Code connects external tools through **MCP servers**, and you can check them inside Claude Code with `/mcp` or from terminal with `claude mcp list`. ([Claude][1])

## My recommended setup for you

### 1. Install RTK first

This is the easiest token-saving layer. It rewrites noisy shell commands into `rtk` versions before Claude sees the output. RTK’s Claude Code setup uses `rtk init -g`, then you restart Claude Code. ([GitHub][2])

```bash
brew install rtk
rtk init -g
rtk init --show
```

Then restart Claude Code.

After this, Claude should mostly use it **automatically** for supported shell commands. Example: test output, git diff, npm logs, pytest logs, etc. RTK says its Claude Code integration uses a `PreToolUse` hook. ([GitHub][2])

### 2. Install ccusage to measure

This does not optimize anything by itself. It shows your token/cost usage so you know whether RTK/Headroom/Serena are actually helping. ccusage can run directly with `npx ccusage@latest` and supports Claude Code, Codex, Gemini CLI, OpenCode, and others. ([GitHub][3])

```bash
npx ccusage@latest
npx ccusage@latest claude daily
npx ccusage@latest session
```

### 3. Install Serena for codebase understanding

Serena is the most important one for **agentic coding**, because it gives Claude symbol-level code navigation instead of reading huge files. Serena’s docs say it provides IDE-like semantic retrieval, editing, refactoring, and debugging tools through MCP. ([GitHub][4])

```bash
brew install uv
uv tool install -p 3.13 serena-agent
serena init
```

Then inside your project root:

```bash
cd /path/to/your/project
serena setup claude-code
```

Or manually:

```bash
claude mcp add serena -- serena start-mcp-server --context claude-code --project "$(pwd)"
```

Verify:

```bash
claude mcp list
```

Then open Claude Code and run:

```text
/mcp
```

Serena’s docs specifically say to verify connection with `/mcp`. They also warn that Claude Code may still prefer built-in tools, so they recommend starting Claude Code with Serena’s system prompt override for better adherence. ([oraios.github.io][5])

```bash
claude --system-prompt="$(serena prompts print-cc-system-prompt-override)"
```

In your first message to Claude, say:

```text
Activate the current project with Serena and read initial instructions. Use Serena for symbol search, references, and code navigation before reading whole files.
```

### 4. Install Context7 for fresh docs

Context7 can work in **CLI + Skills** mode or **MCP** mode. Its setup command is: ([GitHub][6])

```bash
npx ctx7 setup --claude
```

Choose **MCP mode** if you want Claude to call docs tools directly. Choose **CLI + Skills** if you want a lighter setup.

Then add this to your project `CLAUDE.md`:

```md
When working with external libraries, frameworks, SDKs, or APIs, use Context7 before writing code or configuration. Prefer version-specific docs when the project version is known.
```

Context7 says `ctx7 setup` installs a skill automatically, and manual rules can be added to `CLAUDE.md`. ([GitHub][6])

### 5. Add Headroom after the basic setup works

Headroom is a broader compression layer. It can wrap Claude Code with:

```bash
pip install "headroom-ai[all]"
headroom wrap claude
headroom doctor
headroom perf
```

Headroom’s docs say it can run as an agent wrapper, proxy, library, or MCP server, and the `headroom wrap claude` command is the direct Claude Code wrapper mode. ([GitHub][7])

I would add Headroom **after** RTK + Serena + ccusage, because Headroom is more powerful but more invasive. Use `headroom doctor` and `headroom perf` to confirm it is actually routing/compressing. ([GitHub][7])

## Should you install Caveman?

Optional. I would not make it default for serious debugging.

Caveman mainly reduces **Claude’s reply/output tokens** by making responses very terse. It can be triggered with `/caveman` or “talk like caveman,” and stopped with “normal mode.” ([GitHub][8])

Install only after the main setup:

```bash
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

## Final setup I recommend

```text
Install first:
1. RTK
2. ccusage
3. Serena
4. Context7

Install later:
5. Headroom

Optional:
6. Caveman
```

And add this to your project `CLAUDE.md`:

```md
# Agentic coding rules

Use Serena for codebase navigation before reading whole files:
- symbol search
- references
- function/class overview
- targeted edits

Use Context7 when working with external libraries, frameworks, SDKs, APIs, or configuration.

Use terminal commands through RTK when possible, especially for tests, logs, git output, and dependency installation.

Avoid dumping huge files or full logs into context. Prefer focused search, summaries, and targeted reads.

When debugging, preserve exact error messages, failing test names, stack traces, and file paths.
```

So the answer is: **RTK and Headroom can become mostly automatic after setup; Serena and Context7 are available to Claude, but you should guide Claude with `CLAUDE.md` and verify with `/mcp`.**

[1]: https://code.claude.com/docs/en/mcp "Connect Claude Code to tools via MCP - Claude Code Docs"
[2]: https://github.com/rtk-ai/rtk "GitHub - rtk-ai/rtk: CLI proxy that reduces LLM token consumption by 60-90% on common dev commands. Single Rust binary, zero dependencies · GitHub"
[3]: https://github.com/ccusage/ccusage?utm_source=chatgpt.com "npx ccusage"
[4]: https://github.com/oraios/serena "GitHub - oraios/serena: A powerful MCP toolkit for coding, providing semantic retrieval and editing capabilities  - the IDE for your agent · GitHub"
[5]: https://oraios.github.io/serena/02-usage/030_clients.html "Connecting Your MCP Client — Serena Documentation"
[6]: https://github.com/upstash/context7 "GitHub - upstash/context7: Context7 Platform -- Up-to-date code documentation for LLMs and AI code editors · GitHub"
[7]: https://github.com/chopratejas/headroom "GitHub - headroomlabs-ai/headroom: Compress tool outputs, logs, files, and RAG chunks before they reach the LLM. 60-95% fewer tokens, same answers. Library, proxy, MCP server. · GitHub"
[8]: https://github.com/juliusbrussee/caveman?utm_source=chatgpt.com "JuliusBrussee/caveman: 🪨 why use many token ..."

Yes, you can remove them later. I’d separate **disable** vs **fully uninstall**.

## 1. Quick disable from Claude Code

First list what Claude is using:

```bash
claude mcp list
```

Then remove MCP tools like Serena or Context7:

```bash
claude mcp remove serena
claude mcp remove context7
```

Claude’s official MCP docs show `claude mcp list`, `claude mcp get <name>`, `claude mcp remove <name>`, and `/mcp` for checking server status. ([Claude][1])

If you installed a server with user/global scope, remove it with the same scope:

```bash
claude mcp remove serena --scope user
claude mcp remove context7 --scope user
```

Claude Code supports `local`, `project`, and `user` MCP scopes, and the config can live in `~/.claude.json` or `.mcp.json` depending on scope. ([Claude][1])

Then restart Claude Code and check:

```text
/mcp
```

## 2. Remove RTK

RTK is a hook, so remove the hook first:

```bash
rtk init -g --uninstall
```

Then uninstall the binary:

```bash
brew uninstall rtk
```

RTK’s install command is `rtk init -g`, and its hook auto-rewrites Bash commands before Claude sees terminal output. ([GitHub][2]) There is also a known issue saying `rtk init -g --uninstall` removes integration artifacts but may leave runtime data like history/tracking files. ([GitHub][3])

Optional cleanup on macOS:

```bash
rm -rf ~/Library/Application\ Support/rtk
```

## 3. Remove Serena

Remove from Claude MCP first:

```bash
claude mcp remove serena
claude mcp remove serena --scope user
```

Then uninstall Serena if you installed with `uv`:

```bash
uv tool uninstall serena-agent
```

Also remove any Serena hooks you added in:

```bash
~/.claude/settings.json
./.claude/settings.json
```

Serena’s docs show `serena setup claude-code`, manual `claude mcp add ... serena ...`, and optional Claude Code hooks in `.claude/settings.json` or `~/.claude/settings.json`. ([OraiOS][4])

## 4. Remove Context7

Context7 has a built-in remove command:

```bash
npx ctx7 remove
```

If you globally installed the CLI:

```bash
npm uninstall -g ctx7
```

Context7’s docs say `npx ctx7 setup --claude` configures it for Claude Code, and `npx ctx7 remove` removes the generated setup; global CLI installs must be removed separately. ([GitHub][5])

Also delete any Context7 rule you added in `CLAUDE.md`, for example:

```md
Always use Context7 when working with external libraries...
```

## 5. Remove Headroom

Undo the wrapper first:

```bash
headroom unwrap claude
```

If you also installed Headroom MCP:

```bash
headroom mcp uninstall
```

Then uninstall the package:

```bash
pip uninstall headroom-ai
```

Or if installed through npm:

```bash
npm uninstall -g headroom-ai
```

Headroom’s README says agent wrapping can be undone with `headroom unwrap <tool>`. ([GitHub][6]) A current Headroom issue notes that full teardown may require multiple commands: unwrap the tool, uninstall MCP, remove any persistent agent/supervisor setup, then uninstall the Python/npm package. ([GitHub][7])

## 6. Remove Caveman

Caveman is mostly prompt/style config. Remove whatever installer added under your Claude config. Start by checking:

```bash
ls ~/.claude
find ~/.claude -iname "*caveman*"
```

Then remove related files manually. Also delete any `/caveman` command or rule from `CLAUDE.md`.

## 7. Final check

Run:

```bash
claude mcp list
```

Then open Claude Code and run:

```text
/mcp
```

Also search your project for leftover rules:

```bash
rg "serena|context7|rtk|headroom|caveman" .
```

For your setup, the safest uninstall order is:

```text
1. Remove MCP entries
2. Remove hooks/wrappers
3. Remove CLAUDE.md rules
4. Uninstall binaries/packages
5. Restart Claude Code
6. Check /mcp
```

[1]: https://code.claude.com/docs/en/mcp "Connect Claude Code to tools via MCP - Claude Code Docs"
[2]: https://github.com/rtk-ai/rtk "GitHub - rtk-ai/rtk: CLI proxy that reduces LLM token consumption by 60-90% on common dev commands. Single Rust binary, zero dependencies · GitHub"
[3]: https://github.com/rtk-ai/rtk/issues/1014 "`rtk init -g --uninstall` leaves data directory artifacts on disk · Issue #1014 · rtk-ai/rtk · GitHub"
[4]: https://oraios.github.io/serena/02-usage/030_clients.html "Connecting Your MCP Client — Serena Documentation"
[5]: https://github.com/upstash/context7?utm_source=chatgpt.com "Context7 Platform - Up-to-date Code Docs For Any Prompt"
[6]: https://github.com/chopratejas/headroom/blob/main/README.md "headroom/README.md at main · headroomlabs-ai/headroom · GitHub"
[7]: https://github.com/chopratejas/headroom/issues/748 "[FEATURE] One consolidated `headroom uninstall` command + document teardown in --help and README · Issue #748 · headroomlabs-ai/headroom · GitHub"

Yes — **mostly**. For your case, I would make the setup **project-local**, not global.

Meaning:

```text
Only this repo uses Serena / Context7 / RTK / Headroom.
Other Claude Code projects stay clean.
```

Claude Code supports **local MCP scope**, which loads only for the current project and is not shared with your team. It stores that config under your `~/.claude.json`, tied to the project path. It also supports **project scope**, which writes `.mcp.json` into the repo and can be committed. ([Claude][1])

## Recommended local setup

Inside your project:

```bash
cd /path/to/your-project

mkdir -p .agent-tools/bin
mkdir -p .claude

echo ".agent-tools/" >> .gitignore
echo ".claude/settings.local.json" >> .gitignore
```

Use this structure:

```text
your-project/
  .agent-tools/          # local installed tools, gitignored
  .claude/
    settings.local.json  # local hooks/settings, gitignored
  CLAUDE.md              # project rules, optional to commit
  .mcp.json              # only if you want team-shared MCP config
```

## 1. Serena: local to this repo

Serena’s official install path uses `uv tool install`, but for a strictly project-local install, use a virtual environment inside the repo. Serena’s docs say its normal install is through `uv`, and Claude Code can add Serena per project with `claude mcp add serena ... --project "$(pwd)"`. ([OraiOS][2])

```bash
uv venv .agent-tools/serena-venv --python 3.13
.agent-tools/serena-venv/bin/pip install -U serena-agent

.agent-tools/serena-venv/bin/serena init

claude mcp add serena --scope local -- \
  "$(pwd)/.agent-tools/serena-venv/bin/serena" \
  start-mcp-server \
  --context claude-code \
  --project "$(pwd)"
```

Check:

```bash
claude mcp list
```

Then inside Claude Code:

```text
/mcp
```

In your first prompt, say:

```text
Activate the current project with Serena and use Serena for symbol search and code navigation before reading whole files.
```

## 2. Context7: local MCP or lighter rule

Context7 has two modes: **CLI + Skills** and **MCP**. Its docs say the setup command can install a skill, or MCP can register documentation tools natively. ([GitHub][3])

For local MCP, install the MCP package into this project:

```bash
npm init -y
npm install -D @upstash/context7-mcp
```

Then add it to Claude only for this project:

```bash
claude mcp add context7 --scope local -- \
  "$(pwd)/node_modules/.bin/context7-mcp"
```

If that binary name fails, use the automatic setup instead:

```bash
npx ctx7 setup --claude
```

Then choose MCP mode, but check what it writes afterward.

Add to `CLAUDE.md`:

```md
When working with external libraries, frameworks, SDKs, APIs, or configuration, use Context7 before writing code. Prefer version-specific docs when the package version is known.
```

## 3. RTK: local binary, but be careful with auto-hook

RTK’s official install supports Homebrew, curl to `~/.local/bin`, Cargo, and prebuilt binaries. Its auto-rewrite hook is installed with `rtk init -g`, and it only affects Claude Code **Bash** tool calls, not built-in `Read`, `Grep`, or `Glob`. ([GitHub][4])

For local install:

```bash
cargo install --git https://github.com/rtk-ai/rtk --root "$(pwd)/.agent-tools/rtk"
```

Then test:

```bash
.agent-tools/rtk/bin/rtk --version
.agent-tools/rtk/bin/rtk git status
```

For safest local usage, do **not** run:

```bash
rtk init -g
```

because that is global/user-level.

Instead, add this to `CLAUDE.md`:

```md
Use local RTK for noisy shell output:
- Use `.agent-tools/rtk/bin/rtk git status` instead of `git status`
- Use `.agent-tools/rtk/bin/rtk test <command>` for tests
- Use `.agent-tools/rtk/bin/rtk err <command>` for long failing commands
- Avoid pasting full logs unless needed
```

This is less automatic, but safer and fully local.

If you really want local automatic RTK, create a project-local hook in `.claude/settings.local.json`. Claude Code hooks are shell commands that run at lifecycle events such as `PreToolUse`, and `/hooks` can verify them. ([Claude][5])

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$PWD/.agent-tools/rtk/bin/rtk hook claude"
          }
        ]
      }
    ]
  }
}
```

Then check inside Claude Code:

```text
/hooks
```

I would start with **manual RTK commands**, then add the hook later after you trust it.

## 4. Headroom: local venv, but I would add later

Headroom can be installed with pip and used to wrap Claude, but wrapping is more invasive than Serena/Context7. Its PyPI page describes it as compressing tool calls, DB queries, file reads, and RAG retrieval before they hit the model. ([PyPI][6])

Project-local install:

```bash
uv venv .agent-tools/headroom-venv
.agent-tools/headroom-venv/bin/pip install "headroom-ai[all]"
```

Then use it manually:

```bash
.agent-tools/headroom-venv/bin/headroom doctor
.agent-tools/headroom-venv/bin/headroom perf
```

I would **not** wrap Claude globally at first. Keep Headroom as phase 2.

## 5. ccusage: local dev dependency

```bash
npm install -D ccusage
```

Run:

```bash
npx ccusage@latest
npx ccusage@latest session
```

This is only measurement, so it is safe.

## Best local setup for you

Use this first:

```text
Local Serena MCP
+ Local Context7 MCP
+ Local RTK manual commands
+ Local ccusage
```

Then later:

```text
Add RTK local hook
Add Headroom local wrapper
```

My recommended minimal local install:

```bash
cd /path/to/your-project

mkdir -p .agent-tools/bin .claude
echo ".agent-tools/" >> .gitignore
echo ".claude/settings.local.json" >> .gitignore

# Serena
uv venv .agent-tools/serena-venv --python 3.13
.agent-tools/serena-venv/bin/pip install -U serena-agent
.agent-tools/serena-venv/bin/serena init

claude mcp add serena --scope local -- \
  "$(pwd)/.agent-tools/serena-venv/bin/serena" \
  start-mcp-server \
  --context claude-code \
  --project "$(pwd)"

# Context7
npm init -y
npm install -D @upstash/context7-mcp ccusage

# RTK
cargo install --git https://github.com/rtk-ai/rtk --root "$(pwd)/.agent-tools/rtk"

# Verify
claude mcp list
.agent-tools/rtk/bin/rtk --version
npx ccusage@latest session
```

One important caveat: **local MCP config and local install are not exactly the same thing**. The tool files can live inside your repo, but Claude’s **local-scope MCP entry** is still stored in `~/.claude.json`, tied to that project path. That is normal and still means it will not load in other projects.

[1]: https://code.claude.com/docs/en/mcp "Connect Claude Code to tools via MCP - Claude Code Docs"
[2]: https://oraios.github.io/serena/02-usage/010_installation.html?utm_source=chatgpt.com "Installation — Serena Documentation"
[3]: https://github.com/upstash/context7 "GitHub - upstash/context7: Context7 Platform -- Up-to-date code documentation for LLMs and AI code editors · GitHub"
[4]: https://github.com/rtk-ai/rtk "GitHub - rtk-ai/rtk: CLI proxy that reduces LLM token consumption by 60-90% on common dev commands. Single Rust binary, zero dependencies · GitHub"
[5]: https://code.claude.com/docs/en/hooks-guide "Automate actions with hooks - Claude Code Docs"
[6]: https://pypi.org/project/headroom-ai/0.5.23/?utm_source=chatgpt.com "headroom-ai"
