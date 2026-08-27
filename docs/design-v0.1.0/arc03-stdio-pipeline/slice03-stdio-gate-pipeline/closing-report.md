# Slice 03 Closing Report: stdio-gate-pipeline

Proposed done by CC on 2026-08-26. Verifier: CDC.

## Summary

Slice03 wires Wolong's internal planning pipeline through Chengdu's supported
stdio artifact contract:

```text
domain/problem paths -> parser --output -
parser stdout bytes  -> grounder stdin, grounder --output -
grounder stdout bytes -> engine stdin, engine --output -
engine stdout bytes   -> public plan payload, or empty stdout for no-plan
```

The public API remains `wolong:plan/2`, `wolong:plan/3`, and
`wolong:validate/2`. The parser remains a single complete planning-instance
invocation with domain and problem paths; parser `- -` and split parser workers
remain unsupported/deferred.

Implementation commits:

- `d243a66` - `Wire gate pipeline through stdio artifacts`
- `ea2a330` - `Tighten stdio truncation fixture`

## Delivered

- `wolong-gate`
  - adds `classify-stdout/3`;
  - adds `run-parser-stdout-to/5`, `run-grounder-stdin-to/4`, and
    `run-engine-stdin-to/4`;
  - preserves the file-backed `classify/3`, `run-parser-to/5`,
    `run-grounder-to/4`, and `run-engine-to/4` helpers;
  - treats truncated stdout artifacts as `artifact-truncated`;
  - records stdout-sourced artifact metadata and `os-pid`.
- `wolong-pipeline`
  - invokes parser with `--output -`;
  - feeds parser stdout bytes to grounder stdin;
  - feeds grounder stdout bytes to engine stdin;
  - materializes stdout artifacts into the workspace after classification;
  - builds public plan payloads from engine stdout before cleanup.
- Gate fixtures and CT suites
  - model parser artifact stdout, grounder stdin/stdout, engine stdin/stdout,
    engine no-plan empty stdout, parser `- -` usage error, and stdout
    truncation.

## Verification

Local gates passed on 2026-08-26:

```text
rebar3 compile: pass
rebar3 as test eunit: pass, 9 tests, 0 failures
rebar3 as test ct: pass, all 73 tests passed
rebar3 xref: pass
rebar3 dialyzer: pass
rebar3 lfe format --check: pass, all 13 files formatted
rebar3 as test lfe format --check: pass, all 21 files formatted
```

Focused suites after formatting:

```text
wolong_gate_SUITE: pass, 17 tests
wolong_pipeline_SUITE: pass, 9 tests
wolong_plan_SUITE: pass, 10 tests
wolong_dispatch_SUITE: pass, 10 tests
```

Tamper cycle:

```text
tamper: changed grounder handoff back to run-grounder-to/4 file input
command: rebar3 compile && rebar3 as test ct --suite test/wolong_pipeline_SUITE.lfe
observed: failed 4 tests, passed 5 tests
revert: restored run-grounder-stdin-to/4 handoff
observed: same command passed 9 tests
```

Remote CI:

```text
GitHub Actions build 33038449082 for ea2a330: success
ubuntu-22.04: success
macos-15: success
https://github.com/billosys/wolong/actions/runs/33038449082
```

Remote CI is fixture-backed. It does not depend on sibling Chengdu binaries.

## Local Chengdu Smoke

Sibling Chengdu binaries were available under `../chengdu/bin`. Local-only
smoke probes ran public `wolong:plan/3` with those binaries:

```text
minimal:
  result: #(ok Plan)
  payload-bytes: 2040
  parser artifact: stdout, 2444 bytes
  grounder artifact: stdout, 446 bytes, path=-, path_role=htn
  engine artifact: stdout, 2040 bytes, path=-, path_role=engine_input

unsolvable:
  result: #(unsolvable Detail)
  engine exit-status: 2
  engine status: domain_no_plan
  engine stdout-bytes: 0
  engine path=-, path_role=engine_input
```

This evidence proves the current implementation can drive the local sibling
binaries, but it does not close Slice04's real-binary public-plan proof.

## Ledger Walk

- **SG-1 - done.** Pipeline parser invocation uses
  `wolong-gate:run-parser-stdout-to/5`, which builds
  `--supervised --status=stderr --output - DOMAIN PROBLEM`. CT also proves
  parser `- -` is a usage error.
- **SG-2 - done.** Parser stdout is accepted as the parser artifact through
  `classify-stdout/3`. CT asserts `artifact=stdout`, `source=stdout`, and no
  output file requirement at the gate helper.
