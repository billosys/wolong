# Slice 04 Closing Report: real-binary-public-plan

Proposed done by CC on 2026-08-27. Verifier: CDC.

## Summary

Slice04 adds a repeatable public-boundary proof that Wolong drives the current
local Chengdu 0.3.0 binaries through the stdio artifact pipeline:

```text
wolong:plan/2,3
  -> pandapi-parser --supervised --status=stderr --output - DOMAIN PROBLEM
  -> pandapi-grounder --supervised --status=stderr --output - -
  -> pandapi-engine --supervised --status=stderr --output - -

wolong:validate/2
  -> pandapi-parser only
```

The proof is a focused Common Test suite:
`test/wolong_real_chengdu_SUITE.lfe`. It uses environment variables when set,
falls back to the sibling Chengdu checkout when available, and skips with a
clear reason when real binaries or fixtures are absent.

Implementation commit:

- `2d863ed` - `Add real Chengdu public plan proof`

## Real Binary Evidence

Local Chengdu source used:

```text
binary directory: ../chengdu/bin
fixture directory: ../chengdu/fixtures
chengdu branch: release/0.3.x
chengdu head: e55ef5fd
binaries:
  pandapi-parser
  pandapi-grounder
  pandapi-engine
```

Focused local proof command:

```bash
WOLONG_CHENGDU_BIN_DIR=../chengdu/bin \
WOLONG_CHENGDU_FIXTURE_DIR=../chengdu/fixtures \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Observed result:

```text
wolong_real_chengdu_SUITE: pass, all 7 tests passed
```

Cases covered:

- `wolong:plan/3` minimal solved: public `#(ok Plan)`, `outcome=solved`,
  binary payload, payload byte count greater than zero.
- `wolong:plan/2` minimal solved: same public success shape through the default
  wrapper.
- `wolong:plan/3` minimal solved with `keep-artifacts=false`: payload remains
  durable after workspace cleanup and the dispatch workspace is removed.
- `wolong:plan/3` unsolvable: public `#(unsolvable Detail)` with engine
  `status=domain_no_plan`, exit `2`, `outcome=no_plan`, and empty engine
  stdout.
- `wolong:validate/2` minimal: parser-only success with only the real parser
  binary configured.
- `wolong:validate/2` broken syntax: public typed `invalid-hddl` from parser
  `status=input_invalid`, exit `22`.
- Missing real engine tamper/proof case: public result is a typed
  `#(error #(engine binary Detail))`, not a solved proof.

Provenance assertions prove the stdio path from the public result:

```text
parser artifact source: stdout
grounder artifact source: stdout
grounder status: path=-, path_role=htn, operation=read
engine artifact source: stdout
engine status: path=-, path_role=engine_input, operation=read
```

The parser caveat remains unchanged: Wolong's release path uses domain and
problem file paths into one parser invocation; parser `- -`, split parser
workers, and framed parser stdin remain deferred.

## Availability Behavior

The suite does not turn missing real binaries into success. With a deliberately
missing binary directory:

```bash
WOLONG_CHENGDU_BIN_DIR=/tmp/wolong-missing-chengdu-bin-dir \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Observed result:

```text
init_per_suite: skipped with missing-chengdu-bin-dir
skipped 7 tests, passed 0 tests
```

This is the expected remote-CI-safe behavior when Chengdu artifacts are not
available.

## Local Verification

Local gates passed on 2026-08-27:

```text
rebar3 compile: pass
rebar3 as test eunit: pass, 9 tests, 0 failures
rebar3 as test ct: pass, all 80 tests passed
rebar3 xref: pass
rebar3 dialyzer: pass, no warnings in output
rebar3 lfe format --check: pass, all 13 files formatted
rebar3 as test lfe format --check: pass, all 22 files formatted
```

## Tamper Cycle

Tamper:

```text
changed expected engine path_role from engine_input to sas
```

Command:

```bash
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Observed result:

```text
failed 2 tests, passed 5 tests
failures:
  plan3_minimal_returns_real_plan
  plan3_unsolvable_returns_domain_result
reason:
  expected <<"sas">>, actual <<"engine_input">>
```

After reverting the tamper, the same focused suite passed 7/0.

## Remote CI

Remote CI for this slice is fixture-backed unless Chengdu binaries are present
in the CI environment. The real-binary suite is included in `rebar3 as test ct`
and skips honestly when those binaries are absent.

Implementation run:

