# CDC Verification: Slice 02 Pipeline Workspace

Verified by CDC on 2026-08-14.

## Verdict

Accepted. Slice02 is CDC-verified.

The opening ledger has 15 rows, the closing report walks 15 rows, and all 15
rows are accepted as `done` with reproduced or reconciled evidence. No
deferred or no-op rows remain.

## Reviewed Artifacts

- Implementation commit:
  `6b5a67a4aa38b545d5523f51d024a90ba884351f`
  (`Implement pipeline workspace substrate`)
- Close-out commit:
  `a45329fac0bb99e8e73327a78ec5d6ddc38cbdc5`
  (`Close pipeline workspace slice`)
- Source reviewed:
  - `src/wolong-pipeline.lfe`
  - `src/wolong-workspace.lfe`
  - `src/wolong-gate.lfe`
  - `src/wolong.lfe`
  - `test/wolong_pipeline_SUITE.lfe`
  - `test/wolong_gate_SUITE.lfe`
  - `test/fixtures/gate-contract-substrate/*`
- Planning/close artifacts reviewed:
  - `ledger.md`
  - `closing-report.md`
  - `../arc-plan.md`

## Reproduced Local Gates

All commands were run locally from `/Users/oubiwann/lab/billosys/wolong` at
commit `a45329fac0bb99e8e73327a78ec5d6ddc38cbdc5`.

```text
$ rebar3 compile
===> Verifying dependencies...
===> Compiling 1 LFE application(s)
===> Analyzing applications...
===> Compiling wolong
exit 0

$ rebar3 as test eunit
9 tests, 0 failures
exit 0

$ rebar3 as test ct
%%% wolong_exec_SUITE: ..........
%%% wolong_gate_SUITE: ...............
%%% wolong_parser_SUITE: .........
%%% wolong_pipeline_SUITE: ........
All 42 tests passed.
exit 0

$ rebar3 xref
===> Running cross reference analysis...
exit 0

$ rebar3 dialyzer
===> Analyzing 10 files with _build/default/rebar3_28.1.1_plt...
exit 0
```

## CI Evidence

Implementation CI run
`https://github.com/billosys/wolong/actions/runs/31842233200` was checked via
the GitHub Actions jobs API. Both matrix jobs completed successfully:

- `build (macos-15)`: success
- `build (ubuntu-22.04)`: success

Close-out CI run
`https://github.com/billosys/wolong/actions/runs/31842869083` was checked via
the GitHub Actions jobs API. Both matrix jobs completed successfully:

- `build (macos-15)`: success
- `build (ubuntu-22.04)`: success

Each job ran compile, EUnit, Common Test, xref, and Dialyzer.

## Real Chengdu Binary Spot Check

The sibling Chengdu binaries were present and executable:

- `/Users/oubiwann/lab/billosys/chengdu/bin/pandapi-parser`
- `/Users/oubiwann/lab/billosys/chengdu/bin/pandapi-grounder`
- `/Users/oubiwann/lab/billosys/chengdu/bin/pandapi-engine`

Direct supervised minimal chain reproduced the current managed-process status
contract:

```text
pandapi-parser minimal:
PANDAPI_STATUS status=ok component=parser exit_code=0 artifact=file
exit 0

pandapi-grounder minimal:
PANDAPI_STATUS status=ok component=grounder exit_code=0 artifact=file
exit 0

pandapi-engine minimal:
PANDAPI_STATUS status=ok component=engine exit_code=0 artifact=file outcome=solved
exit 0
```

Wolong pipeline top-level result shape was also spot-checked through
`rebar3 lfe eval` with real Chengdu binaries:

```text
minimal fixture:
result_top=ok
exit 0

unsolvable fixture:
result_top='domain-no-plan'
exit 0
```

This remains local-only evidence. CI uses Wolong-owned fixture executables and
does not depend on the sibling Chengdu checkout.

## Scope Fence Check

CDC re-ran the slice scope grep:

```text
rg -n 'defun plan|defun verify|gen_statem|dispatch worker|download|pandaPIparser|pandaPIgrounder|pandaPIengine' \
  src test docs/design-v0.1.0/arc02-gate-pipeline/slice02-pipeline-workspace
```

