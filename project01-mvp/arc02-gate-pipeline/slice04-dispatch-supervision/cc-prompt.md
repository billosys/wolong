# CC prompt: wolong arc02 / slice04 dispatch-supervision

You are CC implementing `slice04-dispatch-supervision` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read First

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md`
4. `docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/closing-report.md`
5. `docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/cdc-verification.md`
6. `docs/design-v0.1.0/arc02-gate-pipeline/slice04-dispatch-supervision/slice-doc.md`
7. `docs/design-v0.1.0/arc02-gate-pipeline/slice04-dispatch-supervision/ledger.md`
8. `/Users/oubiwann/lab/lfe/lfe/test/*SUITE.lfe` for canonical LFE Common Test examples
9. `src/wolong.lfe`
10. `src/wolong-sup.lfe`
11. `src/wolong-app.lfe`
12. `src/wolong-pipeline.lfe`
13. `src/wolong-workspace.lfe`
14. `src/wolong-gate.lfe`
15. `src/wolong-exec.lfe`
16. `test/wolong_plan_SUITE.lfe`
17. `test/wolong_pipeline_SUITE.lfe`
18. `test/wolong_exec_SUITE.lfe`
19. `test/fixtures/gate-contract-substrate/`
20. `test/fixtures/exec-runner/`

Also load the collaboration framework and Erlang/OTP guidance for supervision,
processes, and Common Test. Ledger discipline applies: update `ledger.md` as
you work with attested evidence, and do not leave all evidence for the final
close.

## Mission

Add OTP supervision around planning dispatches.

At close, public `wolong:plan/3` should run one planning request through a
supervised dispatch boundary while preserving the Slice03 public contract:

```lfe
#(ok Plan)
#(unsolvable Detail)
#(error #(Gate Reason Detail))
```

Failures introduced by the dispatch boundary itself must also be typed and
matchable, for example:

```lfe
#(error #(dispatch Reason Detail))
```

Use the exact shape that best fits the implementation, but ledger it and test
it. Do not let dispatch-worker exits leak as raw caller exits unless you have
explicitly ledgered and justified that behavior; the project wants typed API
results.

## Required Shape

Prefer a narrow supervision layer:

- `wolong-sup` owns a dispatch supervisor child;
- the dispatch supervisor starts one supervised dispatch worker per
  `wolong:plan/3` request;
- the worker owns exactly one planning request and delegates to
  `wolong-pipeline:run/2`;
- `wolong:plan/3` routes through this dispatch boundary, then adapts results
  to the Slice03 public shape;
- `wolong:plan/2` remains a convenience wrapper over `plan/3`;
- `wolong:validate/2` remains parser-only.

Do not duplicate parser/grounder/engine argv construction, status parsing,
erlexec calls, workspace creation, cleanup, or public plan adaptation inside
the dispatch supervisor.

## Worker Lifecycle

Be explicit about the one-shot worker lifecycle and restart policy.

A planning dispatch is not a permanent service. If you use `temporary`
workers, prove a crashed worker is isolated and that the supervisor/app remain
usable for later dispatches. If you use `transient` restart, prove it does not
produce duplicate public results or duplicate artifact ownership. If you
choose a different approach, explain it in the ledger and close report.

Do not block a shared long-lived server with planning work. One slow or hung
engine must not serialize unrelated dispatches. The thing that waits on
erlexec should be the per-dispatch worker or an equivalent isolated process.

## Tests and Fixtures

Use Common Test for this slice. Add a suite such as:

```text
test/wolong_dispatch_SUITE.lfe
```

Required cases:

- app start shows `wolong-sup`, erlexec, and the dispatch supervisor alive;
- solved minimal through `wolong:plan/3` still returns `#(ok Plan)` with
  durable payload and `verification-boundary.separate-verifier=not-run`;
- valid no-plan through `wolong:plan/3` still returns `#(unsolvable Detail)`;
- parser, grounder, engine, binary, config, and workspace failures remain
  typed public errors;
- public engine timeout returns a typed engine timeout and preserves useful
  bounded details;
- timeout of a TERM-resistant engine fixture leaves no surviving OS process
  and a later solved dispatch succeeds;
- synthetic dispatch-worker crash is isolated and typed;
- concurrent dispatches use distinct workers and distinct workspace paths;
- concurrent success plus concurrent failure/timeout do not corrupt each
  other;
- terminal dispatches leave no live dispatch worker children;
- `wolong:validate/2` remains parser-only.

Prefer per-test unique base directories. Do not reuse fixed `/tmp` paths when
concurrency or flake risk is involved.

Remote CI must not depend on `../chengdu`. If you run real local evidence
against sibling `../chengdu/bin/pandapi-*`, record it separately and do not
claim CI ran real Chengdu binaries.

## Scope Guard

Stay inside slice04:

- no public `wolong:verify`;
- no release downloader, checksum verifier, or provisioning;
- no planner pool, global queue, back-pressure API, or distributed Erlang;
- no legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback;
- no diagnostic-prose classifier;
- no action-sequence parser;
- no decomposition-tree parser;
- no broad public options redesign.

Keep `verification-boundary.separate-verifier=not-run` load-bearing for
Slice05. Supervision is not verification.

## Verification Before Close

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

Also perform one tamper cycle. Break a meaningful new supervision invariant:
for example route `wolong:plan/3` directly back to `wolong-pipeline:run/2`,
reuse a workspace across concurrent dispatches, skip timeout cleanup, or leak
a worker after completion. Show the owning CT gate fails nonzero, revert the
tamper, and show it passes again.

If CI is available, record the linked green run on both Ubuntu and macOS. If
CI uses fixture executables instead of real Chengdu binaries, say that
directly in the ledger and close report.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all 18 ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did slice04 deliver the `dispatch-supervision` line in `arc-plan.md`;
   - how the worker lifecycle/restart-policy choice affects the arc ledger;
   - what Slice05 must know about preserving the verification boundary;
   - whether any project-plan wording around W4 needs clarification;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Update `../arc-plan.md` if supervision findings change later slice scope,
   sequencing, or the arc ledger.
5. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
