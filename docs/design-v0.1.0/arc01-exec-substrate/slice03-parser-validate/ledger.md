# Slice 03 (wolong arc01): parser-validate

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at
> slice start, 2026-08-14. Closer: CC. Verifier: CDC. Evidence must name the
> commit and include command output or direct artifact pointers; CDC upgrades
> accepted `done` evidence from attested to reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| R-1 | Arc-plan OQ3 is dispositioned before implementation relies on binary discovery: app env only remains the 0.1.0 behavior unless the operator explicitly chooses a PATH or env-var fallback. | read `arc-plan.md`; inspect `config/sys.config`; inspect locator implementation for discovery precedence; read slice docs/close note | correctness | arc-plan OQ3 | open | | Do not silently add convenience lookup. |
| R-2 | The raw parser contract is surveyed and recorded: actual argv shape, working-directory/artifact expectations, and exit/status behavior for valid, missing-file, syntax-error, and broken-reference cases. | read implementation notes in this ledger or closing report; inspect CT fixture setup; if real parser is available, run the surveyed command manually or via CT | serious | arc-plan slice03 line; slice-doc section 5 | open | | If raw `pandaPIparser` contradicts the arc contract, pause before switching to `pandapi-parser` or inventing a workaround. |
| R-3 | A binary locator, probably `wolong-binaries`, resolves the configured parser path through `wolong-config:validate/0` and checks existence plus executable permission before a parser run. | `rebar3 compile`; inspect `src/wolong-binaries.lfe` or equivalent; run unit/CT cases for missing and non-executable parser paths | serious | arc-plan slice03 line | open | | Missing/non-executable binary must be typed; no crash, raw string, or erlexec leak. |
| R-4 | The public API `(wolong:validate domain-path problem-path)` exists, is documented by tests, and is limited to parser validation. | `rebar3 compile`; inspect `src/wolong.lfe`; `rg -n "defun validate|defun plan|defun verify|pandaPIgrounder|pandaPIengine|gen_statem" src test` | serious | arc-plan capability statement | open | | No `plan`/`verify`/pipeline behavior in this slice. |
| R-5 | Parser invocation uses `wolong-exec:run/3` with explicit argv data, configured parse timeout, and bounded stdout/stderr; no shell command string is constructed. | inspect parser call site; inspect CT cases; run `rg -n "os:cmd|open_port|/bin/sh|exec:run|wolong-exec:run" src test` | correctness | slice02 contract; slice-doc section 3 | open | | The gate layer maps completed nonzero exits; the runner still reports completed processes as `#(ok Result)`. |
| R-6 | The valid minimal HDDL domain/problem pair is vendored under `test/fixtures/parser-validate/` and maps to a typed success result with parser provenance and any generated-artifact metadata that the raw parser actually provides. | `rebar3 as test ct`; inspect vendored fixtures; inspect assertion shape for success result | serious | arc ledger A3 | open | | Do not depend on `/Users/oubiwann/lab/billosys/chengdu` at test runtime. |
| R-7 | Missing domain/problem input maps to a distinct typed missing-file or input-unavailable result, not a generic exec error. | `rebar3 as test ct`; inspect CT case and mapper clause; compare against surveyed raw parser contract | serious | arc ledger A3 | open | | Exact exit code follows the surveyed raw parser contract unless the operator changes tools. |
| R-8 | Broken syntax maps to a distinct typed invalid-HDDL syntax result. | `rebar3 as test ct`; inspect CT case and mapper clause; compare stdout/stderr evidence if the parser reports details there | serious | arc ledger A3 | open | | Preserve useful parser diagnostics as metadata, but keep the primary result typed. |
| R-9 | Broken reference or undeclared predicate maps to a distinct typed invalid-HDDL semantic result and is not collapsed into the syntax-error case if the parser exposes a distinction. | `rebar3 as test ct`; inspect CT case and mapper clause; compare against fixture/diagnostic evidence | serious | arc ledger A3 | open | | If the raw parser cannot distinguish these, record the limitation and bubble it up before claiming A3 as written. |
| R-10 | Integration coverage is in Common Test; EUnit/ltest is used only for unit-pure mapping or config/locator helpers; CI remains green on Ubuntu and macOS. | `rebar3 as test eunit`; `rebar3 as test ct`; inspect `.github/workflows/build.yml`; record GitHub Actions run URL and matrix result | correctness | slice02 tooling finding; ledger discipline | open | | If CI uses a fixture executable instead of real `pandaPIparser`, say so explicitly. |
| R-11 | The parser-validation suite is falsifiable: a tamper that breaks a meaningful parser mapping or locator assertion fails the owning test gate with nonzero exit, then passes after revert. | local tamper cycle; record failing and passing command summaries | correctness | ledger discipline | open | | Prefer tampering one result tag or exit-code mapping, not a trivial compile break. |
| R-12 | Scope fence holds: no grounder/engine invocation, no `wolong:plan`/`wolong:verify`, no `gen_statem` dispatch, no scratch-dir pipeline, no Chengdu release downloader/provisioner, and no wrapper switch without operator approval. | inspect changed source/test/docs; `rg -n "pandaPIgrounder|pandaPIengine|pandapi-parser|defun plan|defun verify|gen_statem|scratch|download|release" src test docs/design-v0.1.0/arc01-exec-substrate/slice03-parser-validate` | correctness | slice-doc section 4 | open | | Wrapper mentions in docs as a negative scope fence are acceptable; runtime call sites are not. |

## What Worked

To be completed by CC at close.

## Closure

To be completed by CC at close. Do not create `cdc-verification.md`; CDC writes
that after independent reproduction.
