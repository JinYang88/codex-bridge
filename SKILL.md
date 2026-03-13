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

## How to Use

### Code Review
1. Run: bash <skill-dir>/scripts/codex-review.sh <workdir> <scope> [--dry-run] [--round N]
   - scope: "dirty" (default) | "staged" | "HEAD~1..HEAD"
   - --dry-run: only show findings, don't proceed to fix
   - --round N: pass current round number (affects prompt focus)
2. Parse the output for Findings section
   - If output doesn't match expected format (no ## Findings/Verdict/Summary),
     treat as WARNING-level free-text and present to user
3. Check for ⚠️ TRUNCATED warning — if present, note to user that
   some changes were not reviewed
4. Act on findings:
   - CRITICAL → must fix before continuing
   - WARNING → fix unless there's a good reason not to
   - SUGGESTION → apply if it improves code, skip if trivial
5. After fixing, re-run review with --round 2 (max 3 cycles)
   - Round 2+ prompts automatically focus on verifying fixes,
     not re-reviewing everything
   - **Context Pack Forwarding**: Round N prompt MUST include the
     FULL findings from Round N-1 (not a summary). This lets Codex
     verify whether its prior concerns were actually addressed.
6. Convergence detection: if round N findings overlap >=50% with
   round N-1, stop iterating and escalate to user
7. **Conflict-Triggered Debate Escalation**: if you would APPROVE
   but Codex returns CRITICAL findings, auto-escalate to a mini-debate
   (one round). You MUST explicitly defend your position or concede
   for each CRITICAL finding. Do not dismiss valid Codex concerns.
8. Stop when verdict is APPROVE, 3 cycles reached, or convergence detected

### Plan Review (5-round auto-iteration)
1. Write current plan using the structured template (see §2.2):
   Goal, Constraints, Approach, Files Affected, Tradeoffs
2. Round 1: Run codex-ask.sh with prompt:
   "Review this plan for gaps and risks: $(cat plan.md)"
3. Present Codex's critique to user with round number
4. Revise plan based on valid points, show what changed and why
5. Round 2+: Re-submit revised plan to Codex with prompt:
   "This is a revised plan after incorporating your previous feedback.
   Focus on whether the revisions address the gaps you identified
   and any NEW issues."
   - **Context Pack Forwarding**: The Round N prompt MUST include
     Codex's FULL critique from Round N-1 verbatim (not your summary).
     This lets Codex judge whether its prior concerns were addressed.
6. Each round, display: round number, changes made, Codex findings,
   what was adopted vs rejected with reasoning
7. Stop when: (a) Codex returns no new substantive findings,
   (b) 5 rounds reached, or (c) user interrupts
8. After final round, present consolidated plan with full revision history

### General Question
1. Run: bash <skill-dir>/scripts/codex-ask.sh <workdir> "<question>"
2. Incorporate Codex's perspective into your response

## Rules
- Never blindly apply all Codex suggestions. Use your judgment.
- If Codex and you disagree, present both views to the user.
- Don't call Codex for trivial changes (typo fixes, formatting).
- Always show the user what Codex found before auto-fixing.
- Keep review scope focused: don't send entire repo, send diffs.
