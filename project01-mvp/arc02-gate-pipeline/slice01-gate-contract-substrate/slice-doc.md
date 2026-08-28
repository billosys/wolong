# Slice 01 (wolong arc02): gate-contract-substrate

> Open-set plan-of-record for `slice01-gate-contract-substrate`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened 2026-08-14.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Build the shared gate-contract substrate that the rest of arc02 will use for
parser, grounder, and engine dispatch.

At slice close, Wolong should have one place to resolve configured
`pandapi-*` binaries, one place to parse final `PANDAPI_STATUS` records, and
one gate-oriented mapper that can classify the current managed-process
outcomes for parser, grounder, and engine without scraping diagnostic prose.
The slice should also prove the current supervised parse -> ground -> solve
argv shape through a one-shot internal/fixture path, but it must not expose
`wolong:plan` yet and must not build the full dispatch lifecycle.

## 2. Context From Arc01

- Arc01 closed with `wolong-exec:run/3`, which provides argv-list execution,
  stdout/stderr separation, output caps, process-group timeout cleanup,
  typed timeout/exec errors, no-zombie evidence, and recovery after failure.
- Arc01 added `wolong-binaries:parser/0` plus generic `resolve/1`, but only
  parser resolution is proven by tests.
- Arc01 added `wolong:validate/2`, whose parser-only implementation currently
  contains the first `PANDAPI_STATUS` parser inline. Arc02 should not duplicate
  that parser per gate.
- Arc01 established app-env-only binary lookup for 0.1.0. Keep that default
  unless the operator explicitly changes it.
- Arc01 established that real Chengdu binaries are not available in remote CI
  yet. Checked-in fixture executables may prove Wolong's side of the contract,
  but real-binary evidence must be recorded separately.

## 3. Current Contract Sources

Use current Chengdu docs and local binaries as primary sources:

```text
../chengdu/docs/reference/cli.md
../chengdu/docs/managed-process.md
../chengdu/fixtures/contract/parser-contract-records.md
../chengdu/fixtures/contract/grounder-contract-records.md
../chengdu/fixtures/contract/engine-contract-records.md
../chengdu/fixtures/contract/pipeline-contract-records.md
../chengdu/bin/pandapi-parser
../chengdu/bin/pandapi-grounder
../chengdu/bin/pandapi-engine
```

The expected supported supervised command shapes are:

```text
pandapi-parser  --supervised --status=stderr --output OUT.htn DOMAIN.hddl PROBLEM.hddl
pandapi-grounder --supervised --status=stderr --output OUT.sas INPUT.htn
pandapi-engine  --supervised --status=stderr --output OUT.plan INPUT.sas
```

Programmatic classification comes from the process exit code and final
`PANDAPI_STATUS` fields, not diagnostic prose.

## 4. In Scope

- Extend or wrap `wolong-binaries` so parser, grounder, and engine can be
  resolved from the configured `binaries` map with typed missing,
  non-executable, and stat-failed errors.
- Extract the inline status parsing currently in `src/wolong.lfe` into a
  reusable module or gate abstraction. Preserve unknown status fields rather
  than dropping them.
- Add a shared gate result mapper for current managed statuses:
  `ok`, `domain_no_plan`, `cli_usage_error`, `input_unavailable`,
  `output_unavailable`, `input_invalid`, policy-surface statuses,
  `timeout`, `resource_limit`, `interrupted`, `dependency_failure`,
  `child_process_failure`, `internal_error`, and signal/no-status cases where
  Wolong observes them.
- Keep parser validation behavior compatible with the arc01 public
  `wolong:validate/2` tests while moving shared logic out of the public module.
- Add gate argv builders or equivalent small helpers for supervised,
  file-backed parser, grounder, and engine calls.
- Add Common Test coverage for binary resolution, status parsing/mapping, and
  a one-shot parse -> ground -> solve fixture flow.
- Vendor or create Wolong-owned fixtures needed for this slice under
  `test/fixtures/gate-contract-substrate/`.
- Survey the real sibling Chengdu binaries locally where available and record
  the real parser/grounder/engine status behavior separately from CI fixture
  evidence.

## 5. Out of Scope

- No public `wolong:plan` or `wolong:verify` yet.
- No `gen_statem`, dispatch worker, dispatch supervisor, or concurrency model.
- No full scratch-dir lifecycle beyond temporary artifact paths needed to
  exercise a one-shot fixture flow.
- No Chengdu release download, checksum verification, or provisioning.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No diagnostic-prose classification.
- No ltest/rebar3_lfe remediation beyond preserving the existing EUnit
  autoexport workaround.
- No broad README/API promise changes beyond any necessary internal-doc note
  that arc02 is open.

## 6. Verification Approach

Primary coverage is Common Test:

```bash
rebar3 as test ct
```

EUnit/ltest may remain for pure config tests. Do not put OS-process,
application lifecycle, or binary integration behavior into EUnit.

CDC should independently re-run:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

CDC should also inspect source for:

- no duplicate `PANDAPI_STATUS` parser copies;
- no shell command concatenation;
- no public `plan`/`verify` API yet;
- no legacy binary names;
- no classification from diagnostic prose;
- parser validation tests still green after the shared extraction.

## 7. Exit Criteria

- `wolong-binaries` or an equivalent locator resolves parser, grounder, and
  engine from app env only, with typed errors for missing and non-executable
  binaries.
- Final `PANDAPI_STATUS` parsing is shared and tested; parser validation no
  longer owns a private parser copy.
- Gate status mapping covers the current Chengdu managed-process status/exit
  vocabulary and preserves status fields in the returned detail.
- Parser validation remains green and keeps its public result shapes.
- A CT fixture proves Wolong can invoke parser, grounder, and engine in the
  supervised file-backed argv shape, with stdout/stderr ownership and final
  status assertions.
- Real sibling Chengdu binary evidence is surveyed locally if binaries are
  available, but CI fixture evidence is labelled honestly.
- The slice closes without adding public `wolong:plan`/`wolong:verify`, full
  dispatch supervision, release provisioning, or legacy binary fallbacks.
