# wolong arc01 — exec-substrate — arc plan

> Plan-of-record for arc01, per `PROJECT-MANAGEMENT.md` (v2.1). Parent:
> [`../project-plan.md`](../project-plan.md).

## 1. Capability statement

Roadmap line: *wolong can run one supervised pandaPI process via erlexec and
return a typed result — timeouts, kill escalation, exit-code mapping proven.*

Expanded: this arc builds the substrate every later gate stands on — the OTP
application skeleton in LFE, erlexec integrated and supervised, and a single
generic "run this external tool, bounded in time, and give me a typed
answer" capability, proven against the current pre-release `pandapi-parser`
binary from the sibling Chengdu checkout in its simplest role: parser
validation. At arc close, `(wolong:validate dom prob)` works end to end: it
locates a configured parser binary, runs it under erlexec with a timeout, maps
the current Chengdu parser contract into
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
| slice03 | `parser-validate` | `wolong_binaries` (config-driven locator with startup existence/exec check) + first real integration: `(wolong:validate ...)` via current pre-release `pandapi-parser` from `../chengdu/bin/`, parser-contract mapping surveyed at slice start, tested against the minimal pair and broken variants as fixtures. | arc02 |

Sizing judgment: three slices, each one context with headroom. slice02 is
the load-bearing risk slice (erlexec semantics under deliberate abuse) and
is isolated from pandaPI specifics precisely so its five-iteration budget is
spent on process mechanics, not HDDL. slice03 is small by design — it is the
composition proof, not new machinery.

## 3. Dependencies

**Consumes:** erlexec (hex); the parser contract and minimal-pair fixtures
from the active Chengdu pre-release line; locally-built pandaPI binaries on
the dev machine via explicit config. Until Chengdu 0.3.0 is cut, the intended
developer integration path is the sibling checkout's `../chengdu/bin/`
pre-release binaries: `pandapi-parser`, `pandapi-grounder`, and
`pandapi-engine`. Chengdu release artifacts are NOT a dependency of this arc
(deliberate: arc03 owns provisioning; arc01 must not block on release
publication).

**Leaves for arc02:** the `wolong_exec` contract (typed run results) that
each gate will call; `wolong_binaries` extended trivially to the other two
executables; the fixture corpus layout; and a design sketch to be planned
properly in arc02 — the dispatch as a `gen_statem` whose states are the
gates (parse → ground → solve → convert → verify), one scratch dir per
dispatch, workers under a `simple_one_for_one` dispatch supervisor, crash =
typed gate error. Recorded here so arc01's bubble-ups can correct it before
arc02 commits to it.

## 4. Open questions (named, owned by slices)

- **OQ1 (slice01): RESOLVED — direct calls, no wrapper.** erlexec from LFE —
  erlexec's API is Erlang-friendly but its option lists are idiosyncratic;
  verify early that LFE call ergonomics don't warrant a thin macro layer.
  Decide by end of slice01. *(Was: open. Resolved 2026-08-06 by slice01 —
  see Version History.)*
- **OQ2 (slice02): RESOLVED — bounded in-memory capture for arc01.** stdout
  capture strategy for large outputs — engine output on hard instances can be
  large; stream-to-file vs. accumulate-in-memory, and where the truncation
  policy lives. Slice02 implements independently capped stdout/stderr
  accumulation with truncation metadata via `output-limit-bytes`; stream-to-
  file remains deferred to arc02 when the engine gate is real. *(Was: open.
  Resolved 2026-08-14 by slice02 — see Version History.)*
- **OQ3 (slice03):** binary discovery precedence — app env only, or app env
  → `WOLONG_PANDA_PATH` env var → PATH probe. Default: app env only for
  0.1.0 (explicit beats convenient); record any operator pushback.

## 5. Arc ledger

| Row | Criterion | Target strength |
|-----|-----------|-----------------|
| A1 | `rebar3 lfe compile` + app start/stop clean on a machine with configured binaries; test suite green. | reproduced |
| A2 | `wolong_exec` demonstrably kills a deliberately-hanging process at its timeout, returns a typed timeout, and leaves no OS process behind (checked via OS process table in the test). | reproduced |
| A3 | `(wolong:validate ...)` returns the correct distinct typed result for: valid pair, missing file, syntax error, undeclared predicate or broken reference — classified from the current `pandapi-parser` exit code and final `PANDAPI_STATUS`. | reproduced via test suite |
| A4 | No dispatch path returns an untyped or stringly error; every error term names its gate/reason (attested by review of the public API surface). | attested |

## 6. Version history

- **v1.3 — 2026-08-14 (operator correction before slice03 implementation).**
  The parser integration target is the current Chengdu pre-release binary
  name `pandapi-parser`, supplied from the sibling checkout at
  `../chengdu/bin/pandapi-parser` until Chengdu 0.3.0 release artifacts exist.
  Older references to the legacy raw `pandaPIparser` executable and its
  historical exit-code table are superseded for slice03; CC must survey and
  record the active `pandapi-parser` contract before implementing result
  mapping.
- **v1.2 — 2026-08-14 (surfaced by slice02).** OQ2 resolved:
  **bounded in-memory capture for arc01, stream-to-file deferred to arc02.**
  Evidence: `wolong-exec:run/3` carries an `output-limit-bytes` option,
  applies independent stdout/stderr caps, records observed byte counts and
  truncation flags, and CT case
  `stdout_and_stderr_are_capped_independently` verifies both streams. Slice02
  also surfaced two runner-boundary findings that do not change the arc slice
  breakdown: missing bare command names are normalized before erlexec can
  report them as shell-style completed processes, and timeout cleanup is
  process-group oriented (`kill_group`, `{group, 0}`) so slice03 can call the
  runner without inheriting child-process ambiguity. A tooling finding remains
  outside the arc capability: OTP 28.5.0.5 plus current `rebar3_lfe` exposed
  an ltest/EUnit duplicate-export collision, temporarily handled in
  `rebar.config` by disabling EUnit auto-discovery suffixes while preserving
  ltest `deftest` exports.
- **v1.1 — 2026-08-06 (surfaced by slice01).** OQ1 resolved: **direct
  `exec:run/2` calls, no thin wrapper macro.** Evidence: `wolong`'s erlexec
  probe (`test/unit-wolong-exec-probe-tests.lfe`) calls
  `(exec:run "true" '(sync stdout stderr))` and the equivalent
  nonexistent-command case directly from LFE — plain positional option
  lists of atoms and 2-tuple `#(ok ...)`/`#(error ...)` returns read and
  write cleanly as-is; no idiom in the option-list or return shape fought
  LFE's syntax. (Separately, slice01 found that `ltest`'s `is-match` macro
  does not perform genuine wildcard pattern matching — it degrades to
  structural equality against the literal `assertMatch` guard term, so a
  bare `_` in a guard compares as the atom `_`, not a wildcard. That is an
  `ltest` test-macro limitation, unrelated to erlexec ergonomics, and does
  not change the OQ1 verdict; slice01's tests use `element/1` equality
  checks instead.) The generic `wolong_exec` wrapper module planned for
  slice02 is still built — but as the domain contract (timeouts, kill
  escalation, typed results), not as an ergonomics workaround for erlexec's
  raw API.
- **v1.0 — 2026-08-05.** Initial slice breakdown. Sources: project plan v1.0;
  erlexec decision from plan review; runbook §5 exit-code table as the
  slice03 contract. No slice bubble-ups yet.
