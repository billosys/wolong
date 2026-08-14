# Slice 02 (wolong arc01): exec-runner — closing report

> Written by CC. Per-row walk against [`ledger.md`](./ledger.md), opened
> with 9 rows on 2026-08-13. CDC verification belongs in
> `cdc-verification.md` after independent reproduction; this report does not
> create that artifact.

## Per-row walk

Rows opened: 9. Rows addressed: 9. Done: 9. Deferred: 0. No-op: 0.
Silent drops: 0.

- **R-1 — Slice01 F-1 OTP pin disposition.** Done. Implementation commit
  `25ff21af8f39b10d415d11d02dc12dd62e42c261` moved CI from OTP `28.1.1` to
  `28.5.0.4`; iteration 01 corrects the branch-head pin to `28.5.0.5`. Live
  survey on 2026-08-14 found Erlang's download index listing
  `OTP-28.5.0.5.README` dated `04-Aug-2026 09:59`, after `28.5.0.4`, and
  Erlang's OTP versions tree listing `maint-28` at `OTP 28.5.0.5`, with
  `OTP 28.5.0.4` one row below it. Initial local suite evidence:
  `rebar3 as test eunit` -> 19 tests, 0 failures. Fresh remote CI execution
  under that pin is recorded in R-8.
- **R-2 — Owned typed runner contract.** Done. `src/wolong-exec.lfe` exports
  `(run 3)` and returns only `#(ok Result)`, `#(timeout Result)`, or
  `#(error #(exec Reason Detail))`. `rebar3 compile` exits 0. The result maps
  carry `exit-status`, `stdout`, `stderr`, `duration-ms`,
  `output-limit-bytes`, observed byte counts, and truncation flags. Optional
  `cwd` and `env` were explicitly deferred until a later gate needs and tests
  them.
- **R-3 — Completed exit capture.** Done. Integration runner coverage now runs
  under Common Test. `rebar3 as test ct` exits 0 with
  `wolong_exec_SUITE: 10 tests passed`. `exit_zero_captures_stdout_stderr`
  asserts exit 0, stdout, and stderr. `nonzero_exit_is_completed_result`
  asserts exit 7 is `#(ok Result)`, with separated stdout/stderr.
- **R-4 — argv safety.** Done. The runner builds `(cons command args)` and
  calls `exec:run` with that list, so erlexec receives argv data rather than a
  concatenated shell string. CT case
  `argv_metacharacters_arrive_unchanged` passes an argument containing spaces,
  `$`, `&&`, `|`, and `;`; the fixture receives it unchanged.
- **R-5 — timeout, kill escalation, no-zombie evidence.** Done. The runner
  starts children with erlexec `monitor`, `kill_group`, `{group, 0}`, and
  `{kill_timeout, Sec}`. Timeout results include partial stdout/stderr,
  timeout flags, kill metadata, and duration. CT cases
  `simple_timeout_returns_partial_output` and
  `term_resistant_timeout_kills_process_and_recovers` cover timeout behavior.
  The TERM-resistant case writes a PID file, ignores TERM, times out, and then
  loops `kill -0 <pid>` until the process is absent before asserting recovery.
- **R-6 — bounded stdout/stderr.** Done. CT case
  `stdout_and_stderr_are_capped_independently` sets `output-limit-bytes` to 25
  and asserts captured stdout and stderr are each 25 bytes, both truncation
  flags are true, and observed byte counts exceed the cap. Current policy is
  capped in-memory capture; stream-to-file remains a later engine-scale design
  question.
- **R-7 — post-failure app recovery.** Done. CT case
  `bad_executable_is_typed_exec_error_and_app_recovers` asserts a missing
  executable returns `#(error #(exec ...))`, `wolong-sup` and `exec` remain
  registered, and a subsequent normal run succeeds. The TERM-resistant timeout
  case also asserts a normal run succeeds after timeout cleanup.
