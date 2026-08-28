# CC prompt: wolong arc03 / slice05 backpressure-timeout-hardening

You are CC implementing `slice05-backpressure-timeout-hardening` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read First

1. `AGENTS.md`
2. `.worktrees/planning/project01-mvp/project-plan.md`
3. `.worktrees/planning/project01-mvp/arc03-stdio-pipeline/arc-plan.md`
4. `.worktrees/planning/project01-mvp/arc03-stdio-pipeline/slice04-real-binary-public-plan/closing-report.md`
5. `.worktrees/planning/project01-mvp/arc03-stdio-pipeline/slice04-real-binary-public-plan/cdc-verification.md`
6. `.worktrees/planning/project01-mvp/arc03-stdio-pipeline/slice05-backpressure-timeout-hardening/slice-doc.md`
7. `.worktrees/planning/project01-mvp/arc03-stdio-pipeline/slice05-backpressure-timeout-hardening/ledger.md`
8. `/Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md`
9. `/Users/oubiwann/lab/lfe/lfe/test/*SUITE.lfe` for canonical LFE Common Test examples
10. `src/wolong-exec.lfe`
11. `src/wolong-gate.lfe`
12. `src/wolong-pipeline.lfe`
13. `src/wolong-config.lfe`
14. `src/wolong-dispatch.lfe`
15. `src/wolong.lfe`
16. `config/sys.config`
17. `README.md`
18. `test/wolong_exec_SUITE.lfe`
19. `test/wolong_gate_SUITE.lfe`
20. `test/wolong_pipeline_SUITE.lfe`
21. `test/wolong_plan_SUITE.lfe`
22. `test/wolong_dispatch_SUITE.lfe`
23. `test/wolong_real_chengdu_SUITE.lfe`
24. `test/fixtures/gate-contract-substrate/`
25. `test/fixtures/exec-runner/`
26. `../chengdu/docs/reference/cli.md`
27. `../chengdu/docs/managed-process.md`
28. `../chengdu/fixtures/contract/stdio-contract-records.md`
29. `../chengdu/fixtures/contract/pipeline-contract-records.md`

Also load the collaboration framework and Erlang/OTP guidance for process
boundaries, Common Test, timeout semantics, and typed return shapes. Ledger
discipline applies: update `ledger.md` as you work with attested evidence, and
do not leave all evidence for the final close.

Important repository note: planning artifacts are on the `planning` worktree,
not on `main`. Make code/test/runtime-doc changes in the main worktree, and
make slice ledger/closing-plan updates in `.worktrees/planning`.

## Mission

Harden Wolong's existing stdio pipeline under larger outputs and noisy
diagnostics without redesigning the architecture.

The target behavior:

```text
parser stdout artifact -> grounder stdin
grounder stdout artifact -> engine stdin
engine stdout artifact -> public plan payload
stderr diagnostics + final PANDAPI_STATUS -> typed classification
```

The release-critical invariant is that stdout artifacts are never trusted when
truncated, while stderr diagnostics may be bounded without losing the final
machine status needed for classification.

## Required Shape

Keep the current public API:

```lfe
(wolong:plan domain problem)
(wolong:plan domain problem opts)
(wolong:validate domain problem)
```

Do not add a streaming subsystem, process pool, queue API, release downloader,
parser-framing protocol, or public verifier.

Prefer a small compatibility-preserving extension to runner/gate output
options. A good shape is:

```text
output-limit-bytes      existing compatibility value for both streams
stdout-limit-bytes      optional stdout override
stderr-limit-bytes      optional stderr override
```

Then derive gate runner options from optional application config, for example
an `output-limits` map by gate and stream. Existing configs must keep working
when the new key is absent.

Be careful with stderr. Chengdu writes final `PANDAPI_STATUS` after artifact
disposition, so a process may emit diagnostics before the only status line
Wolong needs. It is acceptable to return a bounded stderr diagnostic preview,
but completed-process classification must still see the final status line when
it was emitted. Use a bounded design, such as retaining a stderr tail or
extracted status line in addition to the preview; do not keep unbounded stderr
in memory.

