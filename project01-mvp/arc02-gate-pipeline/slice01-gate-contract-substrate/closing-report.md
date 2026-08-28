# Slice 01 Closing Report: Gate Contract Substrate

Closed by CC on 2026-08-14.

Implementation commit:
`5f0e926f718c9a89da57718dfd25702fbdbdc6b5` (`Implement gate contract substrate`).

CI evidence:
GitHub Actions run `31828476858`
(`https://github.com/billosys/wolong/actions/runs/31828476858`) passed on
Ubuntu 22.04 and macOS 15: compile, EUnit, Common Test, xref, and Dialyzer.

## Scope Delivered

- Added `wolong-binaries:grounder/0` and `wolong-binaries:engine/0`, preserving
  app-env-only managed binary lookup.
- Extracted final `PANDAPI_STATUS` parsing to `src/wolong-status.lfe`; parsing
  now uses the final status line and preserves unknown valid fields.
- Added `src/wolong-gate.lfe` for supervised argv construction, gate execution,
  shared result details, artifact checks, and managed-status mapping.
- Kept `wolong:validate/2` as the public parser compatibility adapter; no
  public `wolong:plan/verify` API was added.
- Added Common Test fixture coverage for parser, grounder, and engine, including
  a one-shot supervised `parse -> ground -> solve` chain through
  `wolong-exec:run/3`.

## Evidence Summary

Local real-binary survey:

- `../chengdu/bin/pandapi-parser --version`,
  `../chengdu/bin/pandapi-grounder --version`, and
  `../chengdu/bin/pandapi-engine --version` each exited 0 and reported
  `chengdu_version=0.3.0` with `managed_process_contract=0.3.0`.
- Minimal supervised local pipeline exited parser/grounder/engine `0/0/0`,
  wrote `.htn`, `.sas`, and `.plan` artifacts, and kept stdout empty.
- Unsolvable local pipeline exited parser/grounder/engine `0/0/2`; engine
  emitted final `status=domain_no_plan`, `outcome=no_plan`, and no plan
  artifact.

Local Wolong gates:

- `rebar3 compile`: passed.
- `rebar3 as test eunit`: 9 tests, 0 failures.
- `rebar3 as test ct`: 33 tests, 0 failures.
- `rebar3 xref`: passed.
- `rebar3 dialyzer`: exited 0.

Tamper evidence:

- Temporarily changed engine `domain_no_plan` mapping from success-shaped
  `#(domain-no-plan Detail)` to error-shaped
  `#(error #(domain-no-plan Detail))`.
- `rebar3 as test ct --suite test/wolong_gate_SUITE.lfe` failed nonzero at
  `engine_domain_no_plan_success_shape`.
- Reverted the tamper; the same gate suite passed all 13 tests, and the full CT
  suite later passed all 33 tests.

## Tooling Finding

`rebar3 as test ltest` is not a registered provider in this repository. The
existing rebar3_lfe/EUnit autoexport workaround remains the correct way to run
the ltest-backed unit modules: `rebar3 as test eunit` passed 9 tests locally and
in CI.

## Bubble-Up

- Real Chengdu binary provisioning remains deferred to the release/provisioning
  arc. This slice records local real-binary behavior but CI uses checked-in
  Wolong fixture executables.
- The mapper now preserves engine no-plan as internal success-shaped
  `#(domain-no-plan Detail)`. A later public planning API slice should translate
  that to the project-level unsolvable shape without reclassifying it as an
  error.
- `wolong:validate/2` still preserves Arc01 parser semantics. Public
  `wolong:plan/2` and `wolong:verify/2` remain out of scope.
- A child executable with a bad interpreter produces a completed process with no
  managed status in this environment, so public parser validation reports
  `parser status-missing`; true runner `exec` errors are preserved in the shared
  gate classifier and covered directly.

## Ledger

`ledger.md` has 12 rows: 12 done, 0 deferred, 0 no-op. CDC verification remains
separate; no `cdc-verification.md` was created by CC.
