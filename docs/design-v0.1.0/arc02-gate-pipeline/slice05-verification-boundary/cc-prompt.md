# CC prompt: wolong arc02 / slice05 verification-boundary

You are CC implementing `slice05-verification-boundary` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read First

1. `AGENTS.md`
2. `/Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md`
3. `docs/design-v0.1.0/project-plan.md`
4. `docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md`
5. `docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/closing-report.md`
6. `docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/cdc-verification.md`
7. `docs/design-v0.1.0/arc02-gate-pipeline/slice04-dispatch-supervision/closing-report.md`
8. `docs/design-v0.1.0/arc02-gate-pipeline/slice04-dispatch-supervision/cdc-verification.md`
9. `docs/design-v0.1.0/arc02-gate-pipeline/slice05-verification-boundary/slice-doc.md`
10. `docs/design-v0.1.0/arc02-gate-pipeline/slice05-verification-boundary/ledger.md`
11. `README.md`
12. `src/wolong.lfe`
13. `test/wolong_plan_SUITE.lfe`
14. `test/wolong_dispatch_SUITE.lfe`
15. `test/wolong_parser_SUITE.lfe`
16. `../chengdu/docs/reference/cli.md`
17. `../chengdu/docs/managed-process.md`
18. `../chengdu/bin/`

Also load the collaboration framework. Load Erlang/OTP guidance if you touch
LFE code or tests. Ledger discipline applies: update `ledger.md` as you work
with attested evidence, and do not leave all evidence for the final close.

## Mission

Resolve the public verification boundary honestly.

The current expected path is deferral, not implementation:

- keep public `wolong:verify` out of 0.1.0;
- keep solved plans explicit that no separate verifier ran;
- update README/project/arc wording so no user or future slice reads
  verification as already implemented;
- preserve existing public `plan` and `validate` behavior.

If you find a currently supported Chengdu verifier contract in the 0.3.0
pre-release docs or binaries, pause and report before implementing it. Do not
quietly expand this slice into a verifier implementation.

## Required Source Survey

Before editing Wolong, inspect and record:

```bash
ls -al ../chengdu/bin
sed -n '1,260p' ../chengdu/docs/reference/cli.md
sed -n '1,260p' ../chengdu/docs/managed-process.md
```

Run local binary help/version probes if they are usable:

```bash
../chengdu/bin/pandapi-parser --help
../chengdu/bin/pandapi-grounder --help
../chengdu/bin/pandapi-engine --help
../chengdu/bin/pandapi-parser --version
../chengdu/bin/pandapi-grounder --version
../chengdu/bin/pandapi-engine --version
```

The binaries are named `pandapi-parser`, `pandapi-grounder`, and
`pandapi-engine`. Do not use old `pandaPI*` binary names.

## Implementation Guidance

Update documentation to match the code that now exists:

- `README.md` should describe the current supported chain as
  parser -> grounder -> engine, not the old five-gate sequence.
- `README.md` should state that `wolong:validate/2`, `wolong:plan/2`, and
  `wolong:plan/3` exist.
- `README.md` should state that `wolong:verify` is deferred until a supported
  verifier contract exists.
- `README.md` should explain that solved plan results carry explicit
  verification-boundary metadata such as `separate-verifier=not-run`.
- Dev setup should use current `pandapi-*` names and make clear that Arc03
  owns release provisioning.
- `project-plan.md` should supersede or qualify old DoD wording that implies
  implemented `wolong:verify`, action-sequence parsing, or decomposition-tree
  parsing for 0.1.0.
- `arc-plan.md` should resolve OQ1 and record the slice05 version-history
  update.

Do not silently delete historical five-gate context. Keep it only as
historical/inherited context, and state the current supported 0.1.0 boundary
plainly.

## Code and Test Boundaries

Prefer a documentation and test-hardening slice. If code changes are needed,
keep them narrow:

- preserve `wolong:plan/2` and `wolong:plan/3`;
- preserve parser-only `wolong:validate/2`;
- preserve `#(ok Plan)`, `#(unsolvable Detail)`, and typed error shapes;
- preserve `verification-boundary.separate-verifier=not-run`;
- do not move pipeline/gate/exec/workspace/dispatch ownership.

Use Common Test for runtime assertions if you add tests. Existing suites
already assert key verification-boundary fields; tighten them only if this
slice needs extra proving pressure.

Formatter note: `rebar3 lfe format` exists, but the current tree is not
formatter-normalized. Do not run an in-place repo-wide format as part of this
slice. Use `--check`, `--dry-run`, or `--path` only when useful, and keep any
formatting churn explicitly owned.

## Scope Guard

Stay inside slice05:

- no public `wolong:verify` unless the operator rescope is explicit;
- no separate-verifier claim;
- no action-sequence parser;
- no decomposition-tree parser;
- no plan-format parser beyond existing durable payload capture;
- no diagnostic-prose classifier;
- no release downloader, checksum verifier, binary provisioning, or hex.pm
  packaging;
- no legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback;
- no planner pool, queue, back-pressure API, or distributed Erlang;
- no broad public options redesign.

## Verification Before Close

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

Run the ledger's targeted greps for README/docs/API scope. Be careful with
shell quoting when grep patterns contain backticks or parentheses; prefer
single-quoted patterns.

Perform one tamper cycle that proves this slice's protection is meaningful.
Good tamper choices:

- change `separate-verifier` from `not-run` to another value and show the
  owning CT assertion fails;
- add a dummy public `verify` export/definition and show the scope grep fails;
- reintroduce the stale README five-gate current-surface claim and show the
  README grep fails.

Revert the tamper and rerun the owning check.

If CI is available, record the linked green run on both Ubuntu and macOS. CI
uses Wolong-owned fixtures and should not depend on `../chengdu`.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all 16 ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did slice05 deliver the `verification-boundary` line in `arc-plan.md`;
   - how OQ1 was resolved;
   - whether Arc02 is ready for arc close after CDC verification;
   - what Arc03 must know about provisioning/release-binary evidence;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Update `../arc-plan.md` and `../../project-plan.md` version histories for
   any plan wording changes.
5. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
