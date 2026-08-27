# Slice 02 (wolong arc03): stdio-runner

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at slice
> start, 2026-08-26. Closer: CC. Verifier: CDC. Evidence names commits and
> command results; CDC upgrades accepted `done` evidence from attested to
> reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| SR-1 | Existing `wolong-exec:run/3` behavior and result shapes remain compatible for no-stdin callers. | run existing exec CT cases and inspect any changed public/exported runner shape | serious | arc01/arc02 compatibility | open |  | Compatibility wrapper should be explicit if `run/4` is added. |
| SR-2 | A stdin-capable runner API exists and is exported with an explicit payload argument. | inspect `src/wolong-exec.lfe` exports and call sites; CT calls the new API directly | serious | arc03 A2 | open |  | Preferred shape is `run/4`: command, args, stdin-bytes, opts. |
| SR-3 | Stdin validation accepts binary payloads and rejects unsupported shapes with typed `exec` errors. | CT invalid-stdin cases assert matchable error tuples | serious | arc03 A5 | open |  | Do not silently stringify arbitrary terms. |
| SR-4 | The runner sends stdin bytes and then EOF so a child reading until EOF completes. | CT fixture blocks until EOF and then emits deterministic stdout/stderr | serious | release process contract | open |  | Include an empty-binary case. |
| SR-5 | argv-list execution remains shell-free when stdin is used. | CT metacharacter/stdin fixture proves args are not shell-expanded; inspect erlexec call shape | serious | arc01 invariant | open |  | Fixture scripts are acceptable as executables; Wolong must not build command strings. |
| SR-6 | stdout and stderr are still captured separately for stdin runs. | CT fixture writes both streams; assert independent stdout/stderr payloads | serious | managed-process safety | open |  | Status parsing in later slices depends on this. |
| SR-7 | stdout and stderr output caps still apply independently for stdin runs. | CT fixture floods both streams after stdin; assert truncation metadata and bounded payload sizes | serious | arc03 OQ4/A6 | open |  | Preserve existing cap semantics unless a deliberate, ledgered refinement is made. |
| SR-8 | A nonzero child exit after stdin is returned as a completed process result, not a generic runner failure. | CT fixture consumes stdin and exits nonzero; assert exit status and captured streams | correctness | gate classification | open |  | Later gate mapping owns whether the exit is success-shaped or error-shaped. |
| SR-9 | Missing executable, invalid command, invalid args, and invalid opts behavior is unchanged by stdin support. | existing CT plus at least one stdin-adjacent negative case | correctness | arc01 compatibility | open |  | Avoid widening accepted input accidentally. |
| SR-10 | Timeout cleanup kills the process group for stdin-using children and returns a typed timeout. | CT hanging/TERM-resistant fixture with stdin; verify no surviving OS process and typed timeout result | serious | arc03 A6/W2 | open |  | Reuse existing timeout helpers if they fit. |
| SR-11 | Runner remains usable after stdin send failure or timeout. | CT failure/timeout followed by successful stdin run in the same suite | correctness | supervision recovery | open |  | Recovery is part of the release process contract. |
| SR-12 | No `wolong-pipeline`, public `wolong:plan/2,3`, or `wolong:validate/2` behavior changes land in this slice. | inspect diff; run existing plan/dispatch/pipeline CT suites | serious | slice scope | open |  | Pipeline stdio rewiring belongs to Slice03. |
| SR-13 | Parser `- -` caveat is encoded for later work: this slice does not assume both parser HDDL inputs can come from stdin. | inspect docs/prompt/closing report; no tests or helpers model parser both-stdin as supported | correctness | Chengdu re-entry caveat | open |  | Later pipeline likely uses one file path plus one stdin input, or parser file inputs followed by artifact stdio. |
| SR-14 | Optional local real-Chengdu smoke evidence is recorded if sibling binaries are available, without making CI depend on `../chengdu`. | run a narrow stdin probe through the new runner against `../chengdu/bin/pandapi-grounder` or `pandapi-engine`, or record why skipped | correctness | arc03 A3/A4 lead-in | open |  | Remote CI should remain fixture-backed until release artifacts exist. |
| SR-15 | Local gates and formatter check pass. | `rebar3 compile`; `rebar3 as test eunit`; `rebar3 as test ct`; `rebar3 xref`; `rebar3 dialyzer`; `rebar3 lfe format --check` | correctness | repo workflow | open |  | Record exact counts and failures. |
| SR-16 | A meaningful tamper cycle proves a new stdin invariant. | break EOF, stream separation, caps, shell-free argv, or timeout cleanup; show CT fail; revert and show pass | serious | ledger discipline | open |  | Do not commit the tamper. |
| SR-17 | Remote CI evidence is recorded honestly. | link green Ubuntu/macOS run, or mark deferred if not pushed/available | correctness | release confidence | open |  | State explicitly that CI uses fixtures, not sibling Chengdu. |
| SR-18 | Closing report walks every ledger row and bubbles up runner API, Chengdu caveat, remaining pipeline work, and project roadmap impact. | inspect `closing-report.md` for SR-1 through SR-18 and Bubble-up sections | correctness | project management | open |  | CDC writes `cdc-verification.md` later. |

## What Worked

To be completed during slice close.

## Closure

Open.
