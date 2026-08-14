# CC prompt: wolong arc01 / slice03 parser-validate

You are CC implementing `slice03-parser-validate` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read first

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc01-exec-substrate/arc-plan.md`
4. `docs/design-v0.1.0/arc01-exec-substrate/slice01-app-skeleton/closing-report.md`
5. `docs/design-v0.1.0/arc01-exec-substrate/slice01-app-skeleton/cdc-verification.md`
6. `docs/design-v0.1.0/arc01-exec-substrate/slice02-exec-runner/closing-report.md`
7. `docs/design-v0.1.0/arc01-exec-substrate/slice02-exec-runner/cdc-verification.md`
8. `docs/design-v0.1.0/arc01-exec-substrate/slice03-parser-validate/slice-doc.md`
9. `docs/design-v0.1.0/arc01-exec-substrate/slice03-parser-validate/ledger.md`
10. `../chengdu/docs/reference/cli.md`
11. `../chengdu/docs/managed-process.md`
12. `src/wolong-config.lfe`
13. `src/wolong-exec.lfe`
14. `config/sys.config`

Also load the collaboration framework and the Erlang/LFE guidance used by this
repo. Ledger discipline applies: update the ledger as you work, with
attested evidence; do not leave evidence until the final close.

## Mission

Build the first real pandaPI integration: parser validation only.

At close, `(wolong:validate domain-path problem-path)` should locate the
configured current pre-release `pandapi-parser`, run it via
`wolong-exec:run/3`, and return typed public results for:

- valid HDDL pair;
- missing input file;
- broken syntax;
- broken reference or undeclared predicate.

This slice is the composition proof for config + binary locator + runner +
parser result mapping. It is not the planning pipeline.

## Critical First Step

Before implementing the mapper, inspect and record the actual current Chengdu
pre-release parser command contract available in the working environment:

- argv shape;
- whether it needs or writes an output/artifact path;
- working-directory assumptions;
- exit statuses for valid, missing-file, syntax-error, and broken-reference
  cases;
- which stream carries diagnostics.

Use the sibling Chengdu checkout binaries until the 0.3.0 release exists:

```text
../chengdu/bin/pandapi-parser
../chengdu/bin/pandapi-grounder
../chengdu/bin/pandapi-engine
```

Only `pandapi-parser` is in scope for this slice. Older `pandaPIparser`
references are legacy context and must not be used for this implementation.
Use `../chengdu/docs/reference/cli.md` and
`../chengdu/docs/managed-process.md` as primary contract sources.

The documented supervised parser shape is:

```text
pandapi-parser --supervised --status=stderr --output OUT.htn DOMAIN.hddl PROBLEM.hddl
```

Classify from process exit code and the final `PANDAPI_STATUS` fields, not
from diagnostic prose. The current docs define parser success as
`status=ok`/exit `0`, missing input as `status=input_unavailable`/exit `20`,
unavailable output as `status=output_unavailable`/exit `21`, and invalid input
as `status=input_invalid`/exit `22`.

If your survey of `../chengdu/bin/pandapi-parser` does not give enough
information to map the four required outcomes, stop and report before adding
a downloader, assuming 0.3.0 release artifacts, or inventing a compatibility
layer.

## Required Shape

Add a binary locator, probably `src/wolong-binaries.lfe`, that:

- reads the app config through `wolong-config:validate/0`;
- resolves the `parser` binary from the configured `binaries` map;
- preserves the OQ3 default: app env only for 0.1.0 unless the operator
  explicitly changes it;
- checks existence and executable permission before a run;
- returns typed errors for missing/non-executable binaries.

Add `src/wolong.lfe` exposing:

```lfe
(wolong:validate domain-path problem-path)
```

Use the configured `parse` timeout and the existing runner output cap policy.
Invoke the parser through:

```lfe
(wolong-exec:run parser-binary argv opts)
```

Do not concatenate a shell command string.

The argv should include the supervised CLI flags documented by Chengdu:
`--supervised`, `--status=stderr`, `--output`, an output `.htn` path, domain
path, and problem path.

## Fixtures and Tests

Use Common Test for OS/binary integration. A good target is a separate suite
such as:

```text
test/wolong_parser_SUITE.lfe
```

Vendor the HDDL fixtures needed by this slice under:

```text
test/fixtures/parser-validate/
```

You may use the Chengdu fixture corpus as the source, but wolong tests must not
depend on `/Users/oubiwann/lab/billosys/chengdu` at runtime.

If remote CI cannot run the sibling Chengdu `pandapi-parser`, use a checked-in
parser fixture executable to prove wolong's locator, runner invocation, and
mapping logic in CI. Record that honestly. Do not claim CI performed a real
Chengdu parser run unless it actually did. Separately record any real-parser
evidence you can obtain locally from `../chengdu/bin/pandapi-parser`.

EUnit/ltest may cover unit-pure mapping helpers or locator shape checks, but
do not put process/app/binary integration coverage in EUnit.

## Scope Guard

Stay inside slice03:

- no `wolong:plan`;
- no `wolong:verify`;
- no grounder or engine invocation;
- no gate pipeline or `gen_statem`;
- no scratch-dir dispatch lifecycle beyond whatever the parser command itself
  requires for this one command;
- no Chengdu release downloader/provisioning;
- no assumption that Chengdu 0.3.0 release artifacts exist;
- no fallback to legacy `pandaPIparser` names;
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

Also perform one tamper cycle: break a meaningful parser result-mapping or
locator assertion, show the owning test gate fails with nonzero exit, revert
the tamper, and show the suite passes again.

If CI is available, record the linked green run on both Ubuntu and macOS. If
CI uses a fixture executable instead of real `pandapi-parser`, say that
directly in the ledger and close report.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did slice03 deliver the slice breakdown line in `arc-plan.md`;
   - did the current `pandapi-parser` contract match the slice assumption;
   - what did implementation reveal that arc02 must account for;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
