# wolong — standing session instructions

**wolong**: LFE/OTP supervision tree and typed API for the pandaPI HTN
planning toolchain (HDDL), external processes managed via erlexec. The
planning organ's process boundary in the composite-cognition architecture.
Sibling project: `chengdu` (builds/releases the pandaPI binaries wolong
consumes).

- Planning artifacts live under `docs/design-v0.1.0/…`, per the
  collaboration framework's `PROJECT-MANAGEMENT.md` (canonical layout;
  confirmed by operator 2026-08-05). Do not invent parallel structures.
- Load the `collaboration-framework` skill at session start; load the
  `erlang-guidelines` skill whenever writing or reviewing code (OTP design,
  supervision, typespecs, ltest/eunit). Code is LFE targeting rebar3.
- Read `docs/design-v0.1.0/project-plan.md` first. The API contract that
  must never erode: **validated-plan-or-unsolvable as an actual return
  type** — no unverified plan crosses the API, and `Status: Proven
  unsolvable` (engine exit 0!) is a success-shaped result, not an error.
- Design substrate: "Composite Cognition — Supervision-Tree Architecture"
  and "Planner Toolchain Selection" (project docs / operator's Dropbox
  LLMs folder), plus the PANDA Runbook (gate mechanics + exit-code tables,
  evidence-graded).
- Process middleware is erlexec (operator decision 2026-08-05, chosen for
  kill/timeout semantics over raw ports; erlport was a misremembering —
  it is a Python/Ruby bridge and is not used here).

## Workflow

- **Direct-to-main.** No PR ceremony; the quality gate is the ledger +
  CDC verification, not merge review (same operator override as the
  sibling `chengdu` project, applied from the first push — recorded at
  repo creation, slice01 `app-skeleton`).
- **Repo home**: `billosys` org, public, default branch `main` — stated
  explicitly because the one process defect of `chengdu` was a repo born
  in the wrong org.
- **Pins-not-floats**: dependency versions, OTP versions in CI, and
  GitHub Action majors are pinned exactly; version choices are surveyed
  live at the point they're pinned, not recalled from memory, and the
  rationale is recorded in the relevant slice's ledger.
