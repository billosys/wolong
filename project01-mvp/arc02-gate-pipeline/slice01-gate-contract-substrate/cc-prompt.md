# CC prompt: wolong arc02 / slice01 gate-contract-substrate

You are CC implementing `slice01-gate-contract-substrate` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read first

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc01-exec-substrate/closing-report.md`
4. `docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md`
5. `docs/design-v0.1.0/arc02-gate-pipeline/slice01-gate-contract-substrate/slice-doc.md`
6. `docs/design-v0.1.0/arc02-gate-pipeline/slice01-gate-contract-substrate/ledger.md`
7. `../chengdu/docs/reference/cli.md`
8. `../chengdu/docs/managed-process.md`
9. `../chengdu/fixtures/contract/parser-contract-records.md`
10. `../chengdu/fixtures/contract/grounder-contract-records.md`
11. `../chengdu/fixtures/contract/engine-contract-records.md`
12. `../chengdu/fixtures/contract/pipeline-contract-records.md`
13. `src/wolong.lfe`
14. `src/wolong-binaries.lfe`
15. `src/wolong-config.lfe`
16. `src/wolong-exec.lfe`
17. `test/wolong_parser_SUITE.lfe`
18. `rebar.config`

Also load the collaboration framework and Erlang/LFE guidance used by this
repo. Ledger discipline applies: update the ledger as you work, with
attested evidence; do not leave evidence until the final close.

## Mission

Create the shared gate-contract substrate for arc02.

Arc01 proved parser validation as the first real process. Arc02 now needs the
same discipline for parser, grounder, and engine without three copies of the
same status parser or three ad hoc mappers.

At close:

- configured `parser`, `grounder`, and `engine` binaries resolve through app
  env only;
- final `PANDAPI_STATUS` parsing is shared and tested;
- current managed-process statuses map to typed gate/domain results without
  scraping diagnostics;
- parser validation still passes with the same public result shapes;
- a CT fixture proves Wolong can invoke a supervised file-backed
  parse -> ground -> solve chain through `wolong-exec:run/3`;
- no public `wolong:plan` or `wolong:verify` is added yet.

## Critical First Step

Survey the current Chengdu contract before changing the mapper. Use the docs,
fixture records, and the sibling binaries when present:

```text
../chengdu/bin/pandapi-parser
../chengdu/bin/pandapi-grounder
../chengdu/bin/pandapi-engine
```

Expected supervised shapes:

```text
pandapi-parser   --supervised --status=stderr --output OUT.htn DOMAIN.hddl PROBLEM.hddl
pandapi-grounder --supervised --status=stderr --output OUT.sas INPUT.htn
pandapi-engine   --supervised --status=stderr --output OUT.plan INPUT.sas
```

Classify from process exit code and final `PANDAPI_STATUS` fields. Do not
classify from diagnostic prose.

Pay special attention to engine no-plan:

```text
status=domain_no_plan
exit_code=2
```

That is a valid domain result, not malformed input and not generic failure.
The public `#(unsolvable ...)` API lands later, but this slice must not build
a mapper that would make it impossible.

If the current local binaries contradict the docs or do not expose enough
machine data to map a required row, pause and report. Do not invent a
compatibility layer, downloader, or legacy fallback.

## Required Shape

Prefer a small shared module split over a large public `wolong.lfe`:

- a reusable status parser, such as `wolong-status`;
- a gate abstraction or mapper, such as `wolong-gate`;
- extended `wolong-binaries` helpers for `parser/0`, `grounder/0`,
  `engine/0`, and/or `resolve/1`.

Names are suggestions; follow the codebase if a cleaner local shape emerges.
The invariant matters more than the module names: one status parser, shared
gate mapping, typed results, no prose classification.

Keep `wolong:validate/2` compatible. It may delegate to the new gate substrate,
but its public shapes from arc01 must continue to pass:

- `#(ok Detail)` for valid parser input;
- `#(error #(missing-file Detail))`;
- `#(error #(output-unavailable Detail))`;
- `#(error #(invalid-hddl Detail))` with `invalid-kind=undistinguished`;
- typed parser timeout/exec/status errors.

## Fixtures and Tests

Use Common Test for process integration. Add or update a suite for the shared
gate substrate, and keep fixtures under the existing `test/fixtures/` tree,
for example:

```text
test/fixtures/gate-contract-substrate/
```

Remote CI should not require the sibling Chengdu checkout. If you use fixture
executables for parser/grounder/engine, make them strict enough to prove
Wolong's argv shape:

- require `--supervised`;
- require `--status=stderr`;
- require file-backed `--output PATH`;
- emit exactly one final `PANDAPI_STATUS`;
- keep stdout empty for file-backed artifacts;
- write non-empty artifacts on success;
- support an engine no-plan fixture returning exit `2` and
  `status=domain_no_plan`.

Separately record real local evidence from `../chengdu/bin/pandapi-*` if the
binaries are present. Do not claim CI proved real Chengdu binaries unless it
actually did.

## Scope Guard

Stay inside slice01:

- no public `wolong:plan`;
- no public `wolong:verify`;
- no `gen_statem`;
- no dispatch supervisor or concurrent dispatch model;
- no full scratch-dir lifecycle beyond temporary paths needed for this
  one-shot substrate proof;
- no Chengdu release downloader/provisioning;
- no fallback to legacy `pandaPIparser`, `pandaPIgrounder`, or
  `pandaPIengine`;
- no diagnostic-prose classifier;
- no ltest/rebar3_lfe remediation beyond preserving the existing workaround.

## Verification Before Close

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

Also perform one tamper cycle: break a meaningful new gate-contract mapping or
argv assertion, show the owning test gate fails with nonzero exit, revert the
tamper, and show the suite passes again.

If CI is available, record the linked green run on both Ubuntu and macOS. If
CI uses fixture executables instead of real Chengdu binaries, say that
directly in the ledger and close report.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did slice01 deliver the substrate assigned in `arc-plan.md`;
   - did the current `pandapi-*` contract match the arc assumptions;
   - what did implementation reveal that slice02/slice03 must account for;
   - whether OQ1/OQ2/OQ3/OQ4/OQ5 need arc-plan updates now;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
