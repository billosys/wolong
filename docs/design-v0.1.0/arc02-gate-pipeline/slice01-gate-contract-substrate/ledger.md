# Slice 01 (wolong arc02): gate-contract-substrate

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at
> slice start, 2026-08-14. Closer: CC. Verifier: CDC. Evidence must name the
> commit and include command output or direct artifact pointers; CDC upgrades
> accepted `done` evidence from attested to reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| G-1 | The current Chengdu managed contract for parser, grounder, engine, and the supervised pipeline is surveyed from docs, fixture contract records, and local `../chengdu/bin/pandapi-*` binaries where available. | read ledger/closing survey; inspect references to `../chengdu/docs/reference/cli.md`, `../chengdu/docs/managed-process.md`, and `../chengdu/fixtures/contract/*`; if local binaries exist, run `--version` plus minimal/no-plan probes | serious | arc02 dependencies; slice-doc section 3 | open | | Record real-binary evidence separately from CI fixture evidence. |
| G-2 | Binary lookup resolves `parser`, `grounder`, and `engine` from the configured app env only, preserving typed missing, non-executable, and stat-failed errors. | `rebar3 compile`; inspect `src/wolong-binaries.lfe`; CT cases for each component and missing/non-executable paths; grep for PATH/env fallback | serious | arc01 OQ3; arc02 slice01 scope | open | | No PATH or environment-variable discovery unless operator changes policy. |
| G-3 | The final `PANDAPI_STATUS` parser is shared outside `src/wolong.lfe`, preserves required and unknown fields, and has tests for valid records, missing records, malformed fields, numeric exit code parsing, and multiple-line stderr. | inspect new shared module; `rg -n "PANDAPI_STATUS|parse-status|status-fields" src test`; run EUnit/CT parser cases | correctness | arc02 OQ2; arc01 parser implementation | open | | Avoid three gate-local parser copies. |
| G-4 | Parser validation continues to return the arc01 public shapes after shared extraction: success, missing file, output unavailable, invalid-HDDL with `invalid-kind=undistinguished`, timeout, and exec errors. | `rebar3 as test ct`; inspect `test/wolong_parser_SUITE.lfe`; direct call to `wolong:validate/2` if needed | serious | regression guard | open | | Do not erode the closed arc01 API while extracting shared logic. |
| G-5 | Shared gate mapping covers current managed statuses and exit families without scraping prose: `ok`, `domain_no_plan`, `cli_usage_error`, `input_unavailable`, `output_unavailable`, `input_invalid`, policy surfaces, timeout/resource/interrupted, dependency/child/internal, signal/no-status, and unmapped status. | inspect mapper clauses/tests; `rg -n "domain_no_plan|cli_usage_error|input_unavailable|output_unavailable|input_invalid|unsupported_feature|legacy_surface|experimental_surface|future_surface|resource_limit|dependency_failure|internal_error|diagnostic" src test` | correctness | Chengdu managed-process docs; project W3 | open | | `domain_no_plan` must be success-shaped for engine planning, not generic error. |
| G-6 | Gate argv helpers or equivalent call sites build supervised, file-backed argv lists for parser, grounder, and engine: `--supervised --status=stderr --output PATH ...`; no shell command string is constructed. | inspect call sites; `rg -n "wolong-exec:run|--supervised|--status=stderr|--output|os:cmd|/bin/sh|open_port|exec:run" src test` | serious | Chengdu CLI docs; arc01 runner contract | open | | Fixture scripts may use `/bin/sh`; production Wolong call paths must not. |
| G-7 | Common Test proves a one-shot supervised parse -> ground -> solve fixture flow through Wolong code, asserting artifact creation, stdout ownership, final status fields for all three components, and solved engine success. | `rebar3 as test ct`; inspect new/updated `*_SUITE.lfe`; inspect `test/fixtures/gate-contract-substrate/` | serious | arc02 A2 | open | | This is not yet the full dispatch lifecycle or public `plan` API. |
| G-8 | Engine `domain_no_plan`/exit `2` is represented in shared mapping with a success-shaped unsolvable/domain outcome for engine gate use, and a fixture/test proves the mapper distinguishes it from malformed input, timeout, and missing artifact. | `rebar3 as test ct`; inspect engine/no-plan mapper test; compare against Chengdu managed-process docs and engine contract records | serious | project invariant; arc02 A3 | open | | The public `#(unsolvable ...)` API can wait for slice03, but the mapper must not poison it now. |
| G-9 | CI fixture strategy is honest: checked-in fixture executables may emulate parser/grounder/engine status behavior, but the ledger and closing report do not claim remote CI ran real Chengdu binaries unless it did. | inspect fixtures; inspect ledger/closing report; inspect CI run evidence | correctness | arc01 deferral; arc02 OQ3 | open | | Real binary provisioning remains arc03. |
| G-10 | Scope fence holds: no public `wolong:plan`, no public `wolong:verify`, no `gen_statem`, no dispatch supervisor, no Chengdu release downloader, and no legacy `pandaPI*` fallback. | `rg -n "defun plan|defun verify|gen_statem|dispatch|download|release|pandaPIparser|pandaPIgrounder|pandaPIengine" src test docs/design-v0.1.0/arc02-gate-pipeline/slice01-gate-contract-substrate` | correctness | slice-doc section 5 | open | | Docs may mention legacy names only as forbidden fallback context. |
| G-11 | Local gates pass: `rebar3 compile`, `rebar3 as test eunit`, `rebar3 as test ct`, `rebar3 xref`, and `rebar3 dialyzer`. | run listed commands and record summaries | correctness | repo workflow | open | | If dialyzer becomes fragile for LFE/tooling reasons, stop and report before weakening CI. |
| G-12 | A tamper cycle proves the new gate-contract tests are meaningful: break one status mapping or argv assertion, observe the owning test gate fail nonzero, revert, and observe it pass. | local tamper transcript in ledger/closing report | correctness | ledger discipline | open | | Tamper the new gate substrate, not only old parser validation. |

## What Worked

_(At slice close. Patterns that made the slice close cleanly.)_

## Closure

Closed at commit <SHA> on <date>. Verified by: <name/session>.
Rows: 12. Done: <n>. Deferred: <n>. No-op: <n>.