```text
GitHub Actions build 33082934935 for 2d863ed: success
ubuntu-22.04: success
macos-15: success
https://github.com/billosys/wolong/actions/runs/33082934935
```

The remote run did not have sibling Chengdu binaries. Remote CT passed the 73
fixture-backed tests and skipped the 7 real-binary cases with
`missing-chengdu-bin-dir`.

## Ledger Walk

- **RB-1 - done.** The suite resolves `WOLONG_CHENGDU_BIN_DIR` and
  `WOLONG_CHENGDU_FIXTURE_DIR`, falling back to sibling `../chengdu/bin` and
  `../chengdu/fixtures`. Local proof used Chengdu `release/0.3.x` at
  `e55ef5fd`.
- **RB-2 - done.** The suite checks real executables and rejects paths under
  Wolong `test/fixtures`. Local proof used the real sibling `pandapi-*`
  binaries.
- **RB-3 - done.** `plan3_minimal_returns_real_plan` passed with public
  `#(ok Plan)`, `outcome=solved`, and non-empty binary payload.
- **RB-4 - done.** `plan2_minimal_returns_real_plan` passed through the
  default `wolong:plan/2` wrapper with the same solved payload invariant.
- **RB-5 - done.** `plan3_minimal_keep_false_preserves_payload` passed:
  payload bytes remain present after the dispatch workspace is removed.
- **RB-6 - done.** `plan3_unsolvable_returns_domain_result` passed with public
  `#(unsolvable Detail)`, engine `domain_no_plan`, exit `2`, `outcome=no_plan`,
  and empty engine stdout.
- **RB-7 - done.** `validate_minimal_uses_real_parser_only` configures only
  the real parser binary and returns parser success.
- **RB-8 - done.** `real_parser_negative_is_typed` uses real
  `broken-syntax` fixtures and maps parser `input_invalid`/22 to public
  `invalid-hddl`.
- **RB-9 - done.** Public result provenance proves parser artifact stdout,
  grounder stdin with `path_role=htn`, and engine stdin with
  `path_role=engine_input`.
- **RB-10 - done.** Status remains stderr-derived through the existing gate
  path; the real proof asserts status fields while artifact stdout remains the
  payload channel.
- **RB-11 - done.** The harness passes with available binaries and skips with
  a concrete `missing-chengdu-bin-dir` reason when pointed at a missing env
  path.
- **RB-12 - done.** Full CT passed 80/0, and no fixture-backed suite was
  weakened.
- **RB-13 - done.** The slice doc records the exact local command and
  environment variables.
- **RB-14 - done.** Scope guard holds. The implementation adds a focused CT
  suite only; no provisioning, parser framing, public verifier, release
  packaging, or pipeline redesign landed.
- **RB-15 - done.** Required local compile, EUnit, CT, xref, Dialyzer, and
  formatter gates passed.
- **RB-16 - done.** The engine `path_role` tamper failed the real-binary suite
  and passed again after revert.
- **RB-17 - done.** Remote GitHub Actions build `33082934935` passed on Ubuntu
  and macOS. The run was fixture-backed for executable behavior and skipped
  the real-binary suite with `missing-chengdu-bin-dir`.
- **RB-18 - done.** This report walks all 18 ledger rows and includes
  bubble-up.

## Bubble-up to the Arc

Slice04 delivers the Arc03 `real-binary-public-plan` row for local current
Chengdu binaries. Public `wolong:plan/3`, `wolong:plan/2`, and parser-only
`wolong:validate/2` proved out against the sibling Chengdu checkout at
`release/0.3.x` / `e55ef5fd`.

Remote CI remains fixture-backed for release confidence and may skip the
real-binary suite when Chengdu binaries are absent. This is intentional for
Slice04; Arc04 owns clean-machine release artifact acquisition, checksum
verification, and provenance composition.

Slice05 remains useful before Arc03 close. Slice03 and Slice04 prove bounded
capture and real fixture-scale stdio behavior; they do not yet stress
release-scale stdout/stderr backpressure or larger real artifacts.

## Bubble-up to the Project

Slice04 strengthens W1 by proving the public API, not only lower-level
runner/gate calls, against real local Chengdu binaries. W2-W4 remain protected
by the existing fixture-backed timeout, typed failure, and dispatch isolation
coverage, now with the real-binary suite included in full CT.

What remains before release readiness:

- clean-machine binary acquisition and checksum/provenance validation in Arc04;
- any Slice05 large-artifact/backpressure hardening needed before Arc03 close;
- eventual Hex publication in the project W5 path.

No new Chengdu blocker was found.