Hits were confined to slice planning prose and the scope-fence row/report
itself. No public `wolong:plan`, public `wolong:verify`, `gen_statem`,
dispatch worker/supervisor/concurrency model, downloader/provisioner, or
legacy `pandaPI*` runtime fallback landed in the implementation.

## Per-Row Verification

| Row | CDC status | Verification |
|-----|------------|--------------|
| PW-1 | accepted | `../arc-plan.md` v1.2 explicitly resolves OQ4 in favor of file-backed artifacts plus capped diagnostics, with a stream-to-file re-entry condition. `wolong-exec` capture policy was not broadened; pipeline artifacts flow through explicit file paths. |
| PW-2 | accepted | `wolong-workspace:create/1` creates `dispatch-*` directories under configured base dirs; CT reproduced unique workspace and unavailable-workdir cases. |
| PW-3 | accepted | Workspace artifact roles are `parser.htn`, `grounder.sas`, and `engine.plan`; pipeline calls `wolong-gate:run-*-to` with explicit output paths; CT asserts role names. |
| PW-4 | accepted | CT reproduced keep-true solved/no-plan behavior with inspectable workspace/artifacts. |
| PW-5 | accepted | CT reproduced keep-false removal of only the dispatch directory and direct refusal to delete the base directory. |
| PW-6 | accepted | Source inspection confirms `wolong-pipeline:run/2` composes config validation, binary resolution, workspace creation, and sequential parser -> grounder -> engine gate calls. No top-level public `wolong:plan` was added. |
| PW-7 | accepted | CT reproduced solved fixture pipeline as `#(ok Detail)` with gate details and file-backed artifacts; local real-binary spot check reproduced minimal top tag `ok`. |
| PW-8 | accepted | CT reproduced no-plan fixture pipeline as success-shaped `domain-no-plan`; local real-binary spot check reproduced unsolvable top tag `'domain-no-plan'`. |
| PW-9 | accepted | CT marker-file assertions prove parser failure short-circuits grounder and engine. |
| PW-10 | accepted | CT marker-file assertions prove grounder failure short-circuits engine. |
| PW-11 | accepted | CT reproduces typed engine failure, distinct from no-plan, with parser/grounder artifacts preserved under keep-true. |
| PW-12 | accepted | `wolong-gate:classify-status/5` now rejects contradictory OS exit/status-line `exit_code` as `status-exit-mismatch`; CT covers the mismatch and `wolong:validate/2` adapts it. |
| PW-13 | accepted | Scope grep found no forbidden implementation additions; hits are prose/scope-fence only. |
| PW-14 | accepted | Local gates reproduced; implementation and close-out CI runs are green on macOS 15 and Ubuntu 22.04. |
| PW-15 | accepted | Tamper evidence is credible and targets new workspace cleanup behavior; CDC did not repeat the tamper because the owning CT assertions were inspected and full CT reproduced green after revert. |

## Bubble-Up Check

Slice02 delivered the arc-plan line assigned to it: internal per-dispatch
workspace ownership, stable artifact roles, cleanup policy, and sequential
parse -> ground -> solve orchestration over the shared gate substrate.

The slice findings required an arc-plan update, and that update is present in
`../arc-plan.md` v1.2:

- OQ4 is resolved for 0.1.0 as file-backed artifacts plus capped diagnostics,
  with a concrete re-entry condition for stream-to-file capture.
- The Slice01 status-line `exit_code` mismatch residual is fixed, not
  deferred.
- Slice03 is correctly left owning public `wolong:plan`, solved-plan term
  shape, and translation of internal `domain-no-plan` to project-level
  `#(unsolvable ...)`.

The silent-drop diff is clean: scope-as-specified matches scope-as-delivered
for slice02. No public planning/verification API, supervision/concurrency,
release provisioning, or legacy binary fallback was added.

## What Worked

- The workspace helper made deletion safety independently testable.
- The explicit `run-*-to` helpers provided stable artifact paths without
  disturbing the generic runner contract.
- Fixture marker files made short-circuit behavior falsifiable rather than
  inferred from missing outputs.

## Closure

Rows: 15. Accepted: 15. Deferred: 0. No-op: 0.

CDC closes slice02 at
`a45329fac0bb99e8e73327a78ec5d6ddc38cbdc5`. This document records the
independent verification.
