# Slice 03 (wolong arc01): parser-validate - closing report

> Written by CC. Per-row walk against [`ledger.md`](./ledger.md), opened
> with 12 rows on 2026-08-14. CDC verification belongs in
> `cdc-verification.md` after independent reproduction; this report does not
> create that artifact.

## Per-row walk

Rows opened: 12. Rows addressed: 12. Done: 12. Deferred: 0. No-op: 0.
Silent drops: 0.

- **R-1 - OQ3 binary discovery.** Done. OQ3 remains app-env-only for 0.1.0.
  `src/wolong-binaries.lfe` reads `wolong-config:validate/0` and resolves the
  configured `parser` entry only; no PATH or env-var fallback was added.
- **R-2 - current parser contract survey.** Done. The current sibling binary
  is `../chengdu/bin/pandapi-parser`, not legacy `pandaPIparser`. The surveyed
  supervised shape is `pandapi-parser --supervised --status=stderr --output
  OUT.htn DOMAIN.hddl PROBLEM.hddl`. Valid input exits `0` with
  `status=ok`; missing input exits `20` with `status=input_unavailable`;
  output path failure exits `21` with `status=output_unavailable`; syntax and
  broken-reference fixtures both exit `22` with `status=input_invalid`.
  stdout is empty for file-backed supervised runs; stderr carries diagnostics
  plus the final `PANDAPI_STATUS`.
- **R-3 - binary locator.** Done. `wolong-binaries:parser/0` checks the
  configured parser path exists and has an executable mode bit before any run.
  CT covers missing and non-executable parser paths as typed `binary` errors.
- **R-4 - public API.** Done. `src/wolong.lfe` exports only
  `(validate 2)` as the public facade for this slice. CT drives that API for
  valid, missing, syntax-invalid, and reference-invalid inputs.
- **R-5 - parser invocation.** Done. `wolong:validate/2` builds argv data with
  `--supervised`, `--status=stderr`, `--output`, a file-backed `.htn` path,
  domain path, and problem path, then calls `wolong-exec:run/3`. It uses the
  configured `parse` timeout and the slice02 output cap policy of 65536 bytes.
- **R-6 - valid pair.** Done. Minimal HDDL fixtures are vendored under
  `test/fixtures/parser-validate/minimal/`. CT asserts a typed `#(ok Detail)`
  result with `status=ok`, `component=parser`, `exit-code=0`, `artifact=file`,
  empty stdout, and generated artifact metadata.
- **R-7 - missing input.** Done. CT and real-parser evidence both map a
  missing domain path to `#(error #(missing-file Detail))` with
  `status=input_unavailable`, `component=parser`, `exit-code=20`, and
  `path-role=domain`.
- **R-8 - broken syntax.** Done as invalid-HDDL classification. CT and
  real-parser evidence map broken syntax to `#(error #(invalid-hddl Detail))`
  with `status=input_invalid`, `component=parser`, `exit-code=22`, and
  `invalid-kind=undistinguished`.
- **R-9 - broken reference.** Done with limitation recorded. CT and real-parser
  evidence map the undeclared-predicate fixture to the same `invalid-hddl`
  class and status fields as broken syntax. The current parser exposes no
  machine-readable syntax-vs-semantic subtype, even with `--verbose`.
- **R-10 - integration coverage and CI.** Done. Local gates pass: compile,
  EUnit, CT, xref, dialyzer. GitHub Actions run `31824639175` passed on
  Ubuntu and macOS. CI uses the checked-in parser fixture executable, not the
  sibling Chengdu binary; real-parser evidence is local.
- **R-11 - falsifiability.** Done. Tampering the invalid-HDDL expected
  `exit-code` from `22` to `23` made `rebar3 as test ct` exit 1 with two
  parser-suite failures. Reverting the tamper restored all 16 CT tests.
- **R-12 - scope fence.** Done. Scope grep over `src test` found no grounder
  or engine invocation, no `wolong:plan`, no `wolong:verify`, no `gen_statem`,
  no downloader/provisioner, and no legacy `pandaPIparser` fallback.

## Verification

Implementation commit:
`8bccdd1c9ef9f780368653ea4e167c62df7deb99`.

Local gates:

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 9 tests, 0 failures, exit 0
rebar3 as test ct     # wolong_exec_SUITE: 10; wolong_parser_SUITE: 6; all 16 passed, exit 0
rebar3 xref           # exit 0
rebar3 dialyzer       # exit 0
```

Real parser survey and local API evidence used
`../chengdu/bin/pandapi-parser`:

- valid minimal pair: exit `0`, stdout empty, 2444-byte `.htn`, final
  `PANDAPI_STATUS` with `status=ok`, `component=parser`, `exit_code=0`,
  `artifact=file`;
- missing domain: exit `20`, final status `input_unavailable`, `path_role=domain`;
- broken syntax: exit `22`, final status `input_invalid`;
- broken reference: exit `22`, final status `input_invalid`;
- output-unavailable probe: exit `21`, final status `output_unavailable`.

Tamper cycle:

```bash
# Tamper: invalid-HDDL expected exit-code 22 changed to 23.
rebar3 as test ct  # exit 1; 2 failures; expected 23, actual 22

# Revert tamper.
rebar3 as test ct  # all 16 tests passed, exit 0
```

CI evidence:

- Run: `31824639175`
  (`https://github.com/billosys/wolong/actions/runs/31824639175`)
- Head SHA: `8bccdd1c9ef9f780368653ea4e167c62df7deb99`
- Matrix jobs: `build (ubuntu-22.04)` job `94845742832`, success; `build
  (macos-15)` job `94845742768`, success.
- Both jobs passed compile, EUnit, Common Test, xref, and dialyzer.
- CI parser coverage uses
  `test/fixtures/parser-validate/pandapi-parser-fixture.sh`; it does not run
  the sibling Chengdu checkout binary.

## Bubble-up to the arc

**1. Did slice03 deliver the slice breakdown line in `arc-plan.md`?** Yes,
with one contract limitation disclosed. The slice line called for
`wolong_binaries`, config-driven parser lookup, and `(wolong:validate ...)`
through the current pre-release `pandapi-parser`, tested against minimal and
broken fixtures. That composition now exists and passes local and CI gates.

**2. Did the current `pandapi-parser` contract match the slice assumption?**
Mostly. The binary name, supervised argv shape, file-backed output, stdout
emptiness, stderr status stream, and documented exit/status table matched the
prompt and Chengdu docs. The mismatch is granularity: the current parser maps
both broken syntax and undeclared-predicate/reference invalidity to identical
machine fields: `status=input_invalid`, `exit_code=22`,
`class=input_model_error`, `partial_output_policy=discarded`.

**3. What did implementation reveal that arc02 must account for?** Arc02 can
depend on exit/status classification and avoid prose scraping, but it cannot
currently promise syntax-vs-semantic invalid-HDDL subtypes from the parser
alone. If arc02 needs those subtypes, Chengdu must expose a machine field such
as location/rule/error-kind, or wolong must explicitly keep the parser result
as undistinguished invalid input. CI also needs fixture executables until
arc03 provisioning supplies real release binaries to runners.

**4. Scope-as-specified vs. scope-as-delivered.** Delivered: app-env-only
parser lookup, binary existence/executable checks, `wolong:validate/2`,
supervised argv invocation through `wolong-exec:run/3`, status-field parsing,
typed valid/missing/invalid results, vendored HDDL fixtures, CT coverage,
tamper proof, local real-parser evidence, and green CI with a fixture
executable. Deferred: real Chengdu binary execution in CI, release artifact
provisioning, syntax-vs-semantic invalid-HDDL subtype distinction, optional
`cwd`/`env`, and stream-to-file runner capture. Stayed out: grounder, engine,
`plan`, `verify`, `gen_statem`, dispatch lifecycle, downloader/provisioner,
and legacy binary names.

## Closure

Closed against implementation commit
`8bccdd1c9ef9f780368653ea4e167c62df7deb99` on 2026-08-14.
Verified by: CC local session plus GitHub Actions run `31824639175`.
Rows: 12. Done: 12. Deferred: 0. No-op: 0.
