# CDC Verification: Slice 03 stdio-gate-pipeline

Verifier: CDC
Date: 2026-08-27
Subject: CC closure commits through `bfd8cef`

## Decision

Accepted.

Slice03 closes. The implementation wires Wolong's planning pipeline through
the supported Chengdu stdio artifact contract while preserving the public
`wolong:plan/2`, `wolong:plan/3`, and `wolong:validate/2` shapes:

```text
domain/problem paths -> parser --output -
parser stdout bytes  -> grounder stdin, grounder --output -
grounder stdout bytes -> engine stdin, engine --output -
engine stdout bytes   -> public plan payload, or empty stdout for no-plan
```

The parser caveat remains explicit: parser `- -`, split parser workers, and a
framed parser stdin protocol are not part of this slice.

## Scope Reviewed

Commits reviewed:

- `d243a66` - `Wire gate pipeline through stdio artifacts`
- `ea2a330` - `Tighten stdio truncation fixture`
- `bfd8cef` - `Close stdio gate pipeline slice`

Primary implementation files reviewed:

- `src/wolong-gate.lfe`
- `src/wolong-pipeline.lfe`
- `test/wolong_gate_SUITE.lfe`
- `test/wolong_pipeline_SUITE.lfe`
- `test/wolong_plan_SUITE.lfe`
- `test/wolong_dispatch_SUITE.lfe`
- `test/fixtures/gate-contract-substrate/pandapi-parser-fixture.sh`
- `test/fixtures/gate-contract-substrate/pandapi-grounder-fixture.sh`
- `test/fixtures/gate-contract-substrate/pandapi-engine-fixture.sh`

Closure artifacts reviewed:

- `docs/design-v0.1.0/arc03-stdio-pipeline/slice03-stdio-gate-pipeline/ledger.md`
- `docs/design-v0.1.0/arc03-stdio-pipeline/slice03-stdio-gate-pipeline/closing-report.md`
- `docs/design-v0.1.0/arc03-stdio-pipeline/arc-plan.md`
- `docs/design-v0.1.0/project-plan.md`

## Local Verification

Commands rerun by CDC:

```text
git status --short --branch
git diff --check
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
rebar3 as test lfe format --check
```

Observed results:

```text
git status: ## main...origin/main
git diff --check: pass
rebar3 compile: pass
rebar3 as test eunit: pass, 9 tests, 0 failures
rebar3 as test ct: pass, all 73 tests passed
rebar3 xref: pass
rebar3 dialyzer: pass
rebar3 lfe format --check: pass, all 13 files formatted
rebar3 as test lfe format --check: pass, all 21 files formatted
```

## Remote CI Verification

CDC verified the final closure-state GitHub Actions run:

```text
run: 33038811918
head SHA: bfd8ceff5a778b9941bc87bb3f9d0f1366c1f98c
status: completed
conclusion: success
ubuntu-22.04: success
macos-15: success
url: https://github.com/billosys/wolong/actions/runs/33038811918
```

Both platform jobs passed compile, EUnit, Common Test, xref, and Dialyzer. The
remote CI evidence remains fixture-backed and does not use sibling Chengdu
binaries.

## Real Chengdu Smoke

CDC also reproduced the local public-boundary smoke against the sibling Chengdu
checkout:

```text
chengdu branch: release/0.3.x
chengdu head: e55ef5fd
binaries:
  ../chengdu/bin/pandapi-parser
  ../chengdu/bin/pandapi-grounder
  ../chengdu/bin/pandapi-engine
```

Observed public API results:

```text
minimal:
  call: wolong:plan/3
  result tag: ok
  payload bytes: 2033

unsolvable:
  call: wolong:plan/3
  result tag: unsolvable
  engine status: domain_no_plan
  engine exit-code: 2
  engine outcome: no_plan
```

CC's closing report recorded 2040 payload bytes for the minimal smoke. CDC saw
2033 bytes on the current sibling Chengdu checkout. This is not a blocker:
the release criterion is the public solved shape and durable non-empty engine
stdout payload, not an exact byte count for this fixture.

## Ledger Assessment

Rows SG-1 through SG-22 are accepted as done.

- SG-1 through SG-5: accepted. Inspection confirms parser stdout, grounder
  stdin/stdout, and engine stdin/stdout are the active pipeline path.
- SG-6 and SG-7: accepted. Public solved payload survives cleanup, and
  engine `domain_no_plan` / exit `2` maps to public `#(unsolvable Detail)`.
- SG-8 through SG-12: accepted. Status remains stderr-derived, typed failure
  mapping is preserved, timeout cleanup remains covered, and truncated stdout
  artifacts become typed errors.
- SG-13 through SG-16: accepted. Workspace metadata, public API shape,
  parser-only validation, and fixture honesty match the slice contract.
- SG-17: accepted with the payload-byte note above.
- SG-18: accepted. Scope grep found deferred or out-of-scope terms only in
  explicit scope/deferral prose and existing verification-boundary metadata.
- SG-19 through SG-22: accepted. Local gates, tamper evidence, remote CI, and
  closing-report walk are present.

## Residual Risk

The current exec capture policy is prefix-capped. Slice03 proves bounded
fixture behavior and rejects truncated stdout artifacts. A future real binary
that emits more than the stderr cap before its final `PANDAPI_STATUS` could
still lose the machine status and become a typed missing-status failure. This
is a reasonable Slice05 hardening topic rather than a Slice03 closure blocker.

## Bubble-up

Arc03 is now past the Wolong-owned stdio pipeline shape. The next slice should
focus on real-binary public-plan proof as the primary evidence layer, including
`wolong:plan/2`, `wolong:plan/3`, `wolong:validate/2`, solved/no-plan/error
cases, and the documented parser caveat.
