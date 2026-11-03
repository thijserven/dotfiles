# OpenCode

Global OpenCode V2 configuration deployed to `~/.config/opencode/`. `opencode.json` configures the default Build agent, delegation depth, and existing 9Router plugin. `cli.json` holds terminal appearance. `AGENTS.md` provides shared engineering habits without enabling automatic multi-agent orchestration.

## Opt-in engineering workflow

Run from the repository you want to change:

```text
/engineer Add pagination to the users endpoint
```

The command runs one coordinator in a background child session. The parent session keeps its agent and model, remains usable, and receives the result when the child finishes. Ordinary prompts do not select this pipeline. Avoid concurrent edits to the same files while it runs.

| Agent | Responsibility | Restrictions |
| --- | --- | --- |
| `engineer` | Research, acceptance criteria, implementation plan, handoffs, repair loop, final summary | No edits or shell; may launch only coder and reviewer |
| `engineer-coder` | Scoped implementation, self-review, permitted checks, fixes, evidence | No further delegation |
| `engineer-reviewer` | Independent requirements and code-quality review of actual changes | No edits or delegation; shell limited to Git status, diff, and log |

The reviewer checks staged, unstaged, and untracked changes against the coder's recorded baseline. Test/build execution evidence comes from the coder, not independent reviewer execution. Review returns separate spec-compliance and code-quality verdicts; both must pass. Blocking findings return to the coder, followed by review of the fixes. After three unsuccessful repair rounds, or earlier stalled progress, the coordinator reports a blocker rather than claiming completion. Any post-review edit requires affected checks and review again.

Agents inherit the active model; no provider-specific model IDs are pinned. Repository instructions govern validation and whether tests may be added. No automatic commits, pushes, deployments, plan files, or shared workflow state files are requested.

### Invocation and scope

`/engineer` is the native entry point. Global instructions also recognize a literal `@engineer` prefix as a request to delegate when the current agent permits it, but do not add a mention-parser extension or guarantee an autocomplete entry. Use the slash command for explicit routing.

Opt-in covers the supplied task and requested repairs, not later unrelated prompts. The command does not switch the parent to the coordinator. Changing `default_agent` affects new/unselected sessions, not an agent already selected in an existing session.

`experimental.subagent_depth = 2` is required because the coordinator itself runs as a child and launches coder/reviewer grandchildren. This experimental V2 setting is global; worker permission rules deny additional delegation. Agent instructions and permissions constrain behavior but are not a deterministic workflow engine or OS sandbox. No plugin enforces review verdicts. Project configuration can override global configuration.

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
