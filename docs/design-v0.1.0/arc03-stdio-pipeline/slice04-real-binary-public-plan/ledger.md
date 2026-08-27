# Slice 04 (wolong arc03): real-binary-public-plan

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at slice
> start, 2026-08-27. Closer: CC. Verifier: CDC. Evidence names commits and
> command results; CDC upgrades accepted `done` evidence from attested to
> reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| RB-1 | The real-binary proof resolves and records the actual Chengdu binary directory, fixture directory, and Chengdu branch/head or release identifier used. | inspect proof harness and closing report; run `git -C ../chengdu rev-parse --abbrev-ref HEAD` and `git -C ../chengdu rev-parse --short HEAD` when sibling checkout is used | serious | slice04 context | open | | Do not claim release-artifact proof unless a release artifact is actually used. |
| RB-2 | The real-binary proof uses real `pandapi-parser`, `pandapi-grounder`, and `pandapi-engine` binaries, not Wolong fixture scripts. | inspect config/env resolution and test setup; assert binary paths are outside `test/fixtures` | serious | arc03 A3/W1 lead-in | open | | Existing fixture suites remain separate CI evidence. |
| RB-3 | Public `wolong:plan/3` with real minimal HDDL returns `#(ok Plan)` with durable non-empty payload bytes. | run focused real-binary CT or documented command; assert result tag, outcome, payload type, and payload byte count > 0 | serious | project W1 | open | | Exact payload byte count is not the invariant. |
| RB-4 | Public `wolong:plan/2` remains a working default wrapper with real minimal HDDL. | run focused real-binary CT; assert `plan/2` returns `#(ok Plan)` with non-empty payload | correctness | public API compatibility | open | | Keep wrapper behavior aligned with fixture-backed CT. |
| RB-5 | Public solved payload survives workspace cleanup with `keep-artifacts=false` when real binaries are used. | run focused real-binary CT with keep-artifacts false; assert payload remains and dispatch workspace is removed or reports removed cleanup | serious | project W1/Arc02 compatibility | open | | Durable payload is the API promise. |
| RB-6 | Public `wolong:plan/3` with real unsolvable HDDL returns `#(unsolvable Detail)` from engine `domain_no_plan`, exit `2`, outcome `no_plan`, and empty plan stdout. | run focused real-binary CT; inspect public detail/provenance/status fields | serious | project W1/A4 | open | | No-plan is a success-shaped domain result, not generic error. |
| RB-7 | `wolong:validate/2` remains parser-only when configured with the real parser binary. | run focused real-binary CT with only parser configured if feasible; assert valid pair returns parser success and grounder/engine are not required/invoked | serious | public API compatibility | open | | Validation is outside the plan pipeline. |
| RB-8 | At least one real parser negative path maps to a typed public result from status/exit fields, not diagnostic prose. | run missing-input or broken-syntax/broken-reference through `wolong:validate/2` or `wolong:plan/3`; assert public typed error and parser status fields | serious | arc03 A5 | open | | Prefer stable fixtures under `../chengdu/fixtures`. |
| RB-9 | Real-binary public plan provenance proves the stdio pipeline path: parser artifact stdout, grounder input `path=-`/`path_role=htn`, and engine input `path=-`/`path_role=engine_input`. | focused CT asserts status/provenance fields on solved and/or no-plan public results | serious | arc03 A3 | open | | This is the core "not file handoff" proof. |
| RB-10 | Final machine status remains parsed from stderr for real-binary public runs. | inspect gate path and assert real-binary status fields are present while artifact stdout is not parsed as status | serious | managed-process safety | open | | No diagnostic-prose classifier. |
| RB-11 | The real-binary proof harness has honest availability behavior: skip only when required real binaries/fixtures are absent, and never converts a skip into a success claim. | run with available binaries and, if practical, with a deliberately missing env path; inspect skip/error reporting | correctness | CI honesty | open | | Remote CI may skip real-binary cases if Chengdu artifacts are absent. |
| RB-12 | Existing fixture-backed CT suites still pass and continue to model the stdio contract for CI. | `rebar3 as test ct`; inspect no fixture coverage was weakened to satisfy real binaries | serious | regression protection | open | | Fixture-backed CI remains the cross-platform guard. |
| RB-13 | The operator-facing docs explain how to run the real-binary proof locally. | inspect README, arc docs, or slice docs for exact command/env variables | correctness | release workflow | open | | Keep it short and reproducible. |
| RB-14 | Scope guard holds: no provisioning, downloader, checksum verifier, Hex publication, parser `- -` workaround, split parser workers, public verifier, action parser, or decomposition parser lands. | inspect diff and `rg` scoped terms in `src`, `test`, `README.md`, and docs | serious | slice-doc scope | open | | Arc04 owns provisioning. |
| RB-15 | Local gates and formatter checks pass. | `rebar3 compile`; `rebar3 as test eunit`; `rebar3 as test ct`; `rebar3 xref`; `rebar3 dialyzer`; `rebar3 lfe format --check`; `rebar3 as test lfe format --check` | correctness | repo workflow | open | | No exceptions unless explicitly deferred with reason. |
| RB-16 | A meaningful tamper cycle proves a real-binary public-boundary invariant. | break the real-binary proof or its assertions; show owning test fails; revert and show it passes | serious | ledger discipline | open | | Do not commit the tamper. |
| RB-17 | Remote CI evidence is recorded honestly. | link green Ubuntu/macOS run, or mark deferred if not pushed/available; state whether real binaries were present | correctness | release confidence | open | | Fixture-backed CI is acceptable but must be named. |
| RB-18 | Closing report walks every ledger row and bubbles up Arc03 composition impact, real-binary evidence tier, remaining release-artifact gap, and Slice05/Arc04 readiness. | inspect `closing-report.md` for RB-1 through RB-18 and Bubble-up sections | correctness | project management | open | | CDC writes `cdc-verification.md` later. |

## What Worked

_(At slice close. Patterns that made the slice close cleanly.)_

## Closure

_(At slice close. Include closing commit, row counts, and verifier.)_
