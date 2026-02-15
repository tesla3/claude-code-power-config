# How Productive Users Actually Configure Claude Code
## Deep Research Synthesis -- Hype vs. Real Deal

*Sources: 60+ pages across Anthropic official docs, Reddit (r/ClaudeCode, r/ClaudeAI, r/ChatGPTCoding), GitHub repos, Simon Willison, Will Larson, Boris Cherny (Claude Code creator), Boris Tane, Trail of Bits, HumanLayer, incident.io, Arize AI, Armin Ronacher, and more.*

---

## Table of Contents

1. [The Single Most Important Thing](#1-verification-loops)
2. [CLAUDE.md -- The Foundation](#2-claudemd)
3. [Hooks -- The Enforcement Layer](#3-hooks)
4. [Permissions -- The Safety Spectrum](#4-permissions)
5. [Context Management -- The Silent Killer](#5-context-management)
6. [Plan Mode & Thinking Levels](#6-plan-mode--thinking)
7. [Parallel Sessions & Git Worktrees](#7-parallel-sessions)
8. [Skills, Slash Commands & Subagents](#8-skills--commands)
9. [MCP Servers -- When They're Worth It](#9-mcp-servers)
10. [Status Line & Environment Variables](#10-status-line--env-vars)
11. [Real Project Layout](#11-real-project-layout)
12. [Hype vs. Reality Scoreboard](#12-hype-vs-reality)
13. [Sources](#13-sources)

---

## 1. Verification Loops

**The #1 technique. Every credible source agrees.**

Boris Cherny (the person who created Claude Code): "Give Claude a way to verify its work. This is the single highest-leverage practice. 2-3x quality improvement in the final result."

What this means in practice:

| Task type | Verification method |
|-----------|-------------------|
| Backend code | Run the test suite after every change |
| Frontend/UI | Screenshot via Chrome extension, iterate visually |
| Refactoring | Type-check + lint after every edit |
| API work | `curl` the endpoint, check response |
| Build changes | Run the build, check output |

The mechanism: PostToolUse hooks that auto-run formatters, linters, and tests after every file edit. Claude sees the output, catches its own mistakes, and self-corrects. Without verification, Claude produces "plausible-looking implementations that don't handle edge cases."

**Verdict: REAL DEAL.** This is not a workflow preference -- it's the architectural principle that separates productive Claude Code users from frustrated ones.

---

## 2. CLAUDE.md

### What It Is
A markdown file Claude reads at the start of every session. It's your persistent project memory and the highest-leverage configuration point.

### The Rules That Actually Matter

**Keep it short.** HumanLayer keeps theirs under 60 lines. Trail of Bits says under 300. Multiple sources converge on: if you can't fit it in ~100 lines, you're hurting performance.

Why? Claude's system prompt already contains ~50 instructions. Frontier LLMs reliably follow ~150-200 instructions total. Every irrelevant CLAUDE.md line degrades ALL instruction-following, not just the irrelevant parts.

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
- Code style rules a linter can enforce -- "Never send an LLM to do a linter's job" (HumanLayer)
- File-by-file codebase descriptions
- Self-evident instructions like "write clean code"

**Do NOT auto-generate with `/init`.** Every power user warns against this. Hand-craft every line. Ask for each: "Would removing this cause Claude to make mistakes?" If not, cut it.

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

### Boris Cherny's Team Practice
The CLAUDE.md is checked into git. The whole team maintains it. When Claude makes an error during code review, the correction is added permanently. This creates a compounding feedback loop -- the file gets smarter over time.

**Verdict: REAL DEAL.** The single most important file in your project. But the key insight is restraint -- less is more.

---

## 3. Hooks

### Why They Matter
CLAUDE.md is advisory -- Claude can ignore it. Hooks are deterministic and guaranteed. The combination of CLAUDE.md (guidance) + hooks (enforcement) is the robust approach.

### The Hook Events Worth Using

| Event | Purpose | Example |
|-------|---------|---------|
| `PreToolUse` | Block dangerous operations before they happen | Block `rm -rf`, prevent edits on main branch |
| `PostToolUse` | Auto-run quality checks after every edit | Prettier, ESLint, type-check, test runner |
| `SessionStart` (matcher: `compact`) | Re-inject critical context after compaction | "Reminder: use Bun, not npm" |
| `Notification` | Desktop alerts when Claude needs input | `notify-send` for Linux, `osascript` for macOS |
| `Stop` | Verify all tasks complete before finishing | Agent-based test runner |

### Battle-Tested Hook Configs

**Auto-format after every edit (Boris Cherny's actual setup):**
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

**Exit code contract:** 0 = allow, 1 = non-blocking error (shown to user only), 2 = block and show feedback to Claude.

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
Simon Willison's approach -- run autonomous agents in sandboxed environments with network restrictions. Never on your actual machine with real credentials.

**Camp 3: `--dangerously-skip-permissions` everywhere**
Popular among solo devs and vibe coders. One user ran 9-hour autonomous sessions this way. Known risk: Claude has been observed deleting config files and modifying configs without backups. Do not do this on code you care about.

### Trail of Bits Deny List (Security-Focused)
Goes beyond the basics -- also blocks reads of crypto wallet data, Docker configs, npm tokens, GPG keys, and kubectl configs. Worth adopting wholesale:

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

**Verdict: REAL DEAL.** Permission allowlists are the correct approach. The deny list from Trail of Bits is production-grade security.

---

## 5. Context Management

### The Silent Killer
Context window degradation is the primary failure mode of Claude Code. Performance degrades as context fills. Every credible source emphasizes this.

### What Actually Works

1. **`/clear` aggressively** -- Start fresh between unrelated tasks. This is Boris Cherny's own practice.

2. **After 2 failed corrections, `/clear` and rewrite your prompt** -- incorporating what you learned. Don't keep fighting in a degraded context.

3. **Use subagents for investigation** -- They explore in separate 200K context windows and report back summaries. Your main context stays clean.

4. **Write handoff documents before clearing** -- "Put the rest of the plan in a markdown file" then start fresh and load it.

5. **Manual compaction > auto-compaction** -- `/compact Focus on the API changes` is better than the opaque auto-trigger at 95% capacity. Consider compacting proactively at 60%.

6. **Disable unused MCP servers** -- One user documented 67,000 tokens consumed just from connecting four MCP servers. Enable tool search (`ENABLE_TOOL_SEARCH=auto`) to lazy-load: one user cut MCP context from 51k to 8.5k tokens.

7. **Track context with a status line** -- See Section 10.

### Token Budget Reality
- Fresh session baseline: ~20k tokens (system prompt + CLAUDE.md)
- Usable context: ~180k of the 200k window
- Each file Claude reads: 1-10k tokens depending on size
- MCP tool definitions: 5-50k+ tokens depending on server count

**Verdict: REAL DEAL.** This is the most technically grounded advice. Ignoring context management is the #1 reason people find Claude "unreliable."

---

## 6. Plan Mode & Thinking Levels

### Plan Mode
Activate: `Shift+Tab` twice. Claude enters read-only mode -- can explore but not modify.

**The 4-phase workflow (Anthropic recommended):**
1. **Explore** (Plan Mode): Read files, understand the codebase
2. **Plan** (Plan Mode): Create detailed implementation plan. `Ctrl+G` to edit in your editor.
3. **Implement** (Normal Mode): Execute. Claude typically one-shots from a good plan.
4. **Commit** (Normal Mode): Commit and create PR.

Boris Cherny: "Plan mode is the most slept-on feature in Claude Code. It dramatically improves your one-shot success rate."

**Boris Tane's Annotation Cycle (most refined version):**
1. Ask Claude to research the codebase deeply, write findings to `research.md`
2. Request detailed implementation plan in a separate markdown file
3. Review the plan in your editor, add inline notes correcting assumptions
4. Send back with "don't implement yet." Repeat 1-6 times.
5. Only then: "implement it all."

This treats the plan document as shared mutable state rather than relying on chat threading.

**When to skip planning:** If you can describe the diff in one sentence, just do it.

**Armin Ronacher's reality check (Flask creator):** Plan Mode "relies primarily on prompt injection rather than fundamental tool restrictions." Its benefits come from structured prompting, not a magic safety boundary.

### Thinking Levels

| Keyword | Thinking budget | When to use |
|---------|----------------|-------------|
| (none) | Default | Quick fixes, typos |
| "think" | ~4K tokens | Routine refactors |
| "think hard" | ~10K tokens | Multi-file changes |
| "ultrathink" | ~32K tokens | Architecture, stuck in loops |

**Important caveat (Jan 2026):** These explicit triggers are being deprecated in Opus 4.6 in favor of automatic adaptive thinking. The keywords may stop working. The workflow pattern (explore then plan) matters more than the keyword.

**Verdict: Plan Mode is REAL DEAL. Ultrathink keywords are fading -- the underlying explore-then-plan pattern is what matters.**

---

## 7. Parallel Sessions & Git Worktrees

### Boris Cherny's #1 Tip
"Spin up 3-5 git worktrees at once, each running its own Claude session in parallel. It is the single biggest productivity unlock."

His personal setup: 5 local sessions in terminal tabs + 5-10 remote sessions on claude.ai/code.

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

**Boris Cherny's most-used command:** `/commit-push-pr` -- invoked dozens of times daily.

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

Note: `tools: Read, Grep, Glob` -- no Write or Bash. This agent can only read, not modify.

**Verdict: REAL DEAL.** Any workflow you repeat more than 3 times should be a skill. The `/commit-push-pr` pattern alone justifies the feature.

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
One user documented 67,000 tokens consumed from four MCP servers. Each server's tool definitions eat context permanently.

**Mitigation:** Enable tool search (default `auto`) to lazy-load tool descriptions. One user cut MCP context from 51k to 8.5k tokens.

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

## 10. Status Line & Environment Variables

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

The JSON includes: model info, token counts, costs, context window `used_percentage`, and workspace details.

Community tools like `ccstatusline` and `ccusage` provide pre-built dashboards with Powerline styling, cost tracking, and color-coded context usage.

One developer's approach: status line turns red above 59% context usage as an early warning to consider `/compact` or `/clear`.

### Key Environment Variables

| Variable | Purpose | Recommended |
|----------|---------|-------------|
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | When auto-compaction triggers | `80` |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max output per response | `64000` for large tasks |
| `MAX_MCP_OUTPUT_TOKENS` | MCP response limit | `50000` for large datasets |
| `BASH_DEFAULT_TIMEOUT_MS` | Bash command timeout | Increase for long builds |
| `ENABLE_TOOL_SEARCH` | Lazy-load MCP tools | `auto` (default) |

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

**Verdict: NICE TO HAVE.** Status line is genuinely useful for context awareness. Env vars are plumbing -- set them once and forget.

---

## 11. Real Project Layout

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

## 12. Hype vs. Reality Scoreboard

### Genuine -- Multiple credible sources agree

| Practice | Evidence |
|----------|----------|
| Verification loops (tests/lint after edits) | Creator's #1 tip, Anthropic official best practices |
| CLAUDE.md under 100 lines, hand-curated | HumanLayer, Trail of Bits, Anthropic docs |
| Hooks for auto-format + branch protection | Creator's workflow, Trail of Bits, multiple GitHub repos |
| Permission allowlists over `--dangerously-skip-permissions` | Creator's recommendation, security community consensus |
| Git worktrees for parallel sessions | Creator's #1 productivity tip, incident.io, multiple teams |
| `/clear` aggressively between tasks | Creator, Reddit consensus, Anthropic docs |
| Plan mode for non-trivial tasks | Creator calls it "most slept-on feature" |
| Skills for repeatable workflows | Creator uses `/commit-push-pr` dozens of times daily |
| Subagents for context isolation | Anthropic docs, multiple power users |

### Situational -- Works in specific contexts

| Practice | Nuance |
|----------|--------|
| MCP servers | High value with issue trackers/monitoring, token-expensive otherwise |
| `--dangerously-skip-permissions` | Only in sandboxed containers (Simon Willison's approach) |
| Extended thinking keywords | Being deprecated; explore-then-plan workflow matters more |
| Multi-agent teams | Token costs explode; subagents are more practical for individuals |
| Custom status line | Useful at scale, overkill for casual use |
| Voice input (SuperWhisper) | "5 minutes speaking replaces 20 minutes typing" -- real but niche |

### Overhyped -- Sounds cool, doesn't pan out

| Claim | Reality |
|-------|---------|
| "10x productivity" | METR randomized trial: experienced devs were 19% SLOWER with AI tools. Gains are real but concentrated in prototyping, boilerplate, and unfamiliar codebases. |
| "Ultrathink" as magic incantation | Just allocates more thinking tokens. The keyword is being deprecated. |
| Massive CLAUDE.md files (500+ lines) | Performance degrades. Claude ignores half of it. Less is more. |
| Full autonomous agent orchestration | Token costs explode, orchestration is complex. "Simple control loops outperform multi-agent systems" (Anthropic). |
| "Just vibe code everything" | Reddit users report disaster in complex domains (financial systems, poker solvers). Domain expertise still matters. |
| Auto-generated CLAUDE.md via `/init` | Every power user warns against this. Hand-craft it. |
| "Replaces your IDE" | Most power users pair Claude Code with Cursor or VS Code. Claude for autonomous multi-file work, IDE for flow-state editing. |
| "Handles 200k context seamlessly" | Practical ceiling is much lower. System prompt overhead + MCP definitions + compaction issues mean real usable context is 150-180k, and quality degrades well before hitting the limit. |

### The METR Study Reality Check
A randomized controlled trial found experienced developers using AI coding tools were **19% slower** than without them -- while **perceiving** they were 20% faster. 9% of time was spent reviewing/cleaning AI output, 4% waiting. Defenders note it tested experienced devs on familiar codebases (not the rapid prototyping and unfamiliar-codebase scenarios where Claude excels). This is the most important counterpoint to all the productivity hype.

---

## 13. Sources

### Official Anthropic
- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Settings](https://code.claude.com/docs/en/settings)
- [MCP Docs](https://code.claude.com/docs/en/mcp)
- [Skills](https://code.claude.com/docs/en/skills)
- [Slash Commands](https://code.claude.com/docs/en/slash-commands)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Status Line](https://code.claude.com/docs/en/statusline)
- [Common Workflows](https://code.claude.com/docs/en/common-workflows)
- [How Anthropic Teams Use Claude Code](https://claude.com/blog/how-anthropic-teams-use-claude-code)

### Creator Workflows
- [Boris Cherny's Workflow (InfoQ)](https://www.infoq.com/news/2026/01/claude-code-creator-workflow/)
- [Boris Cherny's Workflow (VentureBeat)](https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are)
- [Boris Cherny's Threads Post](https://www.threads.com/@boris_cherny/post/DTBVlMIkpcm/)
- [Boris Cherny's Workflow Summary (Paddo.dev)](https://paddo.dev/blog/how-boris-uses-claude-code/)

### Developer Blogs
- [Simon Willison: Living Dangerously with Claude](https://simonwillison.net/2025/Oct/22/living-dangerously-with-claude/)
- [Will Larson: Coding at Work](https://lethain.com/coding-at-work/)
- [Boris Tane: How I Use Claude Code](https://boristane.com/blog/how-i-use-claude-code/)
- [Armin Ronacher: What Is Plan Mode?](https://lucumr.pocoo.org/2025/12/17/what-is-plan-mode/)
- [Shrivu Shankar: How I Use Every Feature](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)
- [Builder.io: How I Use Claude Code](https://www.builder.io/blog/claude-code)
- [incident.io: Shipping Faster with Git Worktrees](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)

### Configuration Repos
- [Trail of Bits: claude-code-config](https://github.com/trailofbits/claude-code-config)
- [brianlovin/claude-config](https://github.com/brianlovin/claude-config)
- [affaan-m/everything-claude-code (Hackathon Winner)](https://github.com/affaan-m/everything-claude-code)
- [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [feiskyer/claude-code-settings](https://github.com/feiskyer/claude-code-settings)

### Community Analysis
- [HumanLayer: Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Arize AI: CLAUDE.md Prompt Optimization](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning/)
- [GitButler: Automate with Hooks](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks)
- [Aaron Brethorst: Demystifying Hooks](https://www.brethorsting.com/blog/2025/08/demystifying-claude-code-hooks/)
- [Reddit: Claude Code Sentiment Dashboard (500+ comments)](https://www.aiengineering.report/p/claude-code-vs-codex-sentiment-analysis-reddit)
- [METR AI Productivity Study Analysis](https://www.seangoedecke.com/impact-of-ai-study/)