- **R-8 — falsifiability and CI.** Done. Local falsifiability remains recorded
  at implementation commit `25ff21af8f39b10d415d11d02dc12dd62e42c261`: tamper
  changed the nonzero-exit expectation from 7 to 8, and
  `rebar3 as test eunit` exited 1 with 19 tests, 1 failure; reverting the
  tamper produced 19 tests, 0 failures. Current workflow commit
  `a5a0416a2e3edb5b7d7b8154bb0b09b439549e4b` runs `rebar3 compile`,
  `rebar3 as test eunit`, `rebar3 as test ct`, `rebar3 xref`, and
  `rebar3 dialyzer` on `ubuntu-22.04` and `macos-15` at OTP `28.5.0.5`.
  GitHub Actions run `31820063427` succeeded for both matrix jobs:
  `build (ubuntu-22.04)` job `94830903203` and `build (macos-15)` job
  `94830903186` (`https://github.com/billosys/wolong/actions/runs/31820063427`).
  Commit `a5a0416a2e3edb5b7d7b8154bb0b09b439549e4b` temporarily works around
  the OTP 28.5.0.5 + rebar3_lfe/ltest/EUnit duplicate-export interaction by
  disabling EUnit auto-discovery suffixes so ltest owns exports.
- **R-9 — scope fence.** Done. Scope grep over `src test` finds no
  `pandaPIparser`, `pandaPIgrounder`, `pandaPIengine`, `defun plan`,
  `defun verify`, `gen_statem`, or `wolong-binaries`. The diff adds only the
  generic runner, POSIX fixtures, runner tests, and the OTP pin update.

## Verification

Final local verification after the current CI/test-boundary corrections:

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 9 tests, 0 failures, exit 0
rebar3 as test ct     # wolong_exec_SUITE: 10 tests passed, exit 0
rebar3 xref           # exit 0
rebar3 dialyzer       # exit 0
```

Tamper cycle:

```bash
# Tamper: expected nonzero fixture exit 7 changed to 8.
rebar3 as test eunit  # 19 tests, 1 failures, exit 1

# Revert tamper.
rebar3 as test eunit  # 19 tests, 0 failures, exit 0
```

Current CI evidence:

- Run: `31820063427`
  (`https://github.com/billosys/wolong/actions/runs/31820063427`)
- Head SHA: `a5a0416a2e3edb5b7d7b8154bb0b09b439549e4b`
- Matrix jobs: `build (ubuntu-22.04)` job `94830903203`, success; `build
  (macos-15)` job `94830903186`, success.
- Steps passed on both jobs: checkout, setup-beam, compile, EUnit, Common Test,
  xref, dialyzer.

## Bubble-up to the arc

**1. Did slice02 deliver the slice breakdown line in `arc-plan.md`?** Yes. The
slice line called for `wolong_exec`: a generic erlexec wrapper,
`(run cmd args opts)`, typed ok/timeout/error results, kill escalation,
no-zombie guarantee, and fixture tests with no pandaPI yet. The implementation
delivers that generic runner as `wolong-exec:run/3`, with result maps richer
than the arc shorthand, and current CI proves the unit, integration, xref, and
dialyzer gates on Ubuntu and macOS.

**2. What did implementation reveal that the arc plan did not anticipate?**
Three findings matter for later gates. First, erlexec can report a missing
bare command name as a completed process with stderr rather than a start error,
so `wolong-exec` now preflights command names with `os:find_executable/1` and
path-like commands with `filelib:is_file/1`. Second, timeout cleanup should be
process-group oriented from the start: `kill_group` plus `{group, 0}` is now
part of the generic runner options so later pandaPI gates do not inherit
child-process cleanup ambiguity. Third, OTP 28.5.0.5 exposed a
rebar3_lfe/ltest/EUnit duplicate-export interaction. The temporary workaround
disables EUnit auto-discovery suffixes in `erl_opts` so ltest `deftest` owns
exports; longer-term re-entry is to remove this workaround when
rebar3_lfe/ltest/OTP behavior no longer collides or when a first-party test
layout supersedes it.

**3. Scope-as-specified vs. scope-as-delivered.** Delivered: generic runner,
typed results, separated stdout/stderr, nonzero completed exits, argv safety,
timeout results, TERM-resistant cleanup evidence, output caps, post-failure
recovery, corrected OTP 28 branch-head CI pin disposition, local gates, tamper
proof, and remote CI green-run evidence. Deferred: optional `cwd`/`env` runner
options and stream-to-file output capture. Stayed out: pandaPI invocation,
binary locator, top-level `wolong:validate`/`plan`/`verify`, gate pipeline,
`gen_statem`, and publishing.