For stdout artifacts, truncation is not recoverable. If parser, grounder, or
solved-engine stdout exceeds the configured stdout artifact limit, return a
typed gate error and never a partial downstream artifact or solved plan.

## Required Cases

Use Common Test and the existing `test` tree. Extend existing suites/fixtures
where that stays clearer than adding a new suite; add a focused hardening suite
only if the existing suites become crowded.

Cover these cases:

- parser stdout artifact larger than the old 65536-byte cap but within the
  configured parser stdout limit feeds grounder stdin successfully;
- grounder stdout artifact larger than the old cap but within the configured
  grounder stdout limit feeds engine stdin successfully;
- engine stdout solved plan larger than the old cap but within the configured
  engine stdout limit returns public `#(ok Plan)` with durable payload bytes;
- stdout artifact over the configured limit returns a typed gate error, such
  as `artifact-truncated`, and no partial solved plan crosses `wolong:plan/2,3`;
- noisy stderr before final `PANDAPI_STATUS` exceeds the diagnostic preview
  limit but the final status fields are still parsed and used for
  classification;
- genuinely missing or unrecoverable final status returns a typed status error
  rather than a diagnostic-prose guess;
- flood-then-timeout while stdout/stderr are active returns a typed timeout,
  bounds output, records truncation metadata, kills the process group, and
  leaves no survivor;
- after over-limit output or timeout, a later minimal plan succeeds and worker
  count returns to zero;
- existing solved, unsolvable, parser invalid, grounder invalid, engine
  invalid, binary-missing, and dispatch-isolation cases remain green.

## Scope Guard

Stay inside Slice05.

- No streaming/spooling architecture unless the current model is proven
  insufficient; if so, stop and bubble up a new design/slice recommendation.
- No parser `- -` workaround.
- No split domain/problem parser workers.
- No framed parser stdin protocol.
- No planner pool, queue, or distributed Erlang.
- No release downloader, checksum verifier, provenance manifest consumer, or
  Hex packaging.
- No remote CI dependency on a sibling Chengdu checkout.
- No diagnostic-prose classifier.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No public `wolong:verify`, action-sequence parser, or decomposition-tree
  parser.
- No broad rewrite of dispatch or the public API.

If a real Chengdu binary fails a documented contract, stop and report the
exact Chengdu blocker before adding a Wolong workaround.

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

Run and record a focused CT command for the new hardening cases.

Run and record the existing local real-Chengdu public proof when sibling
binaries are available:

```bash
WOLONG_CHENGDU_BIN_DIR=../chengdu/bin \
WOLONG_CHENGDU_FIXTURE_DIR=../chengdu/fixtures \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Include the Chengdu branch/head or release artifact identifier used. If the
suite skips, record the skip reason and do not claim real-binary proof.

Perform one tamper cycle. Good choices:

- remove final-status preservation under noisy/truncated stderr;
- accept a truncated stdout artifact as usable;
- collapse separate stdout/stderr limits back into one too-small cap;
- bypass process-group kill in the flood-then-timeout case.

Show the owning CT case fails, revert the tamper, and show it passes.

If CI is available, push and record a linked green run on Ubuntu and macOS.
State directly whether remote CI used real Chengdu binaries or only Wolong
fixtures.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all 22 ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did Slice05 discharge Arc03's remaining timeout/backpressure hardening
     risk;
   - what output-capture policy landed;
   - whether final status survives noisy/truncated stderr;
   - whether stdout artifact truncation remains typed and safe;
   - whether Arc03 is ready to close or needs a remediation slice.
4. Add `Bubble-up to the project` answering:
   - what this proves toward W1-W4;
   - what remains for Arc04 clean-machine release artifacts and provenance;
   - whether any Chengdu blocker pauses Wolong again.
5. Update `../arc-plan.md` if implementation findings change Arc03 readiness,
   OQ4, A6, or the Slice05 disposition.
6. Update `../../project-plan.md` if project status, README/release-readiness
   wording, or Arc04 prerequisites change.
7. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
