# Codex Bridge

A Claude Code skill that calls [Codex CLI](https://github.com/openai/codex) (GPT 5.4) as a second pair of eyes. Claude Code (Opus 4.6) drives implementation; Codex reviews in a read-only sandbox. Think of it as pilot + co-pilot: CC writes code and orchestrates, Codex catches blind spots through structured code review, plan validation, and technical debate.

## Prerequisites

- **Codex CLI** installed and authenticated (`npm install -g @openai/codex && codex auth login`)
- **ChatGPT Plus/Pro subscription** (Codex CLI uses your subscription quota, not API billing)
- **git** (review mode depends on `git diff`)

## Installation

1. Clone or copy this repo into your Claude Code skills directory:

   ```bash
   git clone https://github.com/<your-username>/codex-bridge.git ~/.claude/skills/codex-bridge
   ```

2. Add `.codex-bridge/` to your project's `.gitignore` (this directory stores usage logs and run history):

   ```bash
   echo '.codex-bridge/' >> .gitignore
   ```

3. Claude Code will auto-detect the skill from `SKILL.md`. No additional configuration needed.

## Quick Start

### Code Review (most common)

Tell CC: `review+fix`, `让 codex 看看`, or `codex review`

CC collects your dirty diff, filters secrets, sends it to Codex in a read-only sandbox, shows you the findings (CRITICAL / WARNING / SUGGESTION), fixes issues, and re-reviews -- up to 3 rounds until convergence.

Add `--dry-run` to see findings without auto-fixing.

### Plan Review

Tell CC: `codex plan review` or `让 codex 审下方案`

CC formats your plan into a structured template (Goal / Constraints / Approach / Files Affected / Tradeoffs) and runs up to 5 rounds of iterative review with Codex. Each round includes full context from the previous round so Codex can verify whether its concerns were addressed.

### Ask Codex a Question

```bash
bash scripts/codex-ask.sh . "REST vs GraphQL for a multi-tenant SaaS?"
```

Or in conversation: `问问 codex，这个并发方案有没有 race condition`

## How It Works

```
You write code
    ↓
CC collects git diff (10-line context)
    ↓
Preflight: filter secret files (.env, .key, .pem), redact passwords/tokens
    ↓
codex exec --sandbox read-only (Codex cannot modify files)
    ↓
Structured findings: CRITICAL / WARNING / SUGGESTION + Verdict
    ↓
CC fixes CRITICAL & WARNING, asks you about SUGGESTION
    ↓
Round 2+: re-review with full previous findings (context pack forwarding)
    ↓
Stop: APPROVE verdict, 3 rounds reached, or ≥50% finding overlap
```

Key design choices:
- **Read-only sandbox**: Codex runs in `--sandbox read-only` mode -- it can read your code but cannot modify anything. All fixes are made by CC.
- **Secret filtering**: Diffs are pre-filtered to exclude `.env`, credential files, and common secret patterns before leaving your machine.
- **Prompt injection defense**: User input (diffs, plans, questions) is wrapped in delimiters and explicitly marked as untrusted data.
- **Hunk-boundary truncation**: Large diffs (>2000 lines) are truncated at hunk boundaries, never mid-hunk.

## File Structure

```
codex-bridge/
├── README.md              # This file
├── SKILL.md               # Skill instructions (read by Claude Code)
├── DESIGN.md              # Technical design document (Chinese)
├── WORKFLOW.md             # Daily workflow guide (Chinese)
├── USAGE.md               # Detailed usage guide (Chinese)
├── .gitignore             # Excludes .codex-bridge/
├── scripts/
│   ├── codex-review.sh    # Code review: diff → Codex → structured findings
│   ├── codex-ask.sh       # General question: prompt → Codex → answer
│   └── parse-findings.sh  # Parse review output into severity counts
└── .codex-bridge/         # Runtime data (gitignored)
    └── usage.log          # Call history for quota tracking
```

## Configuration

| Setting | Default | How to change |
|---------|---------|---------------|
| Max diff lines | 2000 | `MAX_DIFF_LINES` in `codex-review.sh` |
| Review rounds limit | 3 | Defined in SKILL.md orchestration rules |
| Plan review rounds limit | 5 | Defined in SKILL.md orchestration rules |
| Codex timeout | 120s | `TIMEOUT_CMD` in scripts |
| Secret file patterns | `.env`, `.key`, `.pem`, `credentials`, etc. | `SECRET_FILE_PATTERNS` in `codex-review.sh` |

## Further Reading

- **[WORKFLOW.md](WORKFLOW.md)** -- Daily usage patterns and quick reference
- **[DESIGN.md](DESIGN.md)** -- Full technical design, architecture decisions, and roadmap

## License

MIT
