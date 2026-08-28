# CDC Verification: Slice 04 real-binary-public-plan

Verifier: CDC  
Date: 2026-08-27  
Decision: accepted after one harness repair

## Scope

This verification covers Arc03 Slice04, whose claim is that Wolong's public
API can drive real local Chengdu 0.3.0 `pandapi-*` binaries through the stdio
artifact path:

```text
wolong:plan/2,3
  -> pandapi-parser --status=stderr --output - DOMAIN PROBLEM
  -> pandapi-grounder --status=stderr --output - -
  -> pandapi-engine --status=stderr --output - -

wolong:validate/2
  -> pandapi-parser only
```

The verification checks the slice ledger, closing report, implementation
diff, local commands, focused real-binary proof, remote CI evidence, and scope
guard.

## Inputs Inspected

- Main implementation range: `4a81490..7bf2a14`
- CDC repair commit: `d2fbcdd` (`Fix real Chengdu CT env path resolution`)
- Planning branch head: `b6222c9`
- Slice files:
  - `project01-mvp/arc03-stdio-pipeline/slice04-real-binary-public-plan/slice-doc.md`
  - `project01-mvp/arc03-stdio-pipeline/slice04-real-binary-public-plan/ledger.md`
  - `project01-mvp/arc03-stdio-pipeline/slice04-real-binary-public-plan/closing-report.md`
  - `test/wolong_real_chengdu_SUITE.lfe`

## Implementation Review

The slice implementation is narrow. The code change in the implementation
range adds `test/wolong_real_chengdu_SUITE.lfe`; production modules are not
changed by this slice.

The suite exercises the public boundary:

- `wolong:plan/3` minimal solved
- `wolong:plan/2` minimal solved wrapper
- `wolong:plan/3` minimal solved with `keep-artifacts=false`
- `wolong:plan/3` unsolvable mapped to public `#(unsolvable Detail)`
- `wolong:validate/2` parser-only success with only parser configured
- parser negative path mapped to typed `invalid-hddl`
- missing engine case proving no solved result is claimed without a real
  engine

The provenance assertions check parser artifact stdout, grounder stdin with
`path=-` and `path_role=htn`, and engine stdin with `path=-` and
`path_role=engine_input`. This verifies the stdio pipeline at Wolong's public
consumer API rather than a raw shell-pipeline diagnostic.

## CDC Repair

CDC found one issue before acceptance: the documented focused command used
relative environment paths:

```bash
WOLONG_CHENGDU_BIN_DIR=../chengdu/bin \
WOLONG_CHENGDU_FIXTURE_DIR=../chengdu/fixtures \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Common Test runs the suite from its generated log directory. Before the repair,
`configured-dir/2` resolved relative env paths against that CT log directory,
so the documented command skipped with `missing-chengdu-bin-dir` instead of
running the real proof. The default no-env sibling path still worked, which is
why full CT had passed locally.

Commit `d2fbcdd` repairs the harness by resolving relative `WOLONG_CHENGDU_*`
paths from the Wolong project root. After the repair, the documented command
runs and passes the real-binary suite.

## Local Reproduction

Current sibling Chengdu checkout used by CDC:

```text
branch: release/0.3.x
head: 7066f63c
bin dir: ../chengdu/bin
fixtures: ../chengdu/fixtures
```

The original CC report recorded Chengdu `e55ef5fd`. CDC reproduction used the
newer local sibling head `7066f63c`, so the accepted evidence is current for
the local checkout at verification time.

Commands reproduced:

```text
git diff --check: pass
rebar3 compile: pass
rebar3 as test eunit: pass, 9 tests, 0 failures
rebar3 as test ct: pass, all 80 tests passed
rebar3 xref: pass
rebar3 dialyzer: pass, exit 0 with no warnings
rebar3 lfe format --check: pass, all 13 files formatted
rebar3 as test lfe format --check: pass, all 22 files formatted
```

Focused real-binary proof after `d2fbcdd`:

```bash
WOLONG_CHENGDU_BIN_DIR=../chengdu/bin \
WOLONG_CHENGDU_FIXTURE_DIR=../chengdu/fixtures \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Observed result:

```text
wolong_real_chengdu_SUITE: pass, all 7 tests passed
```

Availability check:

```bash
WOLONG_CHENGDU_BIN_DIR=/tmp/wolong-missing-chengdu-bin-dir \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Observed result:

```text
skipped 7 tests, passed 0 tests, reason=missing-chengdu-bin-dir
```

The skip behavior is honest availability evidence only; it is not counted as
real-binary proof.

## Remote CI

CDC verified the reported GitHub Actions runs with `gh run view`.

Implementation run:

```text
run: 33082934935
head: 2d863edce69e888063314b840a7d5daddb3000de
status: completed
conclusion: success
ubuntu-22.04: success
macos-15: success
url: https://github.com/billosys/wolong/actions/runs/33082934935
```

Close-out run:

```text
run: 33083215125
head: 7bf2a14ff0d0f9172b8eeba1a7cbe26bafefc494
status: completed
conclusion: success
ubuntu-22.04: success
macos-15: success
url: https://github.com/billosys/wolong/actions/runs/33083215125
```

Remote CI remains fixture-backed for executable behavior because Chengdu
binaries are not provisioned in CI for this slice. That evidence tier is
recorded correctly in the ledger and closing report.

## Ledger Assessment

Rows RB-1 through RB-18 are accepted.

The only CDC-found gap was RB-13's documented focused command when env paths
were provided relatively. That gap is resolved by `d2fbcdd` and reproduced
locally. The rest of the ledger evidence matches the implementation and test
results:

- public `plan/2`, `plan/3`, and `validate/2` boundaries are exercised;
- real binaries are required for local proof and Wolong fixture scripts are
  rejected as real-binary substitutes;
- solved payloads are non-empty and durable after workspace cleanup;
- engine `domain_no_plan` / exit `2` maps to public unsolvable;
- parser invalid input maps through machine status fields;
- provenance proves parser stdout, grounder stdin/stdout, and engine
  stdin/stdout;
- missing real binaries skip explicitly instead of becoming success claims;
- existing fixture-backed CT and unit gates remain green;
- scope guard holds.

## Residual Risk

No blocker remains for Slice04.

Remaining work belongs to later scope:

- Arc04: clean-machine Chengdu binary acquisition, checksum/provenance, and
  release-artifact composition.
- Possible Arc03 Slice05: larger-artifact stdout/stderr backpressure and
  release-scale hardening, if the project chooses to keep that slice before
  closing Arc03.

## Decision

Slice04 is CDC-accepted as complete after `d2fbcdd`.
