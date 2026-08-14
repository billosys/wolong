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
  supervision, typespecs, ltest/eunit, Common Test). Code is LFE targeting
  rebar3.
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
- **Erlang dependency constraints:** Hex deps and project plugins may use
  normal Erlang-compatible constraints such as `~> 2.2`; `rebar.lock` is the
  reproducibility artifact for the resolved package set. Do not import
  chengdu's C/C++ micro-pin rule into wolong. CI OTP/rebar3 versions and
  GitHub Action majors remain explicit toolchain pins; when a slice relies on
  a particular runtime/tool version, survey live and record the rationale in
  that slice's ledger.
- **Test boundary:** use ltest/EUnit for unit tests; use Common Test for
  integration/system behavior such as application lifecycle, supervision
  trees, erlexec-managed OS processes, timeouts, kill cleanup, and fixture
  flows. Canonical LFE CT examples live in
  `/Users/oubiwann/lab/lfe/lfe/test/*SUITE.lfe`. Keep wolong test artifacts in
  the existing project test tree; do not create parallel test directories.
- **Commit footer convention (operator override, 2026-08-07):** every future
  assistant-authored commit message includes these trailers:
  `Co-authored-by: Codex <noreply@openai.com>` and
  `Co-authored-by: Billo AI <ai-engineering@billo.systems>`.