- **SG-3 - done.** Grounder is invoked with input path `-` and receives parser
  stdout bytes via `wolong-exec:run-stdin/4`. CT asserts `path=-`,
  `path_role=htn`, and `operation=read`.
- **SG-4 - done.** Grounder stdout is classified as the grounder artifact
  without requiring a gate output file. Pipeline materialization happens only
  after classification.
- **SG-5 - done.** Engine is invoked with input path `-` and receives grounder
  stdout bytes via `wolong-exec:run-stdin/4`. CT asserts `path=-`,
  `path_role=engine_input`, and `operation=read`.
- **SG-6 - done.** Solved engine stdout becomes `plan-payload` with
  `source=engine-stdout` before cleanup; `keep-artifacts=false` public plan
  tests retain the payload after workspace removal.
- **SG-7 - done.** Engine no-plan remains internal `#(domain-no-plan Detail)`
  and public `#(unsolvable Detail)`, with exit `2`, `status=domain_no_plan`,
  and empty stdout.
- **SG-8 - done.** Status parsing still reads stderr. Fixtures emit final
  `PANDAPI_STATUS` on stderr, and no stdout-status classifier was added.
- **SG-9 - done.** Parser, grounder, engine, status mismatch, missing status,
  and unmapped status failures remain typed and gate-named across CT suites.
- **SG-10 - done.** Exec-layer failures remain typed and gate-named. Existing
  command/binary/start/timeout coverage passed; no public gate path exposes an
  invalid stdin payload.
- **SG-11 - done.** TERM-resistant engine timeout over stdin is killed, exposes
  bounded detail including `os-pid`, and later solved planning recovers.
- **SG-12 - done.** Output truncation is honest: a large stdout artifact is
  rejected as `artifact-truncated`, with bounded stdout and truncated stderr
  metadata preserved.
- **SG-13 - done.** Workspace cleanup remains honest. Captured stdout artifacts
  are materialized under the workspace for keep-true evidence and are removed
  for keep-false, while the public payload remains durable.
- **SG-14 - done.** Public `wolong:plan/2,3` result tags and metadata remain
  stable for solved, unsolvable, typed errors, dispatch, and verification
  boundary.
- **SG-15 - done.** `wolong:validate/2` remains parser-only and file-backed;
  parser validation CT and dispatch parser-only CT pass.
- **SG-16 - done.** CI fixtures now model parser stdout, grounder stdin/stdout,
  engine stdin/stdout, engine no-plan empty stdout, and parser `- -`
  unsupported.
- **SG-17 - done.** Local real-Chengdu solved and no-plan public-plan smokes
  passed and are recorded separately from CI.
- **SG-18 - done.** Scope guard holds. No split parser workers, framed stdin,
  provisioning, public API redesign, diagnostic-prose classifier, legacy
  binary fallback, verifier, action parser, or decomposition parser landed.
- **SG-19 - done.** Required local gates and formatter checks passed.
- **SG-20 - done.** File-handoff tamper failed the owning pipeline CT gate,
  then passed after revert.
- **SG-21 - done.** Remote GitHub Actions build `33038449082` passed on Ubuntu
  and macOS. The run is fixture-backed.
- **SG-22 - done.** This report walks all 22 rows and includes bubble-up.

## Bubble-up to the Arc

Slice03 delivers Arc03's `stdio-gate-pipeline` row for the Wolong-owned
pipeline path. The landed shape is:

```text
pandapi-parser --supervised --status=stderr --output - DOMAIN PROBLEM
pandapi-grounder --supervised --status=stderr --output - -
pandapi-engine --supervised --status=stderr --output - -
```

Parser `- -`, split domain/problem parser workers, framed stdin, and artifact
merge protocols remain deferred. Slice04 can now focus on proving public
`wolong:plan/2,3` and `wolong:validate/2` against real Chengdu release
artifacts or local binaries as its primary evidence layer, rather than
changing Wolong's internal handoff shape.

Slice05 should remain separate for release-scale backpressure and larger
artifact stress. Slice03 rejects truncated stdout artifacts and proves bounded
fixture behavior, but it does not prove large real artifact streaming under
release-scale load.

## Bubble-up to the Project

Arc03 is no longer blocked on Wolong's internal pipeline shape. The remaining
release-readiness evidence is a real-binary public-plan proof in Slice04, then
any necessary Slice05 stress hardening before Arc04 provisioning.
