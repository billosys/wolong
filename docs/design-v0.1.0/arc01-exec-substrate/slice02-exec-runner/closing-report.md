# Slice 02 (wolong arc01): exec-runner — closing report

> Written by CC. Per-row walk against [`ledger.md`](./ledger.md), opened
> with 9 rows on 2026-08-13. CDC verification belongs in
> `cdc-verification.md` after independent reproduction; this report does not
> create that artifact.

## Per-row walk

Rows opened: 9. Rows addressed: 9. Done: 8. Deferred: 1. No-op: 0.
Silent drops: 0.

- **R-1 — Slice01 F-1 OTP pin disposition.** Done. Implementation commit
  `25ff21af8f39b10d415d11d02dc12dd62e42c261` moved CI from OTP `28.1.1` to
  `28.5.0.4`; iteration 01 corrects the branch-head pin to `28.5.0.5`. Live
  survey on 2026-08-14 found Erlang's download index listing
  `OTP-28.5.0.5.README` dated `04-Aug-2026 09:59`, after `28.5.0.4`, and
  Erlang's OTP versions tree listing `maint-28` at `OTP 28.5.0.5`, with
  `OTP 28.5.0.4` one row below it. Local suite evidence:
  `rebar3 as test eunit` -> 19 tests, 0 failures. Fresh remote CI execution
  under that pin is routed to R-8.
- **R-2 — Owned typed runner contract.** Done. `src/wolong-exec.lfe` exports
  `(run 3)` and returns only `#(ok Result)`, `#(timeout Result)`, or
  `#(error #(exec Reason Detail))`. `rebar3 compile` exits 0. The result maps
  carry `exit-status`, `stdout`, `stderr`, `duration-ms`,
  `output-limit-bytes`, observed byte counts, and truncation flags. Optional
  `cwd` and `env` were explicitly deferred until a later gate needs and tests
  them.
- **R-3 — Completed exit capture.** Done. `rebar3 as test eunit` exits 0 with
  19 tests, 0 failures. `exit-zero-captures-stdout-stderr` asserts exit 0,
  stdout, and stderr. `nonzero-exit-is-completed-result` asserts exit 7 is
  `#(ok Result)`, with separated stdout/stderr.
- **R-4 — argv safety.** Done. The runner builds `(cons command args)` and
  calls `exec:run` with that list, so erlexec receives argv data rather than a
  concatenated shell string. `argv-metacharacters-arrive-unchanged` passes an
  argument containing spaces, `$`, `&&`, `|`, and `;`; the fixture receives it
  unchanged.
- **R-5 — timeout, kill escalation, no-zombie evidence.** Done. The runner
  starts children with erlexec `monitor`, `kill_group`, `{group, 0}`, and
  `{kill_timeout, Sec}`. Timeout results include partial stdout/stderr,
  timeout flags, kill metadata, and duration. `term-resistant-timeout-kills-
  process-and-recovers` writes a PID file, ignores TERM, times out, and then
  loops `kill -0 <pid>` until the process is absent before asserting recovery.
- **R-6 — bounded stdout/stderr.** Done. `stdout-and-stderr-are-capped-
  independently` sets `output-limit-bytes` to 25 and asserts captured stdout
  and stderr are each 25 bytes, both truncation flags are true, and observed
  byte counts exceed the cap. Current policy is capped in-memory capture;
  stream-to-file remains a later engine-scale design question.
- **R-7 — post-failure app recovery.** Done. `bad-executable-is-typed-exec-
  error-and-app-recovers` asserts a missing executable returns
  `#(error #(exec ...))`, `wolong-sup` and `exec` remain registered, and a
  subsequent normal run succeeds. The TERM-resistant timeout test also asserts
  a normal run succeeds after timeout cleanup.
- **R-8 — falsifiability and CI.** Deferred. Local falsifiability is done:
  tamper changed the nonzero-exit expectation from 7 to 8, and
  `rebar3 as test eunit` exited 1 with 19 tests, 1 failure; reverting the
  tamper produced 19 tests, 0 failures. The workflow includes the suite on
  `ubuntu-22.04` and `macos-15` at OTP `28.5.0.5`. Remote CI green evidence
  for the corrected pin is pending. Re-entry: push the correction commit to
  `main`, wait for Actions, and record the green run URL for both matrix legs.
- **R-9 — scope fence.** Done. Scope grep over `src test` finds no
  `pandaPIparser`, `pandaPIgrounder`, `pandaPIengine`, `defun plan`,
  `defun verify`, `gen_statem`, or `wolong-binaries`. The diff adds only the
  generic runner, POSIX fixtures, runner tests, and the OTP pin update.

## Verification

Final local verification after the implementation commit:

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 19 tests, 0 failures, exit 0
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

CI is not claimed; see R-8.

## Bubble-up to the arc

**1. Did slice02 deliver the slice breakdown line in `arc-plan.md`?** Yes,
except for the remote CI evidence explicitly deferred in R-8. The slice line
called for `wolong_exec`: a generic erlexec wrapper, `(run cmd args opts)`,
typed ok/timeout/error results, kill escalation, no-zombie guarantee, and
fixture tests with no pandaPI yet. The implementation delivers that generic
runner as `wolong-exec:run/3`, with result maps richer than the arc shorthand.

**2. What did implementation reveal that the arc plan did not anticipate?**
Two process-substrate details matter for later gates. First, erlexec can report
a missing bare command name as a completed process with stderr rather than a
start error, so `wolong-exec` now preflights command names with
`os:find_executable/1` and path-like commands with `filelib:is_file/1`.
Second, timeout cleanup should be process-group oriented from the start:
`kill_group` plus `{group, 0}` is now part of the generic runner options so
later pandaPI gates do not inherit child-process cleanup ambiguity.

**3. Scope-as-specified vs. scope-as-delivered.** Delivered: generic runner,
typed results, separated stdout/stderr, nonzero completed exits, argv safety,
timeout results, TERM-resistant cleanup evidence, output caps, post-failure
recovery, corrected OTP 28 branch-head CI pin disposition, local gates, and
tamper proof.
Deferred: optional `cwd`/`env` runner options, stream-to-file output capture,
and remote CI green-run evidence. Stayed out: pandaPI invocation, binary
locator, top-level `wolong:validate`/`plan`/`verify`, gate pipeline,
`gen_statem`, and publishing.
