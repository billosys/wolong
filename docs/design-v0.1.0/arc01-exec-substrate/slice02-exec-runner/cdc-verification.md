# Slice 02 (wolong arc01): exec-runner — CDC verification

> Independent verification of [`closing-report.md`](./closing-report.md)
> against [`ledger.md`](./ledger.md). Reviewer: CDC. Date: 2026-08-14.
> Verified commit: `59baeeb720d961546dc12ad2c59431d3f3087f61`.

## Verdict

Slice02 is CDC-closed.

Rows opened: 9. Rows addressed by closing report: 9. Done: 9. Deferred: 0.
No-op: 0. Silent drops found: 0.

## Reproduced Gates

Local verification on CDC machine:

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 9 tests, 0 failures, exit 0
rebar3 as test ct     # wolong_exec_SUITE: 10 tests passed, exit 0
rebar3 xref           # exit 0
rebar3 dialyzer       # exit 0
```

Remote verification:

- GitHub Actions run:
  `https://github.com/billosys/wolong/actions/runs/31821287954`
- Head SHA: `59baeeb720d961546dc12ad2c59431d3f3087f61`
- Result: success.
- Matrix jobs: `build (ubuntu-22.04)` job `94834868478`, success; `build
  (macos-15)` job `94834868452`, success.
- Both jobs passed compile, EUnit, Common Test, xref, and dialyzer under OTP
  `28.5.0.5` / rebar3 `3.27.0`.

## Row Verification

| ID | CDC status | Evidence |
|----|------------|----------|
| R-1 | reproduced | `.github/workflows/build.yml` pins OTP `28.5.0.5` and rebar3 `3.27.0`; remote run `31821287954` passed on Ubuntu and macOS. |
| R-2 | reproduced | `src/wolong-exec.lfe` exports `(run 3)` and returns typed `#(ok Result)`, `#(timeout Result)`, and `#(error #(exec Reason Detail))` shapes; `rebar3 compile` passed. |
| R-3 | reproduced | `test/wolong_exec_SUITE.lfe` covers exit 0 and exit 7 as completed `#(ok Result)` values with separated stdout/stderr; CT passed. |
| R-4 | reproduced | Runner builds argv with `(cons command args)` and calls `exec:run` with a list; CT case `argv_metacharacters_arrive_unchanged` passed. |
| R-5 | reproduced | Runner uses erlexec monitor mode with `kill_group`, `{group, 0}`, and `kill_timeout`; CT timeout cases passed, including TERM-resistant no-process-left check via `kill -0`. |
| R-6 | reproduced | CT case `stdout_and_stderr_are_capped_independently` passed; implementation applies independent stdout/stderr caps with truncation metadata. |
| R-7 | reproduced | CT cases prove missing-executable and timeout paths leave `wolong-sup`/`exec` usable and a subsequent normal run succeeds. |
| R-8 | reconciled | Local gates passed; remote run `31821287954` passed both CI matrix jobs. Historical tamper evidence remains attested from CC and is consistent with the current split: runner integration tests now live in CT, config units in EUnit. |
| R-9 | reproduced | Scope grep over `src test` found no pandaPI binary invocation, no `defun plan`, no `defun verify`, no `gen_statem`, and no `wolong-binaries`; only existing module declarations matched the broader `defmodule wolong` pattern. |

## Findings

No blocking findings.

Non-blocking notes:

- The ltest/EUnit duplicate-export workaround in `rebar.config` is a
  deliberate temporary compatibility measure: EUnit auto-discovery suffixes
  are set to project-impossible strings so ltest `deftest` owns exports. This
  belongs on the ltest/rebar3_lfe follow-up path, not inside slice03.
- The R-8 tamper transcript predates the CT migration and still names
  `rebar3 as test eunit` with 19 tests. It remains acceptable historical
  falsifiability evidence because the runner assertions were later moved to CT
  and the current CI now runs both EUnit and CT. Future tamper evidence should
  target the owning gate directly (`rebar3 as test ct` for runner behavior).

## Bubble-up Check

Slice02 delivered the `arc-plan.md` slice02 line: a generic erlexec runner
with typed ok/timeout/error results, argv execution, bounded output, timeout
cleanup, no-zombie evidence, and fixture-driven tests, without pandaPI
integration.

The slice surfaced one required arc-plan update: OQ2 is now resolved for
arc01. The arc plan has been updated to record bounded in-memory capture with
independent stdout/stderr caps and truncation metadata, with stream-to-file
deferred to arc02.

No slice breakdown change is required before slice03. The next slice can plan
against `wolong-exec:run/3`, while owning binary discovery and
`pandaPIparser` validation as already specified.
