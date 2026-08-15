# Slice 03 (wolong arc02): plan-api

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at
> slice start, 2026-08-15. Closer: CC. Verifier: CDC. Evidence must name the
> commit and include command output or direct artifact pointers; CDC upgrades
> accepted `done` evidence from attested to reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| PA-1 | Public `wolong:plan/3` is exported from `src/wolong.lfe`; optional `plan/2`, if added, is only a default wrapper over `plan/3`. | `rg -n "defun plan" src/wolong.lfe`; inspect export form; `rebar3 compile`; CT public API calls | serious | arc-plan slice03 | open | | Do not add public `wolong:verify`. |
| PA-2 | `wolong:plan/3` validates `DomainPath`, `ProblemPath`, and `Opts` before dispatch; malformed path/opts errors are typed and do not invoke parser/grounder/engine fixtures. | CT invalid argument/options cases with fixture invocation markers absent; inspect adapter code | correctness | public API boundary | open | | Unsupported opts must not be silently ignored. |
| PA-3 | The public adapter delegates to `wolong-pipeline:run/2` or a narrow pipeline helper and does not re-implement argv building, status parsing, erlexec calls, workspace creation, or cleanup. | `rg -n "wolong-pipeline" src/wolong.lfe`; run separate absence greps in `src/wolong.lfe` for `wolong-exec`, `parser-argv`, `grounder-argv`, `engine-argv`, `make_dir`, and `del_dir_r`; source review | serious | slice02 substrate | open | | Public API should be an adapter, not a second pipeline. |
| PA-4 | OQ5 is dispositioned: the first public solved-plan term is defined in code/tests/closing report, including which fields are committed now and which action/decomposition fields are deferred. | inspect `../arc-plan.md` version history and slice close bubble-up; inspect CT assertions for returned plan fields | serious | arc-plan OQ5 | open | | If action parsing is deferred, name the re-entry condition. |
| PA-5 | Solved fixture returns public `#(ok Plan)` with outcome `solved`, structured plan/artifact/provenance fields, and no diagnostic-prose-derived classification. | `rebar3 as test ct`; inspect `wolong_plan_SUITE`; grep for prose parsing | serious | project W1/W3 | open | | The `Plan` term must be matchable. |
| PA-6 | Solved public result contains a durable plan payload or equivalent public plan value, not only an artifact path that may be deleted. | CT solved with `keep-artifacts=false`; assert plan payload still present/nonempty after dispatch workspace removal | serious | public API usability; slice02 cleanup | open | | This is load-bearing for `workdir.keep-artifacts=false`. |
| PA-7 | Solved public result carries explicit verification-boundary metadata and does not imply a separate verifier ran. | CT asserts verification field; inspect close bubble-up and any public text added | serious | project invariant; slice05 dependency | open | | Slice05 owns public `wolong:verify`. |
| PA-8 | Valid no-plan fixture returns public `#(unsolvable Detail)` from engine `domain_no_plan`/exit `2`, preserving parser/grounder/engine provenance and no required plan artifact. | `rebar3 as test ct`; inspect no-plan assertions and returned shape | serious | project invariant; arc02 A3 | open | | Must not leak internal `domain-no-plan` at public API. |
| PA-9 | Parser failure returns typed public `#(error #(parser Reason Detail))` and short-circuits grounder/engine. | CT missing-domain/parser-invalid case; assert markers/artifacts for downstream gates absent | correctness | arc02 A4 | open | | Preserve structured reason from gate/pipeline. |
| PA-10 | Grounder failure returns typed public `#(error #(grounder Reason Detail))` and short-circuits engine. | CT `grounder-invalid` fixture case; assert engine marker/artifact absent | correctness | arc02 A4 | open | | Reuse slice02 fixture trigger. |
| PA-11 | Engine failure returns typed public `#(error #(engine Reason Detail))`, distinct from valid `#(unsolvable ...)`. | CT `engine-invalid` fixture case; inspect result shape | correctness | arc02 A4 | open | | Distinguish invalid input/status failure from no-plan. |
| PA-12 | Workspace/config/binary failures return typed public errors with structured detail and do not collapse into generic `#(error Reason)`. | CT unavailable workdir and missing/non-executable binary config cases; inspect error shape | correctness | public API boundary | open | | Existing config validation shape may be adapted, but must be matchable. |
| PA-13 | Existing `wolong:validate/2` behavior remains compatible with prior tests and parser-specific error adaptations. | `rebar3 as test eunit`; `rebar3 as test ct`; inspect `src/wolong.lfe` diff | serious | backwards compatibility | open | | Do not route validate through the full plan pipeline. |
| PA-14 | Scope fence holds: no public `wolong:verify`, no `gen_statem`, no dispatch supervisor/concurrency model, no release downloader/provisioner, no legacy `pandaPI*` runtime fallback, and no diagnostic-prose classifier. | run separate `rg -n` checks for `defun verify`, `gen_statem`, `dispatch worker`, `dispatch supervisor`, `download`, `provision`, `pandaPIparser`, `pandaPIgrounder`, `pandaPIengine`, `diagnostic prose`, and `grep.*stderr` in `src`, `test`, and this slice directory | serious | slice-doc section 4 | open | | Planning prose may mention forbidden terms as scope fence only. |
| PA-15 | Local gates pass: `rebar3 compile`, `rebar3 as test eunit`, `rebar3 as test ct`, `rebar3 xref`, and `rebar3 dialyzer`; CI is green on Ubuntu and macOS. | run listed commands; record GitHub Actions run URL and matrix result | correctness | repo workflow | open | | If Dialyzer/tooling becomes fragile, stop and report before weakening CI. |
| PA-16 | A tamper cycle proves public plan API tests are meaningful: break no-plan translation, plan payload retention, or gate-error mapping; observe the owning CT gate fail nonzero; revert and observe it pass. | local tamper transcript in ledger/closing report | correctness | ledger discipline | open | | Target new public API behavior, not only old pipeline tests. |

## What Worked

_(At slice close. Patterns that made the slice close cleanly.)_

## Closure

Closed at commit <SHA> on <date>. Verified by: <name/session>.
Rows: 16. Done: <n>. Deferred: <n>. No-op: <n>.
