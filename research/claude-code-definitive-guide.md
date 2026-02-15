# The Definitive Guide to Claude Code Configuration
## Verified Practices from the Creator, Production Teams, and Independent Research

*Last updated: February 15, 2026 | Current model: Opus 4.6 | Claude Code v2.1.x*

*Sources: Official Anthropic docs, Boris Cherny (creator) Threads posts, Trail of Bits, HumanLayer, incident.io, Arize AI, Simon Willison, Will Larson, Boris Tane, Armin Ronacher, METR study, Cui et al. study, Snyk ToxicSkills, and more. All quotes verified against original sources.*

---

## Table of Contents

1. [Verification Loops -- The #1 Technique](#1-verification-loops)
2. [CLAUDE.md -- The Foundation](#2-claudemd)
3. [Hooks -- The Enforcement Layer](#3-hooks)
4. [Permissions -- The Safety Spectrum](#4-permissions)
5. [Context Management -- The Silent Killer](#5-context-management)
6. [Plan Mode & Effort Levels](#6-plan-mode--effort-levels)
7. [Parallel Sessions & Git Worktrees](#7-parallel-sessions--git-worktrees)
8. [Skills, Slash Commands & Subagents](#8-skills-slash-commands--subagents)
9. [MCP Servers](#9-mcp-servers)
10. [Agent Teams](#10-agent-teams)
11. [Cost Management](#11-cost-management)
12. [Security Considerations](#12-security-considerations)
13. [Status Line, Environment Variables & New Features](#13-status-line-environment-variables--new-features)
14. [Real Project Layout](#14-real-project-layout)
15. [Hype vs. Reality Scoreboard](#15-hype-vs-reality-scoreboard)
16. [Sources](#16-sources)

---

## 1. Verification Loops

**The #1 technique. Every credible source agrees.**

Boris Cherny's exact words (Threads, Jan 2026): *"A final tip: probably the most important thing to get great results out of Claude Code -- give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result."*

What this means in practice:

| Task type | Verification method |
|-----------|-------------------|
| Backend code | Run the test suite after every change |
| Frontend/UI | Screenshot via Chrome extension, iterate visually |
| Refactoring | Type-check + lint after every edit |
| API work | `curl` the endpoint, check response |
| Build changes | Run the build, check output |

The mechanism: `PostToolUse` hooks that auto-run formatters, linters, and tests after every file edit. Claude sees the output, catches its own mistakes, and self-corrects. Without verification, Claude produces plausible-looking implementations that don't handle edge cases.

**Verdict: REAL DEAL.** Not a workflow preference -- the architectural principle that separates productive Claude Code users from frustrated ones.

---

## 2. CLAUDE.md

### What It Is
A markdown file Claude reads at the start of every session. Your persistent project memory and the highest-leverage configuration point.

### Keep It Short

HumanLayer keeps theirs at ~88 lines. Trail of Bits recommends under 300. Multiple sources converge on: aim for under 100 lines.

**Why?** The IFScale paper (arXiv 2507.11538, July 2025) tested 20 frontier LLMs and found that 150-200 instructions is a critical primacy-bias inflection point where models begin struggling under cognitive load. This isn't a hard ceiling -- different models degrade differently (threshold decay for reasoning models, linear decay for frontier models, exponential decay for smaller models) -- but the directional advice is clear: every irrelevant CLAUDE.md line degrades instruction-following quality.

**Include:**
- Build/test/lint commands Claude can't guess
- Code style rules that differ from defaults (e.g., "use ES modules, not CommonJS")
- Git workflow conventions (branch naming, commit format)
- Architectural decisions specific to your project
- Common gotchas and non-obvious behaviors
- "IMPORTANT" / "YOU MUST" emphasis for critical rules

**Exclude:**
- Anything Claude can figure out by reading code
- Standard language conventions
- Detailed API docs (link to them instead)
- Code style rules a linter can enforce -- *"Never send an LLM to do a linter's job"* (HumanLayer)
- File-by-file codebase descriptions
- Self-evident instructions like "write clean code"

**Do NOT auto-generate with `/init`.** Every power user warns against this. Hand-craft every line. For each, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

### File Hierarchy

```
~/.claude/CLAUDE.md          # Personal global defaults
./CLAUDE.md                   # Project root (committed, shared with team)
./packages/api/CLAUDE.md      # Subdirectory-specific (pulled in on demand)
./CLAUDE.local.md             # Personal overrides (gitignored)
```

### Real Example (Trail of Bits style)

```markdown
# Project: my-api
Stack: TypeScript, Node 22, Bun, PostgreSQL

## Commands
- Build: `bun run build`
- Test single: `bun test path/to/test.ts`
- Test all: `bun test`
- Lint: `bun run lint`
- Typecheck: `bun run typecheck`

## Code Style
- ES modules only (import/export, never require)
- Functions capped at ~100 lines
- Prefer composition over inheritance
- Use early returns, avoid nested conditionals

## Git
- Branch: `{initials}/{description}`
- Commits: Conventional Commits (feat:, fix:, docs:)
- IMPORTANT: Never push directly to main

## Architecture
- API routes in src/routes/, one file per resource
- Business logic in src/services/, never in route handlers
- Database queries in src/db/, using Drizzle ORM
- YOU MUST run typecheck after editing any .ts file

## Gotchas
- The auth middleware reads from X-API-Key header, not Authorization
- Tests use a separate test database (see .env.test)
```

### Team Practice
Boris Cherny: the CLAUDE.md is checked into git. The whole team maintains it. When Claude makes an error during code review, the correction is added permanently. This creates a compounding feedback loop -- the file gets smarter over time.

**Verdict: REAL DEAL.** The single most important file in your project. The key insight is restraint -- less is more.

---

## 3. Hooks

### Why They Matter
CLAUDE.md is advisory -- Claude can ignore it. Hooks are deterministic and guaranteed. CLAUDE.md (guidance) + hooks (enforcement) is the robust approach.

### All 14 Hook Events (as of Feb 2026)

| # | Event | Purpose |
|---|-------|---------|
| 1 | `SessionStart` | Re-inject context on session start or resume/compact |
| 2 | `SessionEnd` | Cleanup on session termination |
| 3 | `UserPromptSubmit` | Transform/validate user input before processing |
| 4 | `PermissionRequest` | Act when a permission dialog appears |
| 5 | `PreToolUse` | Block dangerous operations before they happen |
| 6 | `PostToolUse` | Auto-run quality checks after every edit |
| 7 | `PostToolUseFailure` | Handle tool failures |
| 8 | `Notification` | Desktop alerts when Claude needs input |
| 9 | `SubagentStart` | Act when a subagent spawns |
| 10 | `SubagentStop` | Act when a subagent finishes |
| 11 | `Stop` | Verify all tasks complete before Claude finishes |
| 12 | `TeammateIdle` | Keep Agent Teams teammates working (exit 2 to send feedback) |
| 13 | `TaskCompleted` | Quality gates on task completion (exit 2 to prevent) |
| 14 | `PreCompact` | Act before context compaction |

**Handler types:** `command` (shell script), `prompt` (single LLM call), `agent` (multi-turn subagent).
**Async support:** Add `"async": true` for non-blocking background execution (since Jan 2026).
**Exit code contract:** 0 = allow, 1 = non-blocking error (shown to user only), 2 = block and show feedback to Claude.
**Input modification:** Hooks can now modify tool inputs before execution, not just block/allow.

### Battle-Tested Hook Configs

**Auto-format after every edit (Boris Cherny's setup):**
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bun run format || true"
      }]
    }]
  }
}
```

**Block edits on main branch:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|MultiEdit|Write",
      "hooks": [{
        "type": "command",
        "command": "[ \"$(git branch --show-current)\" != \"main\" ] || { echo '{\"block\": true, \"message\": \"Cannot edit files on main branch.\"}' >&2; exit 2; }"
      }]
    }]
  }
}
```

**Block destructive bash commands (Trail of Bits):**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "CMD=$(jq -r '.tool_input.command'); if echo \"$CMD\" | grep -qE 'rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f'; then echo 'BLOCKED: Use trash instead of rm -rf' >&2; exit 2; fi"
        },
        {
          "type": "command",
          "command": "CMD=$(jq -r '.tool_input.command'); if echo \"$CMD\" | grep -qE 'git[[:space:]]+push.*(main|master)'; then echo 'BLOCKED: Use feature branches' >&2; exit 2; fi"
        }
      ]
    }]
  }
}
```

**Re-inject context after compaction:**
```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "compact",
      "hooks": [{
        "type": "command",
        "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
      }]
    }]
  }
}
```

**Auto-run tests when test files change:**
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "FILE=$(jq -r '.tool_input.file_path'); if echo \"$FILE\" | grep -qE '\\.(test|spec)\\.(ts|tsx|js|jsx)$'; then npx jest \"$FILE\" --no-coverage 2>&1 | tail -20; fi"
      }]
    }]
  }
}
```

**Verdict: REAL DEAL.** Underappreciated feature. The auto-format + auto-test + branch-protection trifecta is the most impactful hook setup.

---

## 4. Permissions

### The Three Camps

**Camp 1: Permission allowlists (RECOMMENDED)**
Boris Cherny's approach -- pre-allow safe commands via `/permissions` or `settings.json`:
```json
{
  "permissions": {
    "allow": [
      "Bash(bun run build:*)",
      "Bash(bun run test:*)",
      "Bash(bun run typecheck:*)",
      "Bash(bun run format:*)",
      "Bash(git commit *)",
      "Bash(git push *)"
    ],
    "deny": [
      "Bash(curl *)",
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)"
    ]
  }
}
```

**Camp 2: `--dangerously-skip-permissions` in containers**
Simon Willison's approach -- run autonomous agents in sandboxed environments with network restrictions. Never on your actual machine with real credentials. Claude Code now has built-in Docker sandboxing as a proper alternative.

**Camp 3: `--dangerously-skip-permissions` everywhere**
Popular among solo devs and vibe coders. Known risk: Claude has been observed deleting config files and modifying configs without backups. Do not do this on code you care about.

### Trail of Bits Deny List (Security-Focused)
Goes beyond the basics -- blocks reads of crypto wallets, Docker configs, npm tokens, GPG keys, and kubectl configs:

```json
{
  "deny": [
    "Bash(rm -rf *)", "Bash(sudo *)", "Bash(mkfs *)", "Bash(dd *)",
    "Bash(curl *|bash*)", "Bash(wget *|bash*)",
    "Bash(git push --force*)", "Bash(git reset --hard*)",
    "Edit(~/.bashrc)", "Edit(~/.zshrc)", "Edit(~/.ssh/**)",
    "Read(~/.ssh/**)", "Read(~/.gnupg/**)", "Read(~/.aws/**)",
    "Read(~/.azure/**)", "Read(~/.config/gh/**)",
    "Read(~/.git-credentials)", "Read(~/.docker/config.json)",
    "Read(~/.kube/**)", "Read(~/.npmrc)", "Read(~/.pypirc)"
  ]
}
```

**Verdict: REAL DEAL.** Permission allowlists are the correct approach. The Trail of Bits deny list is production-grade.

---

## 5. Context Management

### The Silent Killer
Context window degradation is the primary failure mode of Claude Code. Performance degrades as context fills. Every credible source emphasizes this.

### What Actually Works

1. **`/clear` aggressively** -- Start fresh between unrelated tasks. Boris Cherny's own practice and the single biggest cost saver.

2. **After 2 failed corrections, `/clear` and rewrite your prompt** -- incorporating what you learned. Don't keep fighting in a degraded context.

3. **Use subagents for investigation** -- They explore in separate 200K context windows and report back summaries. Your main context stays clean.

4. **Write handoff documents before clearing** -- "Put the rest of the plan in a markdown file" then start fresh and load it.

5. **Manual compaction > auto-compaction** -- `/compact Focus on the API changes` is better than the opaque auto-trigger. Consider compacting proactively at 60%.

6. **Disable unused MCP servers** -- MCP tool definitions eat context permanently. Tool search (default `auto`) lazy-loads definitions and can reduce MCP context by 85-95%.

7. **Track context with a status line** -- See Section 13.

### Token Budget Reality
- Fresh session baseline: **11-20k tokens** (11k minimal, 20k+ with multiple MCP servers)
- Base context window: **200k tokens** (1M available for API/pay-as-you-go users via `[1m]` suffix)
- System buffer: ~16.5% reserved (~33k tokens)
- Realistic usable context: **140-165k tokens** for typical configurations
- Each file Claude reads: 1-10k tokens depending on size
- MCP tool definitions: 2-50k+ tokens depending on server count

**Verdict: REAL DEAL.** Ignoring context management is the #1 reason people find Claude "unreliable."

---

## 6. Plan Mode & Effort Levels

### Plan Mode
Activate: `Shift+Tab` twice. Claude enters read-only mode -- can explore but not modify.

Boris Cherny (Threads, Nov 26, 2025): *"Plan Mode is the most slept-on feature in Claude Code -- and we just made it a lot better. It dramatically improves your one-shot success rate."* (Note: this was posted to promote a plan mode update -- it's a product announcement as much as a workflow tip. His workflow thread simply says "Most sessions start in Plan mode.")

**The 4-phase workflow (Anthropic recommended):**
1. **Explore** (Plan Mode): Read files, understand the codebase
2. **Plan** (Plan Mode): Create detailed implementation plan. `/plan open` to edit in your editor -- changes sync back to Claude automatically.
3. **Implement** (Normal Mode): Execute. Claude typically one-shots from a good plan.
4. **Commit** (Normal Mode): Commit and create PR.

**Boris Tane's Annotation Cycle (most refined version):**
1. Ask Claude to research the codebase deeply, write findings to `research.md`
2. Request detailed implementation plan in a separate markdown file
3. Review the plan in your editor, add inline notes correcting assumptions
4. Send back with "don't implement yet." Repeat 1-6 times.
5. Only then: "implement it all."

This treats the plan document as shared mutable state rather than relying on chat threading.

**When to skip planning:** If you can describe the diff in one sentence, just do it.

**Armin Ronacher's reality check (Flask creator):** Plan Mode is "just the prompt" with "not much of a difference for how plan mode invokes tools versus how regular execution invokes tools." The benefits come from structured prompting, not a magic safety boundary.

### Effort Levels (Replaced Thinking Keywords)

The `think`, `think hard`, `ultrathink` keywords are **deprecated** as of Opus 4.6. The replacement:

| Setting | How to set | When to use |
|---------|-----------|-------------|
| `low` | `/model` slider or `CLAUDE_CODE_EFFORT_LEVEL=low` | Quick fixes, typos, simple queries |
| `medium` | `/model` slider or `CLAUDE_CODE_EFFORT_LEVEL=medium` | Routine refactors |
| `high` (default) | `/model` slider or `CLAUDE_CODE_EFFORT_LEVEL=high` | Multi-file changes, architecture |

Opus 4.6 uses **adaptive thinking** (`thinking.type: "adaptive"`) -- the model dynamically decides when deeper reasoning helps, rather than requiring explicit keyword triggers. The explore-then-plan workflow pattern matters more than any keyword.

**Verdict: Plan Mode is REAL DEAL. Thinking keywords are deprecated -- use effort levels.**

---

## 7. Parallel Sessions & Git Worktrees

### The Claude Code Team's Top Tip

Boris Cherny (Threads, Jan 31, 2026): *"Spin up 3-5 git worktrees at once, each running its own Claude session in parallel. It's the single biggest productivity unlock, and the top tip from the team. Personally, I use multiple git checkouts, but most of the Claude Code team prefers worktrees -- it's the reason we built native support for them into the Claude Desktop app!"*

**Important nuance:** Worktrees are the *team's* preferred approach. Boris himself uses git checkouts. Both work.

Boris's personal setup: 5 local sessions in terminal tabs + 5-10 remote sessions on claude.ai/code + mobile sessions from the Claude iOS app.

### How To Do It

```bash
# Create isolated worktrees per feature
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b
git worktree add ../project-bugfix-c bugfix-c

# Run Claude in each (separate terminals)
cd ../project-feature-a && claude
cd ../project-feature-b && claude
```

Each worktree has its own working directory. No file conflicts. Each Claude instance has its own context window.

### incident.io's `w` Function
A custom bash function: `w myproject new-feature claude` instantly creates an isolated worktree, names the branch with your username prefix, and launches Claude Code. Their team uses this daily.

### The Writer/Reviewer Pattern
Use separate sessions for quality:

| Session A (Writer) | Session B (Reviewer) |
|---|---|
| Implements the feature | Reviews the code in a fresh context (no bias toward its own output) |
| Addresses review feedback | |

### Will Larson's Fragmented Session Workflow
Pop back into Claude Code sessions between meetings. Review what Claude did, give 2-3 sentences of feedback, context-switch. You don't need large uninterrupted blocks of coding time.

**Verdict: REAL DEAL.** The worktree pattern is the real productivity multiplier. The creator and multiple production teams endorse it.

---

## 8. Skills, Slash Commands & Subagents

### Custom Slash Commands (`.claude/commands/`)
Files in `.claude/commands/` become `/command-name` invocations. The filename becomes the command.

Boris Cherny (Threads, Jan 2026): *"I use slash commands for every inner loop workflow that I do many times a day."* He and Claude use a `/commit-push-pr` slash command *"every day."* (Note: secondary sources paraphrased this as "dozens of times daily" -- his actual words are "every day.")

**Example: ticket workflow (`.claude/commands/ticket.md`):**
```markdown
Read the JIRA ticket $ARGUMENTS using the MCP tool.
Implement the feature described.
Write tests. Run the test suite.
Create a commit with a descriptive message.
Push and create a PR linking back to the ticket.
Update the ticket status to "In Review".
```
Usage: `/ticket ENG-4521`

### Skills (the evolution of commands)
Skills add: a directory for supporting files, YAML frontmatter for control, and automatic loading when relevant.

```markdown
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---
Analyze and fix the GitHub issue: $ARGUMENTS.
1. Use `gh issue view` to get details
2. Search codebase for relevant files
3. Implement changes
4. Write and run tests
5. Create commit, push, create PR
```

`disable-model-invocation: true` = only runs when you explicitly call `/fix-issue 1234`.

### Subagents (`.claude/agents/`)
Custom agents with their own tool restrictions and model selection:

```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities
tools: Read, Grep, Glob
model: opus
---
You are a senior security engineer. Review code for:
- Injection vulnerabilities (SQL, XSS, command injection)
- Authentication and authorization flaws
- Secrets or credentials in code
Provide specific line references and suggested fixes.
```

`tools: Read, Grep, Glob` -- no Write or Bash. This agent can only read, not modify.

**Verdict: REAL DEAL.** Any workflow you repeat more than 3 times should be a skill.

---

## 9. MCP Servers

### When They're Worth It
- **Issue trackers** (JIRA, Linear, GitHub Issues): Enable end-to-end "read ticket -> implement -> test -> update ticket -> create PR" workflows
- **Monitoring** (Sentry): Claude can read error traces and fix bugs directly
- **Communication** (Slack): Get context from product discussions
- **Databases** (via dbhub): Query production data for debugging

### When They're Not Worth It
- **GitHub**: Most power users prefer raw `gh` CLI over GitHub MCP
- **Simple REST APIs**: A `curl` command in a skill is more token-efficient
- **Any stateless tool**: Skills are cheaper than MCP for simple lookups

### The Context Bloat Problem
MCP server tool definitions eat context permanently. Each server adds ~2,000+ tokens to every request.

**Mitigation:** Tool search (enabled by default, `ENABLE_TOOL_SEARCH=auto`) lazy-loads tool descriptions on demand. Can reduce MCP context by 85-95%.

### Setup

```bash
# HTTP-based (recommended for hosted services)
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport http notion https://mcp.notion.com/mcp

# stdio-based (for local tools)
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub \
  --dsn "postgresql://readonly:pass@localhost:5432/mydb"
```

**Team sharing via `.mcp.json`:**
```json
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

`${VAR:-default}` syntax lets you commit without hardcoding secrets.

**Verdict: SITUATIONALLY REAL.** High value for teams with issue trackers and monitoring. Low value for solo devs doing greenfield work. Watch the token costs.

---

## 10. Agent Teams

### What It Is
Multi-agent orchestration where one "team lead" session spawns independent "teammates," each in its own context window. Released **February 5, 2026** alongside Opus 4.6. Status: **experimental, disabled by default.**

### How to Enable
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```
Or in `settings.json`: `"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }`

### Architecture

| Component | Role |
|-----------|------|
| **Team lead** | Main session that creates the team, spawns teammates, coordinates |
| **Teammates** | Separate Claude Code instances working on assigned tasks |
| **Task list** | Shared work items that teammates claim and complete (DAG-based) |
| **Mailbox** | Messaging system for inter-agent communication |

### When to Use
- Parallel code review (security + performance + test coverage reviewers)
- Investigating competing hypotheses for bugs
- Large feature implementation with independent file sets
- Research tasks requiring multiple exploration angles

### Current Limitations
- No session resumption with in-process teammates
- One team per session; no nested teams
- Split-pane mode requires tmux or iTerm2
- Token costs scale proportionally with team size
- Teammates cannot spawn their own teams

### Quality Gates via Hooks
- `TeammateIdle`: Exit code 2 sends feedback and keeps the teammate working
- `TaskCompleted`: Exit code 2 prevents premature task completion

**Verdict: EMERGING.** Promising for parallel work, but token-expensive. Start with research and review tasks before attempting parallel implementation.

---

## 11. Cost Management

### Why This Matters
The original guide had zero cost discussion. For power users, cost is a critical operational concern.

### Hidden Cost Mechanics
- Every message re-sends the full conversation history + CLAUDE.md
- Context ingestion dominates cost: reading 40k tokens to produce 500 tokens of output means paying primarily for reading
- Agent Teams multiply costs proportionally to team size
- MCP servers add ~2,000+ tokens per server to every request

### Pricing (Feb 2026)

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|------------------------|
| Haiku 4.5 | $1 | $5 |
| Sonnet 4.5 | $3 | $15 |
| Opus 4.6 | $5 | $25 |
| Opus 4.6 (fast mode) | $30 | $150 |

For requests exceeding 200K tokens (1M context): 2x input, 1.5x output premium.

### Cost Reduction Techniques
- **`/clear` between tasks** -- Single biggest cost saver (50-70% reduction)
- **`/model haiku`** for simple tasks (60-80% cost reduction vs Opus)
- **`opusplan`** hybrid: Opus for planning, Sonnet for execution automatically
- **Prompt caching**: Up to 90% savings on repeated context (automatic)
- **`/cost`** and **`/usage`** to monitor spend in-session

### Rate Limits (Max Plan)
- 5-hour rolling window controls burst activity
- 7-day weekly ceiling caps total active compute hours

### The `opusplan` Model Alias
Use `/model opusplan` for automatic hybrid routing:
- **In plan mode**: Uses Opus for complex reasoning and architecture decisions
- **In execution mode**: Switches to Sonnet for code generation

Override the underlying models via:
- `ANTHROPIC_DEFAULT_OPUS_MODEL` (planning model)
- `ANTHROPIC_DEFAULT_SONNET_MODEL` (execution model)

**Verdict: REAL DEAL.** Cost management separates sustainable usage from bill shock.

---

## 12. Security Considerations

### Supply Chain Risks for Skills and MCP

**Snyk ToxicSkills Study (Feb 5, 2026):** First comprehensive security audit of the AI agent skills ecosystem. Scanned 3,984 skills from ClawHub and skills.sh.
- **36.82% (1,467 skills)** have at least one security flaw of any kind (hardcoded API keys, insecure credential handling, dangerous third-party content exposure, etc.)
- **Prompt injection specifically** was found in **2.6%** of all skills -- the Snyk blog title "Prompt Injection in 36%" conflates all flaws with prompt injection
- **13.4% (534 skills)** contain critical-level issues (malware, prompt injection, exposed secrets)
- **91% of confirmed malicious skills** contained prompt injection (vs 0% in the legitimate top-100 most-downloaded skills)
- **76 confirmed malicious payloads**, 8 still publicly available at time of publication

**Claude Code Action RCE (disclosed Feb 2026):** Researcher John Stawinski demonstrated unauthorized prompt injection leading to remote code execution in the GitHub Actions integration. Attack chain: malicious PR title -> TOCTOU race condition -> code execution -> secret exfiltration. Remediation took months across multiple incomplete fixes.

**Cowork File Exfiltration (Jan 2026):** PromptArmor demonstrated file theft via indirect prompt injection two days after Cowork's launch. A booby-trapped .docx file with invisible text (1pt font, white-on-white) could cause Claude to exfiltrate files via curl.

### Defensive Measures
1. **Never install skills from untrusted sources** -- treat skills like npm packages, with the same supply chain scrutiny
2. **Use permission deny lists** (see Section 4) -- the Trail of Bits list blocks most exfiltration vectors
3. **Pin MCP server versions** -- prevent silent updates that could introduce malicious behavior
4. **Review skill contents before use** -- check for suspicious curl/fetch commands, base64 encoding, or obfuscated text
5. **Run autonomous agents in Docker/sandbox** rather than on machines with real credentials

**Verdict: CRITICAL.** The security landscape for AI agent tooling is immature. Defense in depth is essential.

---

## 13. Status Line, Environment Variables & New Features

### Custom Status Line
A shell script that receives JSON session data on stdin and displays real-time metrics:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

The JSON includes: model info, token counts, costs, context window `used_percentage`, and workspace details. Community tools like `ccstatusline` provide pre-built dashboards. Consider turning the status red above 60% context usage as an early `/compact` or `/clear` warning.

### Key Environment Variables

| Variable | Purpose | Recommended |
|----------|---------|-------------|
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | When auto-compaction triggers | `80` |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max output per response | Up to `128000` (doubled from 64K) |
| `MAX_MCP_OUTPUT_TOKENS` | MCP response limit | `50000` for large datasets |
| `BASH_DEFAULT_TIMEOUT_MS` | Bash command timeout | Increase for long builds |
| `ENABLE_TOOL_SEARCH` | Lazy-load MCP tools | `auto` (default) |
| `CLAUDE_CODE_EFFORT_LEVEL` | Effort level (low/medium/high) | `high` (default) |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | Toggle auto memory | `0` to force on, `1` to force off |

Set persistently in `settings.json`:
```json
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80",
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1"
  }
}
```

### Notable New Features (Jan-Feb 2026)

| Feature | Description |
|---------|-------------|
| **Fast Mode** (`/fast`) | 2.5x faster Opus 4.6 output, same model intelligence. 6x price. Toggle persists across sessions. |
| **Session Teleportation** (`/teleport`) | Pull web-based Claude Code sessions into your local terminal. One-way (web-to-terminal). |
| **Tasks System** | Persistent DAG-based task management replacing flat Todos. Stored at `~/.claude/tasks/`. Cross-instance sharing via `CLAUDE_CODE_TASK_LIST_ID`. |
| **Auto Memory** | Claude writes its own notes to `~/.claude/projects/<project>/memory/`. First 200 lines of `MEMORY.md` loaded into system prompt. Gradual rollout. |
| **128K Output Tokens** | Doubled from 64K max output per response. |
| **Docker Sandboxing** | MicroVM-based isolation for safe autonomous execution. |
| **GitHub Actions** | CI/CD integration via `claude-code-action` and `-p` flag. |

---

## 14. Real Project Layout

Based on all research, here's what a productive user's project actually looks like:

```
project/
  CLAUDE.md                           # <100 lines, committed, team-maintained
  CLAUDE.local.md                     # Personal overrides (gitignored)
  .mcp.json                           # MCP servers (committed for team)
  .claude/
    settings.json                     # Hooks + permissions (committed)
    settings.local.json               # Personal permissions (gitignored)
    commands/
      commit-push-pr.md               # Most-used command
      ticket.md                       # Issue-to-PR workflow
    skills/
      api-conventions/SKILL.md        # Domain knowledge
      fix-issue/SKILL.md              # Workflow automation
    agents/
      security-reviewer.md            # Read-only security review
      code-reviewer.md                # Code quality review
    hooks/
      protect-files.sh                # Block .env / lockfile edits
      validate-bash.py                # Block destructive commands

~/.claude/                            # Global (all projects)
  CLAUDE.md                           # Personal coding preferences
  settings.json                       # Global deny list + notification hooks
  statusline.sh                       # Context window display
  commands/
    catchup.md                        # "What changed on this branch?"
```

---

## 15. Hype vs. Reality Scoreboard

### Genuine -- Multiple credible sources agree

| Practice | Evidence |
|----------|----------|
| Verification loops (tests/lint after edits) | Creator's top tip, Anthropic official best practices |
| CLAUDE.md under 100 lines, hand-curated | HumanLayer, Trail of Bits, Anthropic docs |
| Hooks for auto-format + branch protection | Creator's workflow, Trail of Bits, multiple GitHub repos |
| Permission allowlists | Creator's recommendation, security community consensus |
| Git worktrees/checkouts for parallel sessions | Claude Code team's #1 productivity tip, incident.io |
| `/clear` aggressively between tasks | Creator, Reddit consensus, biggest single cost saver |
| Plan mode for non-trivial tasks | Creator calls it "most slept-on feature" |
| Skills for repeatable workflows | Creator uses `/commit-push-pr` daily |
| Subagents for context isolation | Anthropic docs, multiple power users |
| Cost management and model switching | 60-80% cost reduction documented |
| Tasks system for complex projects | Persistent DAG-based tracking, multi-session coordination |

### Situational -- Works in specific contexts

| Practice | Nuance |
|----------|--------|
| MCP servers | High value with issue trackers/monitoring, token-expensive otherwise |
| `--dangerously-skip-permissions` | Only in sandboxed containers (Simon Willison's approach) |
| Agent Teams | Experimental; promising for parallel review/research, token-expensive |
| Custom status line | Useful at scale, overkill for casual use |
| Voice input (SuperWhisper) | "5 minutes speaking replaces 20 minutes typing" -- real but niche |
| Auto memory | Useful at scale, partially redundant with good CLAUDE.md |
| Session teleportation | Convenience for multi-device workflows |

### Overhyped -- Sounds cool, doesn't pan out

| Claim | Reality |
|-------|---------|
| "10x productivity" | Evidence is genuinely mixed (see below). Gains are real but concentrated in prototyping, boilerplate, and unfamiliar codebases. |
| Thinking keywords ("ultrathink") | **Deprecated.** Replaced by adaptive thinking + effort levels. |
| Massive CLAUDE.md files (500+ lines) | Performance degrades. The IFScale paper shows primacy bias inflection at 150-200 instructions. |
| Full autonomous agent orchestration | Token costs explode, orchestration is complex. *"Simple control loops outperform multi-agent systems"* (Anthropic). |
| "Just vibe code everything" | Reddit users report disaster in complex domains (financial systems, poker solvers). Domain expertise still matters. |
| Auto-generated CLAUDE.md via `/init` | Every power user warns against this. Hand-craft it. |
| "Replaces your IDE" | Most power users pair Claude Code with Cursor or VS Code. Boris Cherny works primarily in terminal, but he's the exception. |
| "Handles 200k context seamlessly" | Practical ceiling is 140-165k tokens. Quality degrades well before hitting the limit. |

### The Productivity Evidence: Three Key Studies

| Study | N | Tool | Finding | Stat. Sig.? | Key Caveat |
|-------|---|------|---------|-------------|------------|
| **METR (Jul 2025)** | 16 devs, 246 tasks | **Cursor Pro** + Claude 3.5/3.7 | **19% slower**. 95% CI: [-40%, -2%] | Yes | Tested Cursor, not Claude Code. Only 1 of 16 devs had >1 week Cursor experience. Code acceptance rate ~39%. |
| **Cui et al.** | 4,867 devs | GitHub Copilot | **26% more PRs/week** (SE: 10.3%) | Pooled yes; only Microsoft individually | Measures PR throughput, not task time. Less experienced devs benefited more. |
| **Google RCT** | 96 engineers | Internal AI tools | **~21% faster** | p=0.086 (**No** at p<0.05) | Single task type (data logging). Large confidence interval. |

**METR perception gap:** Developers believed they were 20% faster while being 19% slower. This ~39-percentage-point gap between perception and reality is the study's most striking finding. Economics experts predicted 39% speedup, ML experts predicted 38% -- everyone was wrong.

**Critical METR nuance the guide must note:** The study tested **Cursor Pro**, not Claude Code. Participants had extensive repository experience but minimal Cursor-specific experience. Zvi Mowshowitz called the setting "hostile" for AI (familiar codebases, hourly pay, high quality standards).

**METR's follow-up (Aug 2025):** Claude 3.7 Sonnet achieved 38% success on 18 real OSS tasks by automatic test scoring, but **none of the submissions were mergeable as-is** when manually reviewed. 91-100% had testing gaps. This reinforces the verification loops argument powerfully.

**Bottom line:** "10x" is overhyped. "Meaningfully faster for many tasks" is real. The biggest gains come from prototyping, unfamiliar codebases, and boilerplate-heavy work. For experienced developers working on familiar, complex codebases, gains are smaller or negative without good workflow practices.

---

## 16. Sources

### Official Anthropic
- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Hooks Guide](https://code.claude.com/docs/en/hooks)
- [Settings](https://code.claude.com/docs/en/settings)
- [MCP Docs](https://code.claude.com/docs/en/mcp)
- [Skills](https://code.claude.com/docs/en/skills)
- [Slash Commands](https://code.claude.com/docs/en/slash-commands)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Status Line](https://code.claude.com/docs/en/statusline)
- [Common Workflows](https://code.claude.com/docs/en/common-workflows)
- [Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Model Configuration](https://code.claude.com/docs/en/model-config)
- [Memory](https://code.claude.com/docs/en/memory)
- [Fast Mode](https://code.claude.com/docs/en/fast-mode)
- [Costs](https://code.claude.com/docs/en/costs)
- [Claude Code on the Web](https://code.claude.com/docs/en/claude-code-on-the-web)
- [How Anthropic Teams Use Claude Code](https://claude.com/blog/how-anthropic-teams-use-claude-code)
- [Introducing Claude Opus 4.6](https://www.anthropic.com/news/claude-opus-4-6)

### Creator Workflows (Boris Cherny)
- [Personal workflow thread (Threads, Jan 2026)](https://www.threads.com/@boris_cherny/post/DTBVlMIkpcm/) -- 13-part thread
- [Team tips thread (Threads, Jan 31, 2026)](https://www.threads.com/@boris_cherny/post/DUMZsVuksVv/) -- worktrees as #1 team tip
- [Plan Mode announcement (Threads, Nov 26, 2025)](https://www.threads.com/@boris_cherny/post/DRgx_WOjsmL/) -- "most slept-on feature"
- [Verification loops (Threads)](https://www.threads.com/@boris_cherny/post/DTBVvvhEnnW/) -- "2-3x quality"
- [Slash commands (Threads)](https://www.threads.com/@boris_cherny/post/DTBVqdvEj6S/) -- "/commit-push-pr every day"
- [InfoQ Coverage](https://www.infoq.com/news/2026/01/claude-code-creator-workflow/)
- [VentureBeat Coverage](https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are)
- [Paddo.dev Summary](https://paddo.dev/blog/how-boris-uses-claude-code/)

### Developer Blogs
- [Simon Willison: Living Dangerously with Claude](https://simonwillison.net/2025/Oct/22/living-dangerously-with-claude/)
- [Will Larson: Coding at Work](https://lethain.com/coding-at-work/)
- [Boris Tane: How I Use Claude Code](https://boristane.com/blog/how-i-use-claude-code/)
- [Armin Ronacher: What Is Plan Mode?](https://lucumr.pocoo.org/2025/12/17/what-is-plan-mode/)
- [Shrivu Shankar: How I Use Every Feature](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)
- [Builder.io: How I Use Claude Code](https://www.builder.io/blog/claude-code)
- [incident.io: Shipping Faster with Git Worktrees](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)

### Research Papers
- [METR Study (arXiv 2507.09089)](https://arxiv.org/abs/2507.09089) -- 19% slower finding
- [METR Blog Post](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/)
- [METR Follow-up (Aug 2025)](https://metr.org/blog/2025-08-12-research-update-towards-reconciling-slowdown-with-time-horizons/)
- [Cui et al. (SSRN 4945566)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4945566) -- 26% increase
- [Google RCT (arXiv 2410.12944)](https://arxiv.org/abs/2410.12944) -- ~21% faster, not significant
- [IFScale Paper (arXiv 2507.11538)](https://arxiv.org/abs/2507.11538) -- instruction-following degradation

### Study Analyses
- [Zvi Mowshowitz: On METR's AI Coding RCT](https://thezvi.substack.com/p/on-metrs-ai-coding-rct)
- [Sean Goedecke: METR Analysis](https://www.seangoedecke.com/impact-of-ai-study/)
- [Domenic Denicola: My Participation in the METR Study](https://domenic.me/metr-ai-productivity/)

### Security
- [Snyk ToxicSkills Study](https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/) -- 36.82% flaw rate
- [John Stawinski: Claude Code Action RCE](https://johnstawinski.com/2026/02/05/trusting-claude-with-a-knife-unauthorized-prompt-injection-to-rce-in-anthropics-claude-code-action/)
- [The Decoder: Cowork File Exfiltration](https://the-decoder.com/claude-cowork-hit-with-file-stealing-prompt-injection-days-after-anthropics-launch/)

### Configuration Repos
- [Trail of Bits: claude-code-config](https://github.com/trailofbits/claude-code-config) (~880 stars)
- [brianlovin/claude-config](https://github.com/brianlovin/claude-config)
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)

### Community Resources
- [HumanLayer: Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Arize AI: CLAUDE.md Prompt Optimization](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning/)
- [GitButler: Automate with Hooks](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks)
- [Aaron Brethorst: Demystifying Hooks](https://www.brethorsting.com/blog/2025/08/demystifying-claude-code-hooks/)
