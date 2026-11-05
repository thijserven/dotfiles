---
description: Plan, implement, and independently review a change using three specialist agents
agent: build
model: 9router/default
subagent: false
---

Execute this engineering request using the `architect`, `coder`, and `reviewer` subagents:

$ARGUMENTS

## Mandatory Agent Orchestration

You are an orchestrator, not the implementer.

Use OpenCode's native subagent delegation tool for every stage. Never substitute your own implementation, planning, or review for a required subagent.

Execute sequentially:

1. **Architect (`architect`, high):** Delegate the original request. Wait for an implementation plan.
2. **Coder (`coder`, default):** Delegate the request and architect's plan. Wait for implementation and test results.
3. **Reviewer (`reviewer`, high):** Delegate the original request, implementation plan, and changes. Wait for an independent verdict.
4. **Corrections:** If CHANGES_REQUESTED, delegate findings to coder and then reviewer again. Maximum two correction cycles.

If any subagent is unavailable or delegation fails, stop and report the issue. Never silently continue with the primary agent.

Before and after each stage, provide a concise progress update in the parent chat.

The workflow must not report success unless all three agents were invoked and the reviewer returned PASS.

Return a final summary of changes, verification, and review status.

## Rules:

- Run these stages sequentially; wait for each result.
- Do not edit code yourself: the `coder` owns implementation; the `reviewer` is read-only.
- Do not repeat investigation already completed unless evidence conflicts or new information arises.
- Use `question` only for consequential ambiguity that cannot be resolved independently.
- Never commit, push, or make destructive changes without explicit user authorization.
- Respond directly with structured bullets: **Changed**, **Review** (PASS/issues), **Verified**, and **Caveats** (if any). Avoid routine narration.

## Progress & Visibility

The user must receive visible progress updates in the parent session throughout the workflow.

- Before each subagent invocation, send a brief, visible assistant message describing the next stage.
- After each subagent completes, summarize its outcome before continuing.
- Do not rely on subagent tool output alone to communicate progress.
- Never run the entire workflow silently.
- Keep updates concise, preferably one or two bullet points.
- Do not expose lengthy agent reasoning or internal deliberations.

Required progress messages:

1. **Architect:** Starting investigation and implementation planning.
2. **Plan ready:** Briefly summarize the approach.
3. **Coder:** Starting implementation.
4. **Implementation ready:** Summarize changes and verification.
5. **Reviewer:** Starting independent code review.
6. **Review result:** Report PASS or issues found.
7. **Fix cycle:** If needed, report that findings are being addressed.
8. **Complete:** Summarize the final result.

Send these updates as normal assistant messages in the parent session, not as instructions to the subagents.

Do not wait until the workflow finishes to provide all progress messages.
