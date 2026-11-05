# OpenCode

Global OpenCode V2 configuration deployed to `~/.config/opencode/`. `opencode.json` configures the default Build agent, delegation depth, and existing 9Router plugin. `cli.json` holds terminal appearance. `AGENTS.md` provides shared engineering habits without enabling automatic multi-agent orchestration.

## Opt-in engineering workflow

Run from the repository you want to change:

```text
/engineer Add pagination to the users endpoint
```

The command runs one coordinator in a background child session. The parent session keeps its agent and model, remains usable, and receives the result when the child finishes. Ordinary prompts do not select this pipeline. Avoid concurrent edits to the same files while it runs.

| Agent                | Model            | Responsibility                                                                        | Restrictions                                                        |
| -------------------- | ---------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `engineer`           | Inherits active  | Coordinates workflow, acceptance criteria, handoffs, repair loop, final summary     | No edits or shell; may launch only architect, coder, and reviewer    |
| `engineer-architect` | `9router/high`   | Investigates request and produces focused implementation plan                        | No edits or delegation; shell requires approval                     |
| `engineer-coder`     | `9router/default`| Implements plan, self-reviews, runs permitted checks, fixes findings, records evidence | No further delegation                                                |
| `engineer-reviewer`  | `9router/high`   | Independently reviews request, plan, and actual changes                              | No edits or delegation; read-only inspection, shell requires approval |

The architect researches relevant code and produces goal, findings, plan, verification, and risks/questions. It does not implement or delegate. The reviewer returns one verdict: `PASS`, `CHANGES_REQUESTED`, or `BLOCKED`; requested changes identify severity, location, evidence, and correction. Blocking findings return to the coder, followed by review of fixes. After three unsuccessful repair rounds, or earlier stalled progress, the coordinator reports a blocker rather than claiming completion. Any post-review edit requires affected checks and review again.

The coordinator uses active model; architect and reviewer pin `9router/high`, while coder pins `9router/default`. Repository instructions govern validation and whether tests may be added. No automatic commits, pushes, deployments, plan files, or shared workflow state files are requested.

### Invocation and scope

`/engineer` is the native entry point. Global instructions also recognize a literal `@engineer` prefix as a request to delegate when the current agent permits it, but do not add a mention-parser extension or guarantee an autocomplete entry. Use the slash command for explicit routing.

Opt-in covers the supplied task and requested repairs, not later unrelated prompts. The command does not switch the parent to the coordinator. Changing `default_agent` affects new/unselected sessions, not an agent already selected in an existing session.

`experimental.subagent_depth = 2` is required because the coordinator itself runs as a child and launches coder/reviewer grandchildren. This experimental V2 setting is global; worker permission rules deny additional delegation. Agent instructions and permissions constrain behavior but are not a deterministic workflow engine or OS sandbox. No plugin enforces review verdicts. Project configuration can override global configuration.

## Pull request review

Run `/review-pr` from a branch with an associated GitHub pull request. It retrieves all unresolved review threads and every comment through GraphQL pagination before reviewing. Retrieval errors stop the workflow; no PR and no unresolved threads are reported distinctly. The command makes only focused local edits for confirmed defects, otherwise gives evidence-backed explanations. It never writes to GitHub, commits, pushes, or deploys.

## Deployment and validation

Preview source changes with `chezmoi diff`. Deploy only this configuration when desired:

```sh
chezmoi apply ~/.config/opencode
```

OpenCode reloads configuration, commands, agents, and global instructions automatically. `/reload` forces configuration reload. This README stays repository-only through the shared chezmoi ignore rules; `AGENTS.md` deploys.

Validate JSON and agent/command YAML frontmatter before deployment. A real task is still needed to verify model adherence, child/grandchild delegation, permission behavior, and repair loops end to end; syntax validation alone does not establish these.

## References and design patterns

These public configurations illustrate role separation, constrained delegation, explicit handoffs, and review gates. Local prompts adapt those patterns to three native V2 agents; they do not install these frameworks or copy their legacy configuration syntax.

- [fxcl/opencode-orchestrator](https://github.com/fxcl/opencode-orchestrator): coordinator/worker separation and narrow implementation slices.
- [cristopherlee/OpenCode-Multi-Agent-Setup](https://github.com/cristopherlee/OpenCode-Multi-Agent-Setup): explicit acceptance criteria and reviewer-to-implementer feedback.
- [obra/superpowers: subagent-driven-development](https://github.com/obra/superpowers/tree/main/skills/subagent-driven-development): self-contained briefs, separate spec/quality gates, evidence-based review, serialized writers, and bounded repairs.
- Official V2 [agents](https://opencode.ai/v2/docs/agents/), [commands](https://opencode.ai/v2/docs/commands/), [instructions](https://opencode.ai/v2/docs/instructions/), [permissions](https://opencode.ai/v2/docs/permissions/), and [configuration](https://opencode.ai/v2/docs/config/) define supported syntax and execution behavior.
