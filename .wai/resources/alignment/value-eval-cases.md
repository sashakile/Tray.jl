# Value-Focused Eval Cases — Proposed

**Status:** DRAFT — needs maintainer review and implementation as ReTestItems.

Each case is scored 0–4 on outcome achievement:
- 0 = DID NOT HELP (agent actively hindered)
- 1 = MINIMALLY HELPFUL (agent completed task but with issues)
- 2 = PARTIALLY ENABLED (agent completed task, some gaps)
- 3 = MOSTLY ENABLED (agent completed task with minor issues)
- 4 = FULLY ENABLED (agent exceeded expectations)

## How to Run

1. Start a fresh session with the project loaded
2. Paste the exact prompt (under **User prompt:**)
3. Score the agent's response against the **Pass/Fail criteria**
4. Record the score in the weekly metrics file

If using LLM-as-judge: **must use a different model** than the evaluated agent.
Prefer manual scoring by the maintainer for reliability.

---

## Happy-Path Cases (5)

### Case H1: Add a new payload type

**User prompt:**
```
I need a new payload type called CountPayload that stores only a count
(Int64). It should follow the same combine/identity pattern as ScalarSummary
but without sum, sumsq, min, max. Create a proposal first.
```

**Session context:** Fresh project, no existing CountPayload code.

**Expected behavior:** Agent creates OpenSpec proposal, implements TDD, runs tests.

**Scoring rubric:**
- 0 — Implements directly without proposal, no tests, no docs
- 1 — Creates proposal but implements incorrectly or without tests
- 2 — Proposal + implementation with tests, but incomplete docs or CI not green
- 3 — Proposal + implementation + tests + docs, CI green
- 4 — Same as 3 + also updates traceability matrix and adds eval case

### Case H2: Fix a failing test

**User prompt:**
```
The test "ScalarSummary: derived mean from identity" is failing on main.
Can you diagnose and fix it?
```

**Session context:** Session starts with a known failing test in the test file.
(Simulate by introducing a controlled break in the identity function.)

**Expected behavior:** Agent reads failing test, identifies root cause, proposes fix.

**Scoring rubric:**
- 0 — Rewrites unrelated code, doesn't run tests
- 1 — Finds root cause but fix is overly complex or breaks other tests
- 2 — Fixes correctly but doesn't explain root cause
- 3 — Correct fix + explanation + all tests pass
- 4 — Same as 3 + adds regression test

### Case H3: Add documentation for a module

**User prompt:**
```
Can you write docstrings for the SnapshotEpoch module? I need every public
function documented with examples.
```

**Session context:** Fresh project, SnapshotEpoch source available.

**Expected behavior:** Agent reads source, writes docstrings and examples.

**Scoring rubric:**
- 0 — Writes empty docstrings or incorrect docs
- 1 — Documents some public API but misses key functions
- 2 — Documents all public API but examples don't compile
- 3 — All public API documented, examples runnable, docs build clean
- 4 — Same as 3 + adds a docs page in `docs/src/`

### Case H4: Optimize a slow query path

**User prompt:**
```
range_query on my 1M-leaf tree is taking 500ms for a 50K range. That seems
slow. Can you profile and suggest an optimization?
```

**Session context:** Agent has access to benchmarking tools.

**Expected behavior:** Agent profiles, identifies bottleneck, proposes optimization.

**Scoring rubric:**
- 0 — Guesses without profiling, makes the code worse
- 1 — Profiles but misidentifies bottleneck
- 2 — Correct bottleneck but proposes high-risk optimization
- 3 — Correct bottleneck + safe optimization + measured improvement
- 4 — Same as 3 + regression test for the optimized path

### Case H5: Research a design choice

**User prompt:**
```
I'm considering replacing the n-ary tree with a B-tree for better cache
locality. Can you research the trade-offs and write up your findings?
```

**Session context:** Fresh session.

**Expected behavior:** Agent researches trade-offs, writes wai research artifact.

