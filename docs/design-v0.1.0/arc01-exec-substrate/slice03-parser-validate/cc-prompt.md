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
10. `src/wolong-config.lfe`
11. `src/wolong-exec.lfe`
12. `config/sys.config`

Also load the collaboration framework and the Erlang/LFE guidance used by this
repo. Ledger discipline applies: update the ledger as you work, with
attested evidence; do not leave evidence until the final close.

## Mission

Build the first real pandaPI integration: parser validation only.

At close, `(wolong:validate domain-path problem-path)` should locate the
configured raw `pandaPIparser`, run it via `wolong-exec:run/3`, and return
typed public results for:

- valid HDDL pair;
- missing input file;
- broken syntax;
- broken reference or undeclared predicate.

This slice is the composition proof for config + binary locator + runner +
parser result mapping. It is not the planning pipeline.

## Critical First Step

Before implementing the mapper, inspect and record the actual raw
`pandaPIparser` command contract available in the working environment:

- argv shape;
- whether it needs or writes an output/artifact path;
- working-directory assumptions;
- exit statuses for valid, missing-file, syntax-error, and broken-reference
  cases;
- which stream carries diagnostics.

The arc plan currently expects raw `pandaPIparser` and exit-code mapping
roughly `0` success, `2` missing file, and `255` invalid HDDL. If your survey
contradicts that contract, stop and report before switching to Chengdu's
managed `pandapi-parser` wrapper, adding a downloader, or inventing a
compatibility layer.

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

If remote CI cannot run a real `pandaPIparser`, use a checked-in parser fixture
executable to prove wolong's locator, runner invocation, and mapping logic in
CI. Record that honestly. Do not claim CI performed a real pandaPI parser run
unless it actually did. Separately record any real-parser evidence you can
obtain locally.

EUnit/ltest may cover unit-pure mapping helpers or locator shape checks, but
do not put process/app/binary integration coverage in EUnit.

## Scope Guard

Stay inside slice03:

- no `wolong:plan`;
- no `wolong:verify`;
- no grounder or engine invocation;
- no gate pipeline or `gen_statem`;
- no scratch-dir dispatch lifecycle beyond whatever the raw parser itself
  requires for this one command;
- no Chengdu release downloader/provisioning;
- no switch to `pandapi-parser` wrapper without operator approval;
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
CI uses a fixture executable instead of real `pandaPIparser`, say that
directly in the ledger and close report.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did slice03 deliver the slice breakdown line in `arc-plan.md`;
   - did the raw parser contract match the arc assumption;
   - what did implementation reveal that arc02 must account for;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
