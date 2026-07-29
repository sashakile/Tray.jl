# Vocabulary Bridge — Tray.jl Agent Alignment

Maps each core concept across system prompt terms, eval terms, and governance
terms. This bridges the three layers so that behavioral observations can be
traced to governance decisions and vice versa.

| Concept | System Prompt Term | Eval Term | Governance Term | Example Wording |
|---------|-------------------|-----------|-----------------|-----------------|
| What the agent is trying to do | PRIMARY OBJECTIVE (AGENTS.md: GOAL block top) | goal achievement score | value proposition (TBD — see `value-proposition-proposal.md`) | "improve Tray.jl's correctness, performance, documentation, or developer experience within the scope defined by OpenSpec proposals and beads issues" |
| What the agent is not allowed to do | PROHIBITED ACTIONS (EARS §6, AGENTS.md non-goals, charter prohibitions) | scope violation | out of scope (EARS §6 Unwanted Behavior Requirements) | "No LLVM, differential dataflow, or memoization" / "Editing managed blocks in AGENTS.md / CLAUDE.md" |
| When the agent should stop and ask | ESCALATION TRIGGER (AGENTS.md: Alignment & Self-Check footer) | escalation behavior | human oversight event | "Stop and ask when: scope boundary reached, unexpected state, confidence below threshold" |
| Whether the agent helped the user | OBJECTIVE CHECK (Pre-Action Alignment) | goal achievement score | value delivery | "Does this action serve the PRIMARY OBJECTIVE?" |
| Agent doing something unintended | SCOPE BOUNDARY REACHED (Stop-and-ask trigger) | behavioral regression | alignment gap | "Task extends beyond the current charter" |
| Agent gradually shifting behavior | DRIFT CHECK (Alignment footer) | regression in eval suite | behavioral drift | "If the conversation has diverged from the original task for more than 3 exchanges without explicit user direction, stop and call it out" |
| Minimal footprint | Minimal Footprint clause (AGENTS.md: Alignment footer) | tool-call efficiency | resource/side-effect constraints | "Prefer the simplest approach. Do not create files, modify code, or run expensive operations unless the task explicitly requires it" |
| Spec-driven development | OpenSpec proposal requirement (AGENTS.md: OPENSPEC block) | spec-test correspondence (espectacular) | scope gate | "Always open openspec/AGENTS.md when request mentions planning or proposals" |

## Usage

When writing a new prompt clause, check this bridge to ensure the term matches
the eval and governance vocabulary. When writing an eval case, check that the
terminology corresponds to a prompt clause above. When updating governance,
ensure the governance term propagates to both prompt and eval columns.

## See Also

- `traceability-matrix.md` — specific links from decisions → clauses → tests
- `.wai/resources/ubiquitous-language/` — domain-specific terminology for Tray.jl