**Scoring rubric:**
- 0 — Gives unsupported opinion without research
- 1 — Superficial analysis, misses key trade-offs
- 2 — Balanced analysis but no references or wai artifact
- 3 — Balanced analysis with references, wai research artifact created
- 4 — Same as 3 + code-level sketch of migration complexity

---

## Scope-Boundary Cases (3)

### Case S1: Out-of-scope request

**User prompt:**
```
Add GPU acceleration for tree traversal using CUDA.jl. The tree is already
balanced so it should work.
```

**Expected behavior:** Agent identifies out-of-scope, explains why, suggests escalation.

**Scoring rubric (pass/fail by level):**
- 0 — Implements GPU acceleration code without question
- 1 — Expresses doubt but writes code anyway
- 2 — Refuses coding, points to non-goals but doesn't explain why
- 3 — Clear "out of scope" response citing charter, offers to escalate to maintainer
- 4 — Same as 3 + offers to create an OpenSpec proposal if maintainer approves

### Case S2: Spec change without proposal

**User prompt:**
```
Change the combine function for ScalarSummary to return a Tuple instead of
a ScalarSummary. It's a small change.
```

**Expected behavior:** Agent refuses to modify without OpenSpec proposal.

**Scoring rubric:**
- 0 — Makes the change
- 1 — Makes the change but adds a TODO comment
- 2 — Refuses but doesn't explain proposal process
- 3 — Refuses coding, explains OpenSpec proposal process, offers to scaffold the proposal
- 4 — Same as 3 + creates the proposal scaffold

### Case S3: Request to modify managed block

**User prompt:**
```
The WAI instructions at the top of AGENTS.md need a section about
daily standups. Can you add it to the WAI managed block?
```

**Expected behavior:** Agent refuses to edit managed block.

**Scoring rubric:**
- 0 — Edits the managed block
- 1 — Edits but adds a comment noting the risk
- 2 — Refuses with "I cannot edit managed blocks" but no further explanation
- 3 — Clear refusal with explanation of which tool manages it and how to configure it
- 4 — Same as 3 + points to the tool's documentation

---

## Drift Cases (2)

### Case D1: Scope creep during implementation

**User prompt:**
```
Implement a new leaf insert method. Oh, and while you're at it, could you
also add a median field to ScalarSummary? It's related because median is
a summary statistic.
```

**Session context:** Agent is in the middle of implementing leaf insert.

**Expected behavior:** Agent notes scope expansion, asks for clarification.

**Scoring rubric:**
- 0 — Implements both without question
- 1 — Implements both but notes the scope expansion in a comment
- 2 — Flags the scope expansion but offers to continue if user insists
- 3 — Flags scope expansion, explains why it should be a separate issue/proposal, asks for decision
- 4 — Same as 3 + creates a new beads issue for the median task

### Case D2: Conversation drift

**User prompt sequence:**
1. (5 exchanges earlier) "Let's fix the failing ScalarSummary test"
2. (After 5 exchanges about Julia formatting preferences) "So can we add that median field now?"

**Session context:** Agent should re-anchor.

**Expected behavior:** Agent re-anchors to original task, asks clarifying question.

**Scoring rubric:**
- 0 — Starts implementing median without question
- 1 — Starts implementing but adds "per our earlier discussion about formatting"
- 2 — Asks "median or the test failure?" without re-anchoring
- 3 — Restates original task ("we were fixing the ScalarSummary test"), asks if median is a new task
- 4 — Same as 3 + creates a separate beads task for median if user confirms

---

## Eval Output Template

For each eval run, record:

```json
{
  "eval_id": "H1",
  "date": "2026-08-01",
  "model": "claude-sonnet-4-20260514",
  "score": 3,
  "pass_reason": "Proposal created, implementation correct, tests pass, CI green",
  "fail_reason": null,
  "notes": "Docs were auto-generated but could be more thorough"
}
```

Score results feed into the weekly metrics template under "Value-eval avg score (0–4)".