# CDC verification: wolong arc01 / slice03 parser-validate

> Independent verification by CDC on 2026-08-14. CC close commits:
> `8bccdd1c9ef9f780368653ea4e167c62df7deb99` and
> `8187df60012839ea2f5e93248195426d01907de4`.

## Verdict

CDC accepts slice03 as closed.

Rows opened: 12. Rows addressed by CC: 12. Rows independently reproduced or
reconciled by CDC: 12. Deferred: 0. No-op: 0. Silent drops: 0.

No blocking findings.

## Evidence Reproduced

CDC inspected the implementation and close artifacts:

- `src/wolong.lfe`
- `src/wolong-binaries.lfe`
- `test/wolong_parser_SUITE.lfe`
- `test/fixtures/parser-validate/pandapi-parser-fixture.sh`
- `docs/design-v0.1.0/arc01-exec-substrate/slice03-parser-validate/ledger.md`
- `docs/design-v0.1.0/arc01-exec-substrate/slice03-parser-validate/closing-report.md`

Local gates reproduced:

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 9 tests, 0 failures, exit 0
rebar3 as test ct     # wolong_exec_SUITE: 10; wolong_parser_SUITE: 6; all 16 passed, exit 0
rebar3 xref           # exit 0
rebar3 dialyzer       # exit 0
git diff --check      # exit 0
```

CDC also reproduced the real parser contract directly against
`../chengdu/bin/pandapi-parser`:

```text
valid            exit=0  stdout_bytes=0 artifact_bytes=2444 status=ok
missing domain   exit=20 stdout_bytes=0 artifact_bytes=0    status=input_unavailable
broken syntax    exit=22 stdout_bytes=0 artifact_bytes=0    status=input_invalid
broken reference exit=22 stdout_bytes=0 artifact_bytes=0    status=input_invalid
```

Then CDC exercised `wolong:validate/2` against the same real sibling binary
with app env configured to `../chengdu/bin/pandapi-parser`. Results matched
the slice contract:

- valid minimal pair returned `#(ok Detail)` with `status=ok`,
  `component=parser`, `exit-code=0`, empty stdout, and a 2444-byte artifact;
- missing domain returned `#(error #(missing-file Detail))` with
  `status=input_unavailable`, `exit-code=20`, and `path-role=domain`;
- broken syntax returned `#(error #(invalid-hddl Detail))` with
  `status=input_invalid`, `exit-code=22`, and
  `invalid-kind=undistinguished`;
- broken reference returned the same typed invalid-HDDL shape and
  `invalid-kind=undistinguished`.

Remote CI was reconciled through the GitHub Actions API:

- Run `31824639175`, head SHA
  `8bccdd1c9ef9f780368653ea4e167c62df7deb99`, completed with conclusion
  `success`; both jobs `build (ubuntu-22.04)` and `build (macos-15)` passed
  compile, EUnit, CT, xref, and dialyzer.
- Run `31824981332`, head SHA
  `8187df60012839ea2f5e93248195426d01907de4`, completed with conclusion
  `success`; both jobs `build (ubuntu-22.04)` and `build (macos-15)` passed
  compile, EUnit, CT, xref, and dialyzer.

## Row Walk

- **R-1:** Reproduced. `wolong-binaries` resolves configured app env only; no
  PATH/env fallback exists. `arc-plan.md` now records OQ3 as resolved.
- **R-2:** Reproduced. Chengdu CLI docs, `--help`/`--version`, direct
  supervised parser runs, and Wolong API runs all agree on the current
  `pandapi-parser` contract.
- **R-3:** Reproduced. Locator returns typed `binary missing` and
  `binary non-executable` errors; CT covers both.
- **R-4:** Reproduced. `wolong` exports only `validate/2`; scope grep found no
  `plan`, `verify`, grounder/engine invocation, or `gen_statem` runtime path.
- **R-5:** Reproduced. Parser invocation uses `wolong-exec:run/3` with argv
  entries `--supervised`, `--status=stderr`, `--output`, output path, domain,
  and problem; no parser shell string is constructed.
- **R-6:** Reproduced. Vendored minimal fixtures and real Chengdu fixtures map
  to typed success with status fields and artifact metadata.
- **R-7:** Reproduced. Missing domain maps to typed `missing-file` from
  `input_unavailable`/20.
- **R-8:** Reproduced with corrected granularity. Broken syntax maps to typed
  `invalid-hddl`, but the subtype is `undistinguished` because Chengdu exposes
  only `input_invalid`/22.
- **R-9:** Reproduced with corrected granularity. Broken reference maps to the
  same typed `invalid-hddl`/`undistinguished` shape. CC correctly bubbled up
  the absence of a machine-readable syntax-vs-semantic distinction.
- **R-10:** Reconciled. Local EUnit/CT gates and both GitHub matrix jobs are
  green. CI uses the checked-in parser fixture executable, not the real
  sibling Chengdu binary, and the close report says so.
- **R-11:** Reproduced. CDC changed the invalid-HDDL expected `exit-code`
  from `22` to `23`; `rebar3 as test ct` exited 1 with failures in
  `broken_syntax_maps_invalid_hddl` and
  `broken_reference_maps_invalid_hddl`, each `{expected,23,actual,22}`.
  Restoring the assertion to `22` returned CT to all 16 tests passed.
- **R-12:** Reproduced. Runtime scope grep over `src test` found no grounder,
  engine, `plan`, `verify`, `gen_statem`, downloader, release provisioner, or
  legacy `pandaPIparser` fallback.

## Bubble-up Check

Slice03 delivered the assigned arc piece: config-backed binary lookup,
`wolong:validate/2`, supervised `pandapi-parser` execution through
`wolong-exec:run/3`, typed parser-result mapping, vendored fixtures, CT
coverage, local real-parser evidence, and CI fixture coverage.

The silent-drop diff is honest. The only material gap against the original
arc A3 wording is not a Wolong implementation drop: current Chengdu
`pandapi-parser` does not expose a machine-readable syntax-vs-reference
invalid-HDDL subtype. Wolong preserves that truth as
`invalid-kind=undistinguished`.

CDC updated `../arc-plan.md` before planning the next arc/slice:

- OQ3 is now resolved as app-env-only for 0.1.0.
- A3 is corrected to require typed invalid-HDDL classification with
  `invalid-kind=undistinguished` unless Chengdu adds a stable subtype field.
- Version history entry v1.4 records the slice03 finding and its arc02
  consequence.

## What Worked

- The checked-in parser fixture gave CI a deterministic contract test without
  pretending that the sibling Chengdu checkout exists on GitHub runners.
- The real-parser evidence stayed separate from CI evidence.
- The slice kept the public facade narrow: `wolong:validate/2` only, with
  no planner pipeline drift.

## Residual Risk

Arc02 should treat `invalid-kind=undistinguished` as the supported parser
granularity until Chengdu emits a stable machine field for syntax-vs-semantic
invalid input. Real Chengdu binaries still do not run in CI; that remains
arc03 provisioning territory.
