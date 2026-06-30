# Low-Cost Token Test

Use this test to check whether `agentic-dev-kit` is helping reduce token usage in a small sandbox. It is a cheap confidence check, not a scientific benchmark.

## 1. Create And Install The Sandbox

```bash
cd /Users/banknatchapol/Desktop/Codes/agentic-dev-kit
scripts/token-test-sandbox.sh all
```

This creates `/tmp/agentic-dev-kit-token-test`, installs the local kit there, runs status checks, and prints the prompts.

## 2. Run Four Fresh Agent Sessions

Run each session from the sandbox:

```bash
cd /tmp/agentic-dev-kit-token-test
```

Codex baseline prompt:

```text
Do not use Serena, Context7, RTK, or Headroom. Inspect the repo normally. Summarize the app structure, identify the failing log cause, and suggest one fix. Keep the answer under 8 bullets.
```

Codex optimized prompt:

```text
Use the local agentic-dev-kit setup. Use Serena before reading full files, Context7 only if needed, and RTK for noisy shell/log output. Do the same task as before. Keep the answer under 8 bullets.
```

Claude baseline prompt:

```text
Do not use Serena, Context7, RTK, or Headroom. Inspect the repo normally. Summarize the app structure, identify the failing log cause, and suggest one fix. Keep the answer under 8 bullets.
```

Claude optimized prompt:

```text
Use the local agentic-dev-kit setup. Use Serena before reading full files, Context7 only if needed, and RTK for noisy shell/log output. Do the same task as before. Keep the answer under 8 bullets.
```

For optimized runs, check `/mcp` first and confirm Serena + Context7 are available.

## 3. Compare Usage

After each run, record the newest session:

```bash
node_modules/.bin/ccusage codex session --json
node_modules/.bin/ccusage claude session --json
```

Compare:

- `inputTokens` as the primary metric
- `totalTokens`, `totalCost`, and `outputTokens` as secondary metrics

Expected result:

- Any visible `inputTokens` reduction is good for this tiny sandbox.
- 15-30% reduction suggests the kit is helping.
- No reduction usually means the task was too small or the agent ignored the tools.

Do not over-interpret `cacheReadTokens`; prompt caching can make totals look strange across sessions.

## 4. Cleanup

```bash
scripts/token-test-sandbox.sh cleanup
```

