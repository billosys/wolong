# wolong arc01 — exec-substrate — arc plan

> Plan-of-record for arc01, per `PROJECT-MANAGEMENT.md` (v2.1). Parent:
> [`../project-plan.md`](../project-plan.md).

## 1. Capability statement

Roadmap line: *wolong can run one supervised pandaPI process via erlexec and
return a typed result — timeouts, kill escalation, exit-code mapping proven.*

Expanded: this arc builds the substrate every later gate stands on — the OTP
application skeleton in LFE, erlexec integrated and supervised, and a single
generic "run this external tool, bounded in time, and give me a typed
answer" capability, proven against the real pandaPIparser in its simplest
role (validation, runbook §5). At arc close, `(wolong:validate dom prob)`
works end to end: it locates a configured parser binary, runs it under
erlexec with a timeout, maps exit codes 0/2/255 to
`#(ok ...)`/`#(error #(missing-file ...))`/`#(error #(invalid-hddl ...))`,
kills it cleanly if it hangs, and never leaks an OS process. The risky
unknowns this arc exists to burn down are erlexec's ergonomics from LFE and
the fidelity of exit-code/stdout capture — not planning semantics, which
wait for arc02 on purpose.

## 2. Slice breakdown

| Slice | Slug | Scope (one line) | Load-bearing for |
|-------|------|------------------|------------------|
| slice01 | `app-skeleton` | rebar3 LFE OTP app `wolong`: deps (erlexec, ltest), `wolong_app`/`wolong_sup`, config schema stub (binary paths, timeouts), compiles, starts, stops clean; CI stub running the test suite. | everything |
| slice02 | `exec-runner` | `wolong_exec`: the generic erlexec wrapper — `(run cmd args opts)` → `#(ok stdout exit-status)` / `#(timeout partial-output)` / `#(error reason)`, with kill escalation and no-zombie guarantee; tested against fixture scripts (sleep, exit N, stdout floods) — no pandaPI yet. | slice03, all of arc02 |
| slice03 | `parser-validate` | `wolong_binaries` (config-driven locator with startup existence/exec check) + first real integration: `(wolong:validate ...)` via pandaPIparser, exit-code mapping per runbook §5 table, tested against the runbook's minimal pair and its broken variants as fixtures. | arc02 |

Sizing judgment: three slices, each one context with headroom. slice02 is
the load-bearing risk slice (erlexec semantics under deliberate abuse) and
is isolated from pandaPI specifics precisely so its five-iteration budget is
spent on process mechanics, not HDDL. slice03 is small by design — it is the
composition proof, not new machinery.

## 3. Dependencies

**Consumes:** erlexec (hex); the runbook's §5 exit-code table (*reproduced*
grades) and minimal-pair fixtures; locally-built pandaPI binaries on the dev
machine (the operator's field-built macOS set, and/or sandbox-built Linux
set) via config — chengdu releases are NOT a dependency of this arc
(deliberate: arc03 owns provisioning; arc01 must not block on chengdu).

**Leaves for arc02:** the `wolong_exec` contract (typed run results) that
each gate will call; `wolong_binaries` extended trivially to the other two
executables; the fixture corpus layout; and a design sketch to be planned
properly in arc02 — the dispatch as a `gen_statem` whose states are the
gates (parse → ground → solve → convert → verify), one scratch dir per
dispatch, workers under a `simple_one_for_one` dispatch supervisor, crash =
typed gate error. Recorded here so arc01's bubble-ups can correct it before
arc02 commits to it.

## 4. Open questions (named, owned by slices)

- **OQ1 (slice01):** erlexec from LFE — erlexec's API is Erlang-friendly but
  its option lists are idiosyncratic; verify early that LFE call ergonomics
  don't warrant a thin macro layer. Decide by end of slice01.
- **OQ2 (slice02):** stdout capture strategy for large outputs — engine
  output on hard instances can be large; stream-to-file vs. accumulate-in-
  memory, and where the truncation policy lives. Default: accumulate with a
  configurable cap for arc01; revisit at arc02 when the engine gate is real.
- **OQ3 (slice03):** binary discovery precedence — app env only, or app env
  → `WOLONG_PANDA_PATH` env var → PATH probe. Default: app env only for
  0.1.0 (explicit beats convenient); record any operator pushback.

## 5. Arc ledger

| Row | Criterion | Target strength |
|-----|-----------|-----------------|
| A1 | `rebar3 lfe compile` + app start/stop clean on a machine with configured binaries; test suite green. | reproduced |
| A2 | `wolong_exec` demonstrably kills a deliberately-hanging process at its timeout, returns a typed timeout, and leaves no OS process behind (checked via OS process table in the test). | reproduced |
| A3 | `(wolong:validate ...)` returns the correct distinct typed result for: valid pair, missing file, syntax error, undeclared predicate — the four runbook §5 rows. | reproduced via test suite |
| A4 | No dispatch path returns an untyped or stringly error; every error term names its gate/reason (attested by review of the public API surface). | attested |

## 6. Version history

- **v1.0 — 2026-08-05.** Initial slice breakdown. Sources: project plan v1.0;
  erlexec decision from plan review; runbook §5 exit-code table as the
  slice03 contract. No slice bubble-ups yet.
