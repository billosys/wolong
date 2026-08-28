# Slice 02 (wolong arc03): stdio-runner

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at slice
> start, 2026-08-26. Closer: CC. Verifier: CDC. Evidence names commits and
> command results; CDC upgrades accepted `done` evidence from attested to
> reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| SR-1 | Existing `wolong-exec:run/3` behavior and result shapes remain compatible for no-stdin callers. | run existing exec CT cases and inspect any changed public/exported runner shape | serious | arc01/arc02 compatibility | done | Commit `a6b7847`; `rebar3 as test ct --suite test/wolong_exec_SUITE.lfe` passed 18 tests; full CT passed 70 tests. | `run/3` remains exported and no-stdin callers still use the same result shapes. |
| SR-2 | A stdin-capable runner API exists and is exported with an explicit payload argument. | inspect `src/wolong-exec.lfe` exports and call sites; CT calls the new API directly | serious | arc03 A2 | done | Commit `a6b7847`; `src/wolong-exec.lfe` exports `(run-stdin 4)`; CT calls `wolong-exec:run-stdin/4` directly. | LFE same-name arity grouping made `run/4` a poor fit; explicit API is `run-stdin/4`. |
| SR-3 | Stdin validation accepts binary payloads and rejects unsupported shapes with typed `exec` errors. | CT invalid-stdin cases assert matchable error tuples | serious | arc03 A5 | done | Commit `a6b7847`; `invalid_stdin_shape_is_typed_exec_error` asserts `#(error #(exec invalid-stdin ...))` and recovery. | Binary stdin is the only accepted payload form. |
| SR-4 | The runner sends stdin bytes and then EOF so a child reading until EOF completes. | CT fixture blocks until EOF and then emits deterministic stdout/stderr | serious | release process contract | done | Commit `a6b7847`; `stdin_bytes_and_eof_are_sent` and `empty_stdin_sends_eof`; tamper removed EOF and CT failed nonzero. | Empty binary sends EOF and completes. |
| SR-5 | argv-list execution remains shell-free when stdin is used. | CT metacharacter/stdin fixture proves args are not shell-expanded; inspect erlexec call shape | serious | arc01 invariant | done | Commit `a6b7847`; `stdin_argv_metacharacters_arrive_unchanged`; `run-valid` still calls `exec:run argv options` with `(cons command args)`. | Fixture scripts run through `/bin/sh` as argv-list executable/args, not command strings. |
| SR-6 | stdout and stderr are still captured separately for stdin runs. | CT fixture writes both streams; assert independent stdout/stderr payloads | serious | managed-process safety | done | Commit `a6b7847`; stdin CT cases assert distinct stdout and stderr payloads; local Chengdu smoke returned stdout artifact and stderr `PANDAPI_STATUS`. | Later status parsing can continue reading stderr. |
| SR-7 | stdout and stderr output caps still apply independently for stdin runs. | CT fixture floods both streams after stdin; assert truncation metadata and bounded payload sizes | serious | arc03 OQ4/A6 | done | Commit `a6b7847`; `stdout_and_stderr_are_capped_independently_for_stdin` passes with 25-byte caps and truncation flags. | Existing cap semantics are reused. |
| SR-8 | A nonzero child exit after stdin is returned as a completed process result, not a generic runner failure. | CT fixture consumes stdin and exits nonzero; assert exit status and captured streams | correctness | gate classification | done | Commit `a6b7847`; `nonzero_exit_after_stdin_is_completed_result` asserts exit `7` with captured streams. | Gate mapping remains a later layer. |
| SR-9 | Missing executable, invalid command, invalid args, and invalid opts behavior is unchanged by stdin support. | existing CT plus at least one stdin-adjacent negative case | correctness | arc01 compatibility | done | Commit `a6b7847`; existing no-stdin compatibility cases plus `stdin_runner_preserves_validation_errors`. | Stdin support does not widen command/args/options validation. |
| SR-10 | Timeout cleanup kills the process group for stdin-using children and returns a typed timeout. | CT hanging/TERM-resistant fixture with stdin; verify no surviving OS process and typed timeout result | serious | arc03 A6/W2 | done | Commit `a6b7847`; `stdin_term_resistant_timeout_kills_process_and_recovers` asserts timeout, no surviving PID, captured streams, and recovery. | Uses the existing kill-group cleanup path. |
| SR-11 | Runner remains usable after stdin send failure or timeout. | CT failure/timeout followed by successful stdin run in the same suite | correctness | supervision recovery | done | Commit `a6b7847`; invalid-stdin and timeout cases each perform a following successful stdin run. | Send failures are converted by `safe-exec-send/2` to `stdin-send-failed`; no direct fixture triggered that path. |
| SR-12 | No `wolong-pipeline`, public `wolong:plan/2,3`, or `wolong:validate/2` behavior changes land in this slice. | inspect diff; run existing plan/dispatch/pipeline CT suites | serious | slice scope | done | Commit `a6b7847`; changed only `src/wolong-exec.lfe`, `test/wolong_exec_SUITE.lfe`, and exec-runner fixtures; full CT passed 70 tests. | Pipeline stdio rewiring remains Slice03. |
| SR-13 | Parser `- -` caveat is encoded for later work: this slice does not assume both parser HDDL inputs can come from stdin. | inspect docs/prompt/closing report; no tests or helpers model parser both-stdin as supported | correctness | Chengdu re-entry caveat | done | Commit `a6b7847` plus `closing-report.md`; no fixture models parser `- -`; Arc03 plan notes the caveat. | Slice03 must preserve exactly-one parser stdin input. |
| SR-14 | Optional local real-Chengdu smoke evidence is recorded if sibling binaries are available, without making CI depend on `../chengdu`. | run a narrow stdin probe through the new runner against `../chengdu/bin/pandapi-grounder` or `pandapi-engine`, or record why skipped | correctness | arc03 A3/A4 lead-in | done | Local smoke ran `wolong-exec:run-stdin/4` against `../chengdu/bin/pandapi-grounder`; result exit `0`, stdout 446 bytes, stderr 208 bytes with `PANDAPI_STATUS status=ok`. | Local-only evidence; remote CI remains fixture-backed. |
| SR-15 | Local gates and formatter check pass. | `rebar3 compile`; `rebar3 as test eunit`; `rebar3 as test ct`; `rebar3 xref`; `rebar3 dialyzer`; `rebar3 lfe format --check` | correctness | repo workflow | done | 2026-08-26: compile pass; eunit pass 9/0; CT pass 70/0; xref pass; dialyzer pass; formatter pass all 13 files. | No exceptions. |
| SR-16 | A meaningful tamper cycle proves a new stdin invariant. | break EOF, stream separation, caps, shell-free argv, or timeout cleanup; show CT fail; revert and show pass | serious | ledger discipline | done | Temporarily skipped EOF after stdin; `rebar3 compile && rebar3 as test ct --suite test/wolong_exec_SUITE.lfe` failed 7 tests/11 passed; reverted; same command passed 18/0. | Tamper was not committed. |
| SR-17 | Remote CI evidence is recorded honestly. | link green Ubuntu/macOS run, or mark deferred if not pushed/available | correctness | release confidence | done | GitHub Actions build `33027645336` for `a6b7847` passed on `ubuntu-22.04` and `macos-15`: https://github.com/billosys/wolong/actions/runs/33027645336 | Remote CI is fixture-backed and does not use sibling Chengdu. |
| SR-18 | Closing report walks every ledger row and bubbles up runner API, Chengdu caveat, remaining pipeline work, and project roadmap impact. | inspect `closing-report.md` for SR-1 through SR-18 and Bubble-up sections | correctness | project management | done | `closing-report.md`; Arc03 plan updated. | CDC writes `cdc-verification.md` later. |

## What Worked

- Reusing the existing runner receive loops kept stdin support from forking
  timeout, output cap, and stream-capture semantics.
- The EOF tamper was a high-signal proof: EOF-sensitive fixtures immediately
  timed out when `exec:send(Pid, eof)` was removed.
- The local Chengdu smoke proved the new Wolong API can drive a real current
  Chengdu stdin component without making CI depend on `../chengdu`.

## Closure

Proposed done by CC on 2026-08-26.
Rows: 18. Done: 18. Deferred: 0. No-op: 0.
