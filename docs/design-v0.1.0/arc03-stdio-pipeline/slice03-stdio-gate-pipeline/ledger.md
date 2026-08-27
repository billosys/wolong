# Slice 03 (wolong arc03): stdio-gate-pipeline

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at slice
> start, 2026-08-26. Closer: CC. Verifier: CDC. Evidence names commits and
> command results; CDC upgrades accepted `done` evidence from attested to
> reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| SG-1 | Pipeline parser invocation uses the supported complete planning-instance parser call with `--output -`. | inspect parser argv builder/call path; CT fixture asserts parser output target is stdout and domain/problem roles are not both `-` | serious | arc03 slice03 goal | open |  | Do not assume parser `- -`. |
| SG-2 | Parser stdout bytes are classified as the parser artifact without requiring a parser output file for success. | CT solved path asserts parser detail records stdout artifact bytes/source and status fields | serious | arc03 A3 | open |  | Existing file-backed classifier requires output-path adaptation. |
| SG-3 | Grounder is invoked with input path `-`, receives parser stdout bytes via `wolong-exec:run-stdin/4`, and receives EOF. | CT fixture blocks until EOF and asserts `path=-` / `path_role=htn` status fields or equivalent marker | serious | arc03 A3 | open |  | No shell pipe and no intermediate file input. |
| SG-4 | Grounder stdout bytes are classified as the grounder artifact without requiring a grounder output file for success. | CT solved path asserts grounder detail records stdout artifact bytes/source and status fields | serious | arc03 A3 | open |  | Materialization for debug is allowed but not the handoff. |
| SG-5 | Engine is invoked with input path `-`, receives grounder stdout bytes via `wolong-exec:run-stdin/4`, and receives EOF. | CT fixture blocks until EOF and asserts `path=-` / `path_role=engine_input` status fields or equivalent marker | serious | arc03 A3/A4 | open |  | This is the release-critical engine boundary. |
| SG-6 | Engine solved stdout bytes become the durable plan payload before workspace cleanup. | CT `keep-artifacts=false` solved public plan still contains plan payload bytes and source metadata | serious | project W1 | open |  | Payload source should not imply a file artifact if it came from stdout. |
| SG-7 | Engine no-plan with exit `2`, `status=domain_no_plan`, and empty stdout remains `#(domain-no-plan Detail)` internally and public `#(unsolvable Detail)`. | CT internal pipeline and public plan no-plan cases | serious | project W1/A4 | open |  | Empty stdout is expected here, not missing artifact. |
| SG-8 | Final machine status remains parsed from stderr for all stdio gates. | CT success and failure fixtures include stderr `PANDAPI_STATUS`; grep/inspect no stdout-status dependency | serious | managed-process safety | open |  | No diagnostic-prose classification. |
| SG-9 | Parser, grounder, and engine failure statuses remain typed and gate-named. | CT parser invalid/missing, grounder invalid, engine invalid, status mismatch/missing, and unmapped status cases | serious | arc03 A5 | open |  | Preserve existing public `#(error #(Gate Reason Detail))` adaptation. |
| SG-10 | Exec-layer failures from stdio handoff remain typed and gate-named. | CT stdin send failure if feasible, invalid stdin via gate helper if exposed, command-not-found, start-failed, and timeout paths | correctness | arc03 A5 | open |  | Do not leak raw `exec` details without gate context. |
| SG-11 | Timeout cleanup still kills TERM-resistant stdio children and later dispatches recover. | CT engine timeout over stdin, no survivor PID, then solved plan succeeds | serious | project W2/A6 | open |  | Existing dispatch timeout tests should remain meaningful. |
| SG-12 | Output caps/truncation are surfaced honestly for stdout artifacts and stderr diagnostics. | CT fixture floods stdout/stderr; assert bounded captures and typed result/metadata rather than silent artifact trust | correctness | arc03 OQ4/A6 | open |  | If artifact truncation should be an error, ledger the chosen behavior. |
| SG-13 | Workspace metadata and cleanup remain honest for stdout-sourced artifacts. | CT `keep-artifacts=true` and `keep-artifacts=false`; inspect artifact metadata source/path/bytes and cleanup result | correctness | arc02 compatibility | open |  | Optional mirror files must not be mistaken for handoff inputs. |
| SG-14 | Public `wolong:plan/2,3` shapes are unchanged for solved, unsolvable, typed gate errors, dispatch metadata, and verification-boundary metadata. | existing and new CT in `wolong_plan_SUITE`/`wolong_dispatch_SUITE` | serious | public API compatibility | open |  | Implementation may change; contract must not. |
| SG-15 | `wolong:validate/2` remains parser-only and does not invoke grounder or engine. | CT fixture markers prove only parser runs; result shape remains parser validation | correctness | public API compatibility | open |  | If validate remains file-backed, record that as not part of this pipeline proof. |
| SG-16 | CI fixtures model Chengdu stdio artifact behavior honestly, including parser stdout, grounder stdin/stdout, engine stdin/stdout, and parser `- -` unsupported. | inspect fixture scripts and CT assertions | serious | CI honesty | open |  | Remote CI must not depend on `../chengdu`. |
| SG-17 | Optional local real-Chengdu solved and no-plan smoke probes are recorded if sibling binaries are available. | run Wolong pipeline or public plan with `../chengdu/bin/pandapi-*`; record command/result, or reason skipped | correctness | release confidence | open |  | Local-only evidence; do not close Slice04 with this. |
| SG-18 | Scope guard holds: no split parser workers, framed stdin, provisioning, public API redesign, diagnostic-prose classifier, legacy binary fallback, verifier, action parser, or decomposition parser lands. | inspect diff and `rg` for scoped terms in `src`, `test`, `README.md`, and docs | serious | slice-doc scope | open |  | Future architecture urges get their own arc/slice. |
| SG-19 | Local gates and formatter check pass. | `rebar3 compile`; `rebar3 as test eunit`; `rebar3 as test ct`; `rebar3 xref`; `rebar3 dialyzer`; `rebar3 lfe format --check` | correctness | repo workflow | open |  | Record exact counts and failures. |
| SG-20 | A meaningful tamper cycle proves a new stdio pipeline invariant. | break grounder/engine stdin handoff, EOF, stdout artifact use, status stream, or no-plan empty stdout handling; show CT fail; revert and show pass | serious | ledger discipline | open |  | Do not commit the tamper. |
| SG-21 | Remote CI evidence is recorded honestly. | link green Ubuntu/macOS run, or mark deferred if not pushed/available | correctness | release confidence | open |  | State fixture-backed vs real-Chengdu evidence. |
| SG-22 | Closing report walks every ledger row and bubbles up pipeline shape, parser caveat, Slice04 readiness, and any Slice05 hardening need. | inspect `closing-report.md` for SG-1 through SG-22 and Bubble-up sections | correctness | project management | open |  | CDC writes `cdc-verification.md` later. |

## What Worked

To be completed during slice close.

## Closure

Open.
