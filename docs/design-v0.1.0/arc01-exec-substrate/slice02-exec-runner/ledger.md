# Slice 02 (wolong arc01): exec-runner

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at
> slice start, 2026-08-13. Closer: CC. Verifier: CDC. Evidence must name the
> commit and include command output or direct artifact pointers; CDC upgrades
> accepted `done` evidence from attested to reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| R-1 | Slice01 CDC finding F-1 is dispositioned before slice02 relies on runtime/CI pins: either CI is moved to the current OTP 28 branch head after live survey, or an operator-approved rationale for staying on `28.1.1` is recorded. | read `.github/workflows/build.yml`; read the ledger evidence or docs note containing the live survey/rationale; run `rebar3 as test eunit` under the selected pin in CI | correctness | slice01 `cdc-verification.md` F-1 | open | | This is a gate on assumptions, not a demand to bump. |
| R-2 | `src/wolong-exec.lfe` defines the owned runner contract `(run command args opts)` and all public return paths use typed tuple/map results: `#(ok Result)`, `#(timeout Result)`, or `#(error #(exec Reason Detail))`; no public return path reports a bare stringly error. | `rebar3 compile`; inspect `src/wolong-exec.lfe`; `rg -n "defun run|#\\(timeout|#\\(error #\\(exec|exit-status|stdout|stderr" src test` | serious | slice-doc §§1,3,5 | open | | Nonzero process exit is a completed run, not an exec error. |
| R-3 | Completed process exits are captured faithfully: exit 0 and a nonzero exit both return `#(ok Result)` with exact `exit-status`, separated stdout, and separated stderr. | `rebar3 as test eunit`; read tests and fixtures for exit 0, exit N, stdout, stderr | serious | arc-plan slice02 line | open | | Use fixture scripts, not pandaPI binaries. |
| R-4 | Command and args are executed as argv data, not a concatenated shell string; an argument containing spaces and shell metacharacters reaches the fixture unchanged. | `rebar3 as test eunit`; inspect runner call site for list/argv erlexec invocation; inspect argv fixture assertion | correctness | slice-doc §5 shell-interpolation fence | open | | This protects every later gate from quoting surprises. |
| R-5 | Timeout handling kills a deliberately hanging process, including a TERM-resistant fixture via kill escalation, returns `#(timeout Result)` with timeout/kill metadata and partial stdout/stderr, and leaves no OS process behind. | `rebar3 as test eunit`; inspect timeout fixture PID-file/process-table check; repeat the no-zombie check manually if needed with `kill -0 <pid>` or equivalent | serious | arc ledger A2 | open | | Test must assert process absence, not rely on human observation. |
| R-6 | Captured output is bounded by `output-limit-bytes`; stdout and stderr caps are applied independently, the returned result exposes truncation metadata, and flood fixtures cannot grow memory unbounded in normal tests. | `rebar3 as test eunit`; inspect output-flood tests and result shape | correctness | arc-plan OQ2 | open | | Default cap may be conservative; the policy must be explicit. |
| R-7 | Runner failures do not destabilize the OTP app: after a bad executable and after a timeout, `exec`/`wolong-sup` remain alive and a subsequent normal run succeeds. | `rebar3 as test eunit`; inspect tests for post-failure/post-timeout recovery assertions | serious | project ledger W4 substrate | open | | This is the slice02 version of dispatch isolation. |
| R-8 | The runner test suite is falsifiable and included in CI on Ubuntu and macOS; a tamper that breaks a meaningful runner assertion fails `rebar3 as test eunit` with nonzero exit, then passes after revert. | local tamper cycle; CI run page; read `.github/workflows/build.yml`; optionally run `actionlint .github/workflows/build.yml` | correctness | ledger discipline; slice01 K-6/K-7 | open | | Use `rebar3 as test eunit`, not `rebar3 lfe ltest`, as the gate. |
| R-9 | Scope fence holds: slice02 adds no pandaPI invocation, no new top-level `wolong:validate`/`plan`/`verify` public API, no binary locator, and no gate pipeline or `gen_statem` dispatch. | inspect changed source/test files; `rg -n "pandaPIparser|pandaPIgrounder|pandaPIengine|defmodule wolong\\b|defun plan|defun verify|gen_statem|wolong-binaries" src test` plus diff review | correctness | slice-doc §4 | open | | Planning-doc mentions of pandaPI and the existing `wolong-config:validate/0` are not violations. |

## What Worked

_(At slice close. Patterns that made the slice close cleanly.)_

## Closure

Closed at commit <SHA> on <date>. Verified by: <name/session>.
Rows: 9. Done: <n>. Deferred: <n>. No-op: <n>.
