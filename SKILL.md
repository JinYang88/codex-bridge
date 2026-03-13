---
name: codex-bridge
description: Collaborate with Codex (GPT 5.4) for code review,
  plan validation, and technical debates. Use when you want a
  second opinion from a different model.
---

# Codex Bridge

## When to Use
- After implementing a feature: run review+fix loop
- After writing a plan: get Codex to challenge it
- Technical decision with multiple valid approaches: debate
- User says: "review", "让 codex 看看", "codex review",
  "review+fix", "second opinion"

## When NOT to Use
- Trivial changes (typo fixes, formatting, config tweaks)
- Exploratory / prototype code
- Diff > 1500 lines — split into smaller chunks first
- Rate limit concern — check `.codex-bridge/usage.log`

## How to Use

### Code Review
1. Run: `bash <skill-dir>/scripts/codex-review.sh <workdir> <scope> [--dry-run] [--round N] [--prev-findings <file>]`
   - scope: `dirty` (default) | `staged` | `HEAD~1..HEAD`
   - `--dry-run`: only show findings, don't proceed to fix
   - `--round N`: pass current round number (affects prompt focus)
   - `--prev-findings <file>`: path to previous round's output file for context pack forwarding
2. Parse the output for Findings section
   - If output doesn't match expected format (no ## Findings/Verdict/Summary),
     treat as WARNING-level free-text and present to user
3. Check for TRUNCATED warning — if present, note to user that
   some changes were not reviewed
4. Act on findings:
   - CRITICAL: must fix before continuing
   - WARNING: fix unless there's a good reason not to
   - SUGGESTION: apply if it improves code, skip if trivial
5. After fixing, save current findings to a temp file, then re-run with
   `--round 2 --prev-findings <saved-file>` (max 3 cycles)
   - Round 2+ prompts automatically focus on verifying fixes
   - **Context Pack Forwarding**: The `--prev-findings` flag passes
     the FULL findings from Round N-1 verbatim into the prompt.
     This lets Codex verify whether its prior concerns were actually addressed.
6. Convergence detection: if round N findings overlap >=50% with
   round N-1, stop iterating and escalate to user
7. **Conflict-Triggered Debate Escalation**: if you would APPROVE
   but Codex returns CRITICAL findings, auto-escalate to a mini-debate
   (one round). You MUST explicitly defend your position or concede
   for each CRITICAL finding. Do not dismiss valid Codex concerns.
8. Stop when verdict is APPROVE, 3 cycles reached, or convergence detected

### Plan Review (5-round auto-iteration)
1. Write current plan using the structured template:
   Goal, Constraints, Approach, Files Affected, Tradeoffs
2. Round 1: Run codex-ask.sh with prompt:
   `"Review this plan for gaps and risks:\n<plan content>"`
3. Present Codex's critique to user with round number
4. Revise plan based on valid points, show what changed and why
5. Round 2+: Re-submit revised plan to Codex with prompt:
   `"This is a revised plan after incorporating your previous feedback.
   Focus on whether the revisions address the gaps you identified
   and any NEW issues.\n\nPrevious critique:\n<full previous critique>\n\nRevised plan:\n<plan>"`
   - **Context Pack Forwarding**: The Round N prompt MUST include
     Codex's FULL critique from Round N-1 verbatim (not your summary).
6. Each round, display: round number, changes made, Codex findings,
   what was adopted vs rejected with reasoning
7. Stop when: (a) Codex returns no new substantive findings,
   (b) 5 rounds reached, or (c) user interrupts
8. After final round, present consolidated plan with full revision history

### General Question
1. Run: `bash <skill-dir>/scripts/codex-ask.sh <workdir> "<question>"`
2. Incorporate Codex's perspective into your response

## Environment Variables

These can be set before running scripts to tune behavior:

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEX_TIMEOUT` | 7200 | Timeout in seconds for codex exec (values >10000 auto-detected as milliseconds) |
| `CODEX_MODEL` | (config default) | Override model (e.g., `o3`, `gpt-5.4`) |
| `MAX_DIFF_LINES` | 1500 | Max diff lines before hunk-boundary truncation |

## Rules
- Never blindly apply all Codex suggestions. Use your judgment.
- If Codex and you disagree, present both views to the user.
- Don't call Codex for trivial changes (typo fixes, formatting).
- Always show the user what Codex found before auto-fixing.
- Keep review scope focused: don't send entire repo, send diffs.
- Codex runs in `--sandbox read-only` — it can read workspace files
  but cannot modify anything. All fixes are done by you (CC).

## Troubleshooting

- **Timeout**: Increase `CODEX_TIMEOUT` (e.g., `CODEX_TIMEOUT=300`).
  Large diffs take longer because Codex may read files in the workspace.
- **Empty output**: Check stderr in the error message. Common cause:
  Codex CLI not logged in (`codex login`).
- **Unstructured output**: Script auto-detects and wraps as RAW OUTPUT.
  Treat as WARNING-level findings.
- **Rate limit**: Check `.codex-bridge/usage.log` line count.
  ChatGPT Plus/Pro subscriptions have daily limits.
