# CC prompt: wolong arc02 / slice02 pipeline-workspace

You are CC implementing `slice02-pipeline-workspace` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read first

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md`
4. `docs/design-v0.1.0/arc02-gate-pipeline/slice01-gate-contract-substrate/closing-report.md`
5. `docs/design-v0.1.0/arc02-gate-pipeline/slice01-gate-contract-substrate/cdc-verification.md`
6. `docs/design-v0.1.0/arc02-gate-pipeline/slice02-pipeline-workspace/slice-doc.md`
7. `docs/design-v0.1.0/arc02-gate-pipeline/slice02-pipeline-workspace/ledger.md`
8. `../chengdu/docs/reference/cli.md`
9. `../chengdu/docs/managed-process.md`
10. `src/wolong-config.lfe`
11. `src/wolong-binaries.lfe`
12. `src/wolong-exec.lfe`
13. `src/wolong-status.lfe`
14. `src/wolong-gate.lfe`
15. `test/wolong_gate_SUITE.lfe`
16. `test/fixtures/gate-contract-substrate/`

Also load the collaboration framework and Erlang/LFE guidance used by this
repo. Ledger discipline applies: update the ledger as you work, with
attested evidence; do not leave evidence until the final close.

## Mission

Build the internal pipeline workspace and sequential orchestration substrate.

At close, Wolong should be able to run an internal parse -> ground -> solve
pipeline through `wolong-gate`, using a unique per-dispatch workspace under
configured `workdir.base-dir`, with stable artifact roles, cleanup controlled
by `workdir.keep-artifacts`, short-circuit behavior on gate failure, and a
success-shaped engine no-plan result.

This slice must not add public `wolong:plan` or `wolong:verify`. Slice03 will
wrap this internal substrate into the public planning API.

## Required Shape

Prefer a small internal module boundary:

- `wolong-pipeline` for orchestration;
- optionally `wolong-workspace` for workspace create/path/cleanup helpers;
- small extensions to `wolong-gate` if explicit output paths are needed.

Names are suggestions; follow the codebase if a cleaner local shape emerges.
The invariants matter:

- one dispatch gets one unique workspace directory under configured
  `workdir.base-dir`;
- parser, grounder, and engine artifacts have stable roles/names inside that
  workspace;
- every gate runs through `wolong-gate` and therefore through
  `wolong-exec:run/3`;
- failure stops the next gate from running;
- cleanup never deletes outside the dispatch workspace;
- returned details preserve enough metadata to debug success, no-plan, and
  failure after cleanup.

The pipeline result shape is internal, but it should be ready for Slice03 to
translate:

```lfe
#(ok Detail)
#(domain-no-plan Detail)
#(error #(parser Reason Detail))
#(error #(grounder Reason Detail))
#(error #(engine Reason Detail))
#(error #(workspace Reason Detail))
```

That shape is a recommendation, not a syntax prison. If you choose a different
shape, it must still name the failing gate/reason and preserve gate/workspace
metadata. Valid engine no-plan must not be error-shaped.

## OQ4 Decision

Before implementing around output assumptions, decide OQ4 from the arc plan:

- implement stream-to-file runner capture now, or
- explicitly accept file-backed artifacts plus capped stdout/stderr
  diagnostics for 0.1.0, with a re-entry condition for stream-to-file if
  later engine diagnostics exceed the cap or public API needs full streams.

Given the current Chengdu managed-process contract uses file-backed artifacts
and empty stdout for supervised normal paths, the conservative expected answer
is probably "file-backed artifacts plus capped diagnostics are sufficient for
0.1.0." But make the decision explicit in the ledger and closing bubble-up.

## Slice01 Residual

Slice01 CDC left this residual hardening note:

> `wolong-gate` classifies from the observed OS exit status plus final
> `status` field and preserves status-line `exit_code`; it does not yet reject
> a contradictory status-line `exit_code`.

Disposition it in this slice before public API work begins. Prefer a small
typed mismatch result and CT coverage if the change stays local. If you defer
it, the deferral must have a concrete reason and re-entry condition in the
ledger and closing report.

## Tests and Fixtures

Use Common Test for workspace/process integration. Add a suite such as:

```text
test/wolong_pipeline_SUITE.lfe
```

Reuse the strict fixtures under:

```text
test/fixtures/gate-contract-substrate/
```

Add small fixture triggers only where necessary to prove:

- parser failure short-circuits grounder and engine;
- grounder failure short-circuits engine;
- engine failure differs from engine no-plan;
- cleanup policy does not remove outside the dispatch workspace.

Remote CI must not depend on `../chengdu`. If you run real local evidence
against sibling `../chengdu/bin/pandapi-*`, record it separately and do not
claim CI ran real Chengdu binaries.

## Scope Guard

Stay inside slice02:

- no public `wolong:plan`;
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

Also perform one tamper cycle: break a meaningful new pipeline/workspace
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
   - did slice02 deliver the workspace/orchestration line in `arc-plan.md`;
   - how OQ4 was dispositioned;
   - how the Slice01 status-mismatch residual was dispositioned;
   - what Slice03 must know before wrapping this into `wolong:plan`;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Update `../arc-plan.md` if OQ4 or the residual changes later slice scope.
5. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
