# CC prompt: wolong arc02 / slice03 plan-api

You are CC implementing `slice03-plan-api` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read first

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md`
4. `docs/design-v0.1.0/arc02-gate-pipeline/slice02-pipeline-workspace/closing-report.md`
5. `docs/design-v0.1.0/arc02-gate-pipeline/slice02-pipeline-workspace/cdc-verification.md`
6. `docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/slice-doc.md`
7. `docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/ledger.md`
8. `../chengdu/docs/reference/cli.md`
9. `../chengdu/docs/managed-process.md`
10. `src/wolong.lfe`
11. `src/wolong-pipeline.lfe`
12. `src/wolong-workspace.lfe`
13. `src/wolong-gate.lfe`
14. `src/wolong-status.lfe`
15. `src/wolong-config.lfe`
16. `src/wolong-binaries.lfe`
17. `test/wolong_pipeline_SUITE.lfe`
18. `test/wolong_gate_SUITE.lfe`
19. `test/fixtures/gate-contract-substrate/`

Also load the collaboration framework and Erlang/LFE guidance used by this
repo. Ledger discipline applies: update the ledger as you work, with attested
evidence; do not leave evidence until the final close.

## Mission

Add the first public planning API over the verified internal pipeline.

At close, Wolong should expose `wolong:plan/3` and return solved,
unsolvable, or typed public gate errors:

```lfe
#(ok Plan)
#(unsolvable Detail)
#(error #(parser Reason Detail))
#(error #(grounder Reason Detail))
#(error #(engine Reason Detail))
#(error #(workspace Reason Detail))
```

The exact detail maps may evolve, but the top-level result classes and failing
gate/reason names must be matchable. Valid engine `domain_no_plan` must become
public `#(unsolvable Detail)`, not `#(error ...)` and not the internal
`#(domain-no-plan ...)`.

## Required Shape

Prefer a narrow public adapter in `src/wolong.lfe`:

- validate `DomainPath`, `ProblemPath`, and `Opts`;
- delegate to `wolong-pipeline:run/2` or a narrow helper in the pipeline layer;
- translate internal pipeline result shapes into public plan API shapes;
- preserve `wolong:validate/2` as parser-only validation.

Do not duplicate gate execution in `wolong.lfe`. The public adapter should not
build parser/grounder/engine argv, parse `PANDAPI_STATUS`, call
`wolong-exec:run/3`, create workspaces, or delete directories directly.

## OQ5 Decision

Before coding the return adapter, decide OQ5 from the arc plan: the first
public solved-plan representation.

The conservative expected answer is:

- return an artifact-backed, provenance-rich `Plan` term;
- include a durable plan payload, such as the engine plan artifact bytes or a
  copied public value, so `keep-artifacts=false` does not leave users with only
  a deleted path;
- include engine artifact metadata, parser/grounder/engine status provenance,
  workspace/cleanup metadata, and an explicit verification-boundary field;
- defer action-sequence parsing and decomposition-tree parsing unless you can
  prove a stable machine-readable plan format with tests.

If you choose a richer parsed action representation now, prove it with fixture
and real-binary evidence. Do not infer semantics from human diagnostics.

Whatever you choose, update the ledger and closing bubble-up, and update
`../arc-plan.md` if the decision changes later slice scope.

## Public Options

`wolong:plan/3` needs an explicit `Opts` contract. Keep it small.

An empty map or empty list is a reasonable accepted default. Unsupported or
malformed options should return a typed error before the external pipeline
starts. Do not silently ignore unknown options.

Add `wolong:plan/2` only if it is just a convenience wrapper over `plan/3` and
has tests.

## Tests and Fixtures

Use Common Test for public plan API integration. Add a suite such as:

```text
test/wolong_plan_SUITE.lfe
```

Reuse the strict fixtures under:

```text
test/fixtures/gate-contract-substrate/
```

Required fixture-backed cases:

- solved minimal returns `#(ok Plan)`;
- solved minimal with `keep-artifacts=false` still returns a durable plan
  payload after the dispatch workspace is removed;
- valid no-plan returns `#(unsolvable Detail)`;
- parser failure returns a parser error and short-circuits downstream gates;
- grounder failure returns a grounder error and short-circuits engine;
- engine failure returns an engine error and is distinct from unsolvable;
- malformed or unsupported opts return a typed error before fixture invocation;
- workspace/config/binary failures remain structured;
- `wolong:validate/2` still passes existing tests.

Remote CI must not depend on `../chengdu`. If you run real local evidence
against sibling `../chengdu/bin/pandapi-*`, record it separately and do not
claim CI ran real Chengdu binaries.

## Scope Guard

Stay inside slice03:

- no public `wolong:verify`;
- no `gen_statem`;
- no dispatch worker, dispatch supervisor, or concurrency model;
- no release downloader/provisioning;
- no legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback;
- no diagnostic-prose classifier;
- no broad config redesign.

## Verification Before Close

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

Also perform one tamper cycle: break a meaningful new public plan API
assertion, show the owning CT gate fails with nonzero exit, revert the tamper,
and show the suite passes again.

If CI is available, record the linked green run on both Ubuntu and macOS. If
CI uses fixture executables instead of real Chengdu binaries, say that
directly in the ledger and close report.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did slice03 deliver the `plan-api` line in `arc-plan.md`;
   - how OQ5 was dispositioned;
   - what Slice04 must know before adding dispatch supervision;
   - what Slice05 must know about the verification boundary;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Update `../arc-plan.md` if OQ5 or the public plan shape changes later slice
   scope.
5. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
