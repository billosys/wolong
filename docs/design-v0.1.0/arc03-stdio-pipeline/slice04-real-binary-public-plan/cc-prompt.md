# CC prompt: wolong arc03 / slice04 real-binary-public-plan

You are CC implementing `slice04-real-binary-public-plan` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read First

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc03-stdio-pipeline/arc-plan.md`
4. `docs/design-v0.1.0/arc03-stdio-pipeline/slice03-stdio-gate-pipeline/closing-report.md`
5. `docs/design-v0.1.0/arc03-stdio-pipeline/slice03-stdio-gate-pipeline/cdc-verification.md`
6. `docs/design-v0.1.0/arc03-stdio-pipeline/slice04-real-binary-public-plan/slice-doc.md`
7. `docs/design-v0.1.0/arc03-stdio-pipeline/slice04-real-binary-public-plan/ledger.md`
8. `/Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md`
9. `/Users/oubiwann/lab/lfe/lfe/test/*SUITE.lfe` for canonical LFE Common Test examples
10. `src/wolong-exec.lfe`
11. `src/wolong-gate.lfe`
12. `src/wolong-pipeline.lfe`
13. `src/wolong-dispatch.lfe`
14. `src/wolong.lfe`
15. `test/wolong_gate_SUITE.lfe`
16. `test/wolong_pipeline_SUITE.lfe`
17. `test/wolong_plan_SUITE.lfe`
18. `test/wolong_dispatch_SUITE.lfe`
19. `../chengdu/docs/reference/cli.md`
20. `../chengdu/docs/managed-process.md`
21. `../chengdu/fixtures/contract/stdio-contract-records.md`
22. `../chengdu/fixtures/contract/pipeline-contract-records.md`

Also load the collaboration framework and Erlang/OTP guidance for Common Test,
supervised process boundaries, and typed return shapes. Ledger discipline
applies: update `ledger.md` as you work with attested evidence, and do not
leave all evidence for the final close.

## Mission

Turn the Slice03 local smoke into a repeatable public-boundary proof that
Wolong drives the real current Chengdu 0.3.0 binaries through the stdio
artifact pipeline:

```text
wolong:plan/2,3
  -> parser --output -
  -> grounder stdin / --output -
  -> engine stdin / --output -

wolong:validate/2
  -> parser only
```

The key distinction for this slice: the proof boundary is Wolong's public API.
Raw shell pipelines, direct Chengdu commands, and direct `wolong-exec` probes
may help diagnose failures, but they do not satisfy the slice by themselves.

## Required Shape

Add a repeatable real-binary proof harness. A focused Common Test suite such
as `test/wolong_real_chengdu_SUITE.lfe` is the preferred shape if it can be
made cleanly skippable when real binaries are absent.

Resolve real Chengdu inputs from environment or explicit config. Suggested
environment variables:

```text
WOLONG_CHENGDU_BIN_DIR
WOLONG_CHENGDU_FIXTURE_DIR
```

It is acceptable to default to the sibling checkout when it exists:

```text
../chengdu/bin
../chengdu/fixtures
```

but do not make remote CI require that sibling checkout. If the suite skips,
the skip reason must be clear, and the closing report must not claim
real-binary proof from skipped tests.

Use real binaries:

```text
pandapi-parser
pandapi-grounder
pandapi-engine
```

Do not use Wolong fixture scripts for the real-binary proof rows.

## Required Cases

Real-binary proof cases:

- `wolong:plan/3` with `../chengdu/fixtures/minimal` returns `#(ok Plan)`
  with `outcome=solved` and non-empty binary payload bytes.
- `wolong:plan/2` with the same minimal pair returns the same success shape.
- `wolong:plan/3` with `keep-artifacts=false` still returns a durable
  non-empty payload after workspace cleanup.
- `wolong:plan/3` with `../chengdu/fixtures/unsolvable` returns
  `#(unsolvable Detail)` from engine `status=domain_no_plan`, exit `2`, and
  outcome `no_plan`.
- `wolong:validate/2` with the real parser returns parser validation success
  for the minimal pair without requiring grounder or engine configuration.
- One parser negative path, preferably `../chengdu/fixtures/broken-syntax` or
  a missing domain path, maps to a typed public result using status/exit fields.
- Solved and/or no-plan provenance proves the stdio path:
  - parser artifact source is stdout;
  - grounder status includes `path=-`, `path_role=htn`, and `operation=read`;
  - engine status includes `path=-`, `path_role=engine_input`, and
    `operation=read`;
  - status comes from stderr, not artifact stdout.

Keep existing fixture-backed suites green. They remain the remote CI safety
net and should not be weakened to accommodate real-binary differences.

## Parser Caveat

Carry this forward exactly:

- the common Wolong release path is two HDDL file paths into one parser;
- parser artifact stdout feeds grounder stdin;
- grounder artifact stdout feeds engine stdin;
- parser `- -` is unsupported in Chengdu 0.3.0 and must not be assumed;
- split domain/problem parser workers and framed stdin are deferred.

Do not solve the deferred parser-framing problem in this slice.

## Scope Guard

Stay inside Slice04.

- No release downloader, checksum verifier, provenance manifest consumer, or
  Hex packaging.
- No clean-machine provisioning claim.
- No remote CI dependency on a sibling Chengdu checkout.
- No parser `- -` workaround.
- No split domain/problem parser workers.
- No framed parser stdin protocol.
- No planner pool, queue, backpressure API, or distributed Erlang.
- No diagnostic-prose classifier.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No public `wolong:verify`, action-sequence parser, or decomposition-tree
  parser.
- No broad rewrite of the stdio pipeline unless the real binaries expose a
  concrete mismatch with Chengdu's documented contract.

If a real binary fails a documented contract, stop and report the exact
Chengdu blocker before adding a Wolong workaround.

## Verification Before Close

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
rebar3 as test lfe format --check
```

Run and record the real-binary proof command. Include:

- `WOLONG_CHENGDU_BIN_DIR` and `WOLONG_CHENGDU_FIXTURE_DIR`, or the documented
  defaults used;
- Chengdu branch/head or release artifact identifier;
- solved public result summary;
- unsolvable public result summary;
- parser validation and negative-path summaries;
- whether any real-binary tests skipped, and why.

Perform one tamper cycle. Good choices:

- point the proof at a missing engine and show the public result is not a
  solved proof;
- weaken or remove the provenance assertion that distinguishes stdio from
  file handoff;
- treat no-plan as a generic error;
- accept zero-byte solved payload.

Show the owning test fails, revert the tamper, and show it passes.

If CI is available, push and record the linked green run on both Ubuntu and
macOS. State directly whether the run used real Chengdu binaries or only
fixture-backed Wolong tests.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all 18 ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did Slice04 deliver the `real-binary-public-plan` row in `arc-plan.md`;
   - what real Chengdu binary/version evidence was used;
   - whether public `plan/2`, `plan/3`, and `validate/2` proved out;
   - whether remote CI remained fixture-backed;
   - whether Slice05 backpressure hardening is still needed before Arc03 close.
4. Add `Bubble-up to the project` answering:
   - what this proves toward W1-W4;
   - what remains for clean-machine release artifacts and Arc04 provisioning;
   - whether any Chengdu blocker must pause Wolong again.
5. Update `../arc-plan.md` if implementation findings change Slice05 scope,
   Arc03 composition rows, or arc readiness.
6. Update `../../project-plan.md` only if project roadmap or release-readiness
   wording changes.
7. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
