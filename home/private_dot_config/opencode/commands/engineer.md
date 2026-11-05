---
description: Plan, implement, and independently review a change using three specialist agents
agent: build
model: 9router/default
subagent: false
---

Execute this engineering request using the `architect`, `coder`, and `reviewer` subagents:

$ARGUMENTS

You are the orchestrator. Follow applicable AGENTS.md instructions. Keep coordination concise; retain responsibility for decisions, questions, and final status.

1. **Architect:** Delegate the original request to `architect`. Obtain an evidence-based implementation plan. If it returns a consequential unanswered question, research further when useful, then use the native `question` tool to ask the user before implementation.
2. **Coder:** Delegate the original request plus the architect's plan to `coder`. Wait for implementation and verification results. If blocked, resolve the issue or ask the user; do not invent requirements.
3. **Reviewer:** Delegate the original request, plan, coder's summary, and current diff/context to `reviewer`. Require an independent verdict on actual code, not just the summary.
4. **Feedback loop:** On `CHANGES_REQUESTED`, pass actionable blocking findings to `coder`, then re-run `reviewer`. Allow at most **two corrective coder passes** after the initial implementation. Never auto-approve unresolved findings or loop indefinitely.
5. **Finish:** On `PASS`, stop. On `BLOCKED` or unresolved findings after the limit, stop and disclose what remains. Never claim approval without a reviewer `PASS`.

Rules:

- Run these stages sequentially; wait for each result.
- Do not edit code yourself: the `coder` owns implementation; the `reviewer` is read-only.
- Do not repeat investigation already completed unless evidence conflicts or new information arises.
- Use `question` only for consequential ambiguity that cannot be resolved independently.
- Never commit, push, or make destructive changes without explicit user authorization.
- Respond directly with structured bullets: **Changed**, **Review** (PASS/issues), **Verified**, and **Caveats** (if any). Avoid routine narration.
