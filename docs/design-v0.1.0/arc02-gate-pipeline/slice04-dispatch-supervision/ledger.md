# Slice 04 (wolong arc02): dispatch-supervision

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at
> slice start, 2026-08-15. Closer: CC. Verifier: CDC. Evidence must name the
> commit and include command output or direct artifact pointers; CDC upgrades
> accepted `done` evidence from attested to reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| DS-1 | The Wolong supervision tree contains an explicit dispatch supervision boundary under `wolong-sup`. | inspect `src/wolong-sup.lfe` and new dispatch supervisor module; `rebar3 compile`; CT app-start assertion | serious | arc-plan slice04 | open | | Supervisor child specs must state restart/shutdown/type choices. |
| DS-2 | Public `wolong:plan/3` routes through the supervised dispatch boundary; `plan/2` remains only a default wrapper over `plan/3`. | run separate `rg -n` checks for dispatch module names in `src/wolong.lfe`; inspect `plan/2` and `plan/3`; public CT calls | serious | slice03 bubble-up | open | | Preserve public API shape. |
| DS-3 | `wolong:validate/2` remains parser-only and does not run through the full planning dispatch supervisor. | inspect `src/wolong.lfe`; `rebar3 as test eunit`; existing parser CT | serious | backwards compatibility | open | | Do not change validate semantics. |
| DS-4 | The dispatch layer delegates to `wolong-pipeline:run/2` or a narrow helper and does not duplicate parser/grounder/engine argv building, status parsing, erlexec calls, workspace creation, or cleanup. | `rg -n "wolong-pipeline" src`; run separate absence greps in new dispatch modules for `parser-argv`, `grounder-argv`, `engine-argv`, `wolong-exec`, `make_dir`, and `del_dir_r`; source review | serious | slice02 substrate | open | | Dispatch supervision wraps the pipeline. |
| DS-5 | Solved and no-plan public results through the supervised path preserve Slice03 shapes and fields. | CT public solved and no-plan cases through `wolong:plan/3`; assert `#(ok Plan)`, durable payload, verification boundary, and `#(unsolvable Detail)` | serious | slice03 contract | open | | No public shape churn. |
| DS-6 | Parser, grounder, engine, binary, config, and workspace failures remain typed public errors naming the failing boundary. | CT fixture failure cases through supervised `wolong:plan/3`; inspect error tuples | correctness | arc02 A4 | open | | Do not collapse into generic dispatch failure. |
| DS-7 | Engine timeout through public `wolong:plan/3` returns a typed engine timeout and preserves bounded stdout/stderr details. | CT timeout fixture through public API; inspect result detail | serious | project W2 | open | | Timeout should still come from the gate/exec substrate. |
| DS-8 | Engine timeout cleanup leaves no surviving OS process group member and the application can complete a later dispatch. | CT term-resistant engine fixture with pid marker; `kill -0` style wait; subsequent solved dispatch succeeds | serious | project W2; arc02 A5 | open | | Reuse or adapt Arc01 timeout fixture pattern. |
| DS-9 | A synthetic dispatch-worker crash is isolated: the application and dispatch supervisor remain alive and the caller receives a typed, matchable dispatch failure. | CT crash-trigger fixture or test-only hook; assert supervisor alive, no leaked worker, typed result | serious | project W4 | open | | If same-request restart is implemented, prove one coherent caller result. |
| DS-10 | Concurrent dispatches use distinct dispatch workers and distinct workspace paths/artifacts. | CT starts at least two overlapping dispatches; assert worker identities and workspace paths differ | correctness | arc02 A6 | open | | Prefer per-test unique base dirs. |
| DS-11 | One concurrent failure or timeout does not take down the app or corrupt another concurrent success. | CT parallel success plus failure/timeout; assert success payload/provenance intact and failure typed | serious | project W4; arc02 A6 | open | | This is the UAT heart of the slice. |
| DS-12 | Completed, failed, timed-out, and crashing dispatches leave no live dispatch worker children after terminal result delivery. | CT queries dispatch supervisor children before/after or uses a stable worker registry helper; assert child count returns to baseline | correctness | OTP hygiene | open | | No orphan dispatch workers. |
| DS-13 | Supervisor restart policy and worker lifecycle are explicitly documented in code or close report, including why one-shot workers use the chosen restart type. | inspect child spec and closing-report design note | serious | Erlang supervision guidance | open | | Avoid accidental permanent restart loops. |
| DS-14 | The verification boundary remains explicit: solved public plans still carry `separate-verifier=not-run`, and no public `wolong:verify` is added. | CT solved result assertion; run separate `rg -n` checks for `defun verify`, `verification-boundary`, and `separate-verifier` in `src`, `test`, and this slice directory | serious | slice03; slice05 dependency | open | | Supervision is not verification. |
| DS-15 | Scope fence holds: no release provisioning, no legacy `pandaPI*` runtime fallback, no diagnostic-prose classifier, no planner pool/global queue/distribution, and no action/decomposition parser. | run separate `rg -n` checks for `download`, `provision`, `pandaPIparser`, `pandaPIgrounder`, `pandaPIengine`, `diagnostic prose`, `grep.*stderr`, `pool`, `queue`, `distributed`, `action-sequence`, and `decomposition-tree` in `src`, `test`, and this slice directory | serious | slice-doc section 4 | open | | Planning prose may mention forbidden terms as scope fence only. |
| DS-16 | Integration tests live in Common Test under the existing `test` tree; no new parallel test directory is created and supervision/process behavior is not moved into EUnit. | inspect `test/*SUITE.lfe`; `rg --files test`; `rebar3 as test ct`; `rebar3 as test eunit` | correctness | AGENTS test boundary | open | | Use LFE CT idioms. |
| DS-17 | Local gates pass: `rebar3 compile`, `rebar3 as test eunit`, `rebar3 as test ct`, `rebar3 xref`, and `rebar3 dialyzer`; CI is green on Ubuntu and macOS. | run listed commands; record GitHub Actions run URL and matrix result | correctness | repo workflow | open | | If Dialyzer/tooling becomes fragile, stop and report before weakening CI. |
| DS-18 | A tamper cycle proves dispatch supervision tests are meaningful: break supervised routing, worker isolation, timeout cleanup, or concurrent workspace uniqueness; observe the owning CT gate fail nonzero; revert and observe it pass. | local tamper transcript in ledger/closing report | correctness | ledger discipline | open | | Target new supervision behavior, not only old pipeline tests. |

## What Worked

_(At slice close. Patterns that made the slice close cleanly.)_

## Closure

Closed at commit <SHA> on <date>. Verified by: <name/session>.
Rows: 18. Done: <n>. Deferred: <n>. No-op: <n>.
