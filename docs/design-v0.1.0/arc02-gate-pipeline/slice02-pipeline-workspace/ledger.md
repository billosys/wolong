# Slice 02 (wolong arc02): pipeline-workspace

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at
> slice start, 2026-08-14. Closer: CC. Verifier: CDC. Evidence must name the
> commit and include command output or direct artifact pointers; CDC upgrades
> accepted `done` evidence from attested to reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| PW-1 | OQ4 is dispositioned before pipeline code relies on output capture: either stream-to-file runner capture lands, or file-backed artifacts plus capped diagnostics are accepted for 0.1.0 with a re-entry condition. | inspect `../arc-plan.md` version history and slice close bubble-up; inspect `wolong-exec`/`wolong-gate` changes for capture policy | serious | arc-plan OQ4; slice01 CDC residuals | open | | Do not leave this implicit. |
| PW-2 | A per-dispatch workspace is created under configured `workdir.base-dir` with a unique dispatch id/path and typed errors for unavailable base/workspace directories. | `rebar3 as test ct`; inspect workspace module/helpers; CT case for unique workspace and unavailable workdir | serious | arc-plan slice02 | open | | The workspace root must stay under `base-dir`. |
| PW-3 | Stable artifact roles and names exist inside the dispatch workspace for parser, grounder, and engine outputs, and pipeline gate calls use those explicit output paths. | inspect `wolong-pipeline`/`wolong-gate`; CT asserts artifact paths end inside one dispatch dir with expected roles/names | correctness | Chengdu pipeline contract; slice-doc section 3 | open | | Extend `wolong-gate` if needed; avoid base-dir-only random gate paths. |
| PW-4 | `workdir.keep-artifacts=true` keeps the dispatch workspace and artifacts inspectable after solved and no-plan results. | CT case with `keep-artifacts=true`; inspect returned workspace/artifact metadata; `filelib:is_dir`/`filelib:is_file` assertions | correctness | config contract; debugability | open | | No-plan should preserve parser/grounder artifacts even when no plan exists. |
| PW-5 | `workdir.keep-artifacts=false` removes only the dispatch workspace after result construction for success, no-plan, and failure paths, while preserving enough metadata for debugging. | CT cases with `keep-artifacts=false`; assert dispatch dir removed; assert parent/base dir remains; inspect detail metadata and cleanup result | serious | cleanup safety | open | | Never delete configured `base-dir` or caller input files. |
| PW-6 | An internal pipeline function composes config validation, parser/grounder/engine binary resolution, workspace creation, and sequential parser -> grounder -> engine execution through `wolong-gate`. | `rebar3 compile`; inspect exports/call graph; `rg -n "wolong-pipeline\|wolong-gate:run-parser\|wolong-gate:run-grounder\|wolong-gate:run-engine\|wolong-binaries" src test` | serious | arc-plan slice02 | open | | Internal module exports are fine; do not add top-level public `wolong:plan`. |
| PW-7 | Solved minimal fixture pipeline returns a success-shaped internal result with parser, grounder, and engine gate details; artifacts are complete and stdout ownership remains empty for file-backed artifacts. | `rebar3 as test ct`; inspect `wolong_pipeline_SUITE`; real-binary local probe if available | serious | arc02 A2 | open | | CI may use strict fixtures; record real Chengdu evidence separately. |
| PW-8 | Valid no-plan fixture pipeline returns a success-shaped internal no-plan/domain result from engine `domain_no_plan`/exit `2`, with parser/grounder artifacts present and no required plan artifact. | `rebar3 as test ct`; inspect no-plan assertions and returned shape | serious | project invariant; arc02 A3 | open | | This must not be `#(error ...)`. |
| PW-9 | Parser failure short-circuits the pipeline: no grounder or engine gate is invoked, and the returned typed error names the parser gate/reason. | CT missing-domain or parser-invalid case; assert no grounder/engine artifacts/markers; inspect error shape | correctness | pipeline safety | open | | Avoid continuing on partial artifacts. |
| PW-10 | Grounder failure short-circuits the pipeline: engine is not invoked, and the returned typed error names the grounder gate/reason. | CT malformed `.htn` or fixture-induced grounder invalid case; assert no engine artifact/marker; inspect error shape | correctness | pipeline safety | open | | Add a small fixture trigger if existing fixtures cannot produce this path. |
| PW-11 | Engine failure returns a typed engine error while preserving parser/grounder artifacts and workspace cleanup policy. | CT engine invalid/failure fixture case; inspect error shape and metadata | correctness | pipeline safety | open | | Distinguish engine invalid/error from engine no-plan. |
| PW-12 | Slice01 residual status mismatch is dispositioned: contradictory OS exit/status-line `exit_code` is either a typed mismatch result with tests or a documented deferral with reason and re-entry before slice03. | inspect `wolong-gate` tests/mapper or closing bubble-up and `../arc-plan.md`; CT tamper/synthetic result if implemented | correctness | slice01 CDC residual | open | | Prefer fixing now if small. |
| PW-13 | Scope fence holds: no public `wolong:plan`, no public `wolong:verify`, no `gen_statem`, no dispatch supervisor/concurrency model, no release downloader/provisioner, and no legacy `pandaPI*` runtime fallback. | `rg -n "defun plan|defun verify|gen_statem|supervisor|dispatch worker|download|release|pandaPIparser|pandaPIgrounder|pandaPIengine" src test docs/design-v0.1.0/arc02-gate-pipeline/slice02-pipeline-workspace` | serious | slice-doc section 4 | open | | Planning prose may mention forbidden terms as scope fence only. |
| PW-14 | Local gates pass: `rebar3 compile`, `rebar3 as test eunit`, `rebar3 as test ct`, `rebar3 xref`, and `rebar3 dialyzer`; CI is green on Ubuntu and macOS. | run listed commands; record GitHub Actions run URL and matrix result | correctness | repo workflow | open | | If Dialyzer/tooling becomes fragile, stop and report before weakening CI. |
| PW-15 | A tamper cycle proves pipeline tests are meaningful: break cleanup, short-circuit, or no-plan mapping; observe the owning CT gate fail nonzero; revert and observe it pass. | local tamper transcript in ledger/closing report | correctness | ledger discipline | open | | Target new pipeline/workspace behavior, not only old gate mapping. |

## What Worked

_(At slice close. Patterns that made the slice close cleanly.)_

## Closure

Closed at commit <SHA> on <date>. Verified by: <name/session>.
Rows: 15. Done: <n>. Deferred: <n>. No-op: <n>.
