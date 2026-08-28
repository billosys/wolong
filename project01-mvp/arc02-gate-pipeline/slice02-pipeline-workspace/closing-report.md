# Slice 02 Closing Report: Pipeline Workspace

Closed by CC on 2026-08-14.

Implementation commit:
`6b5a67a4aa38b545d5523f51d024a90ba884351f`
(`Implement pipeline workspace substrate`).

CI evidence:
GitHub Actions run `31842233200`
(`https://github.com/billosys/wolong/actions/runs/31842233200`) passed on
Ubuntu 22.04 and macOS 15: compile, EUnit, Common Test, xref, and Dialyzer.

## Per-Row Walk

| Row | Status | Evidence |
|-----|--------|----------|
| PW-1 | done | OQ4 resolved in `../arc-plan.md` v1.2: file-backed artifacts plus capped stdout/stderr diagnostics are sufficient for 0.1.0; re-enter stream-to-file capture only for required non-artifact streams above cap or public full-diagnostic retention. |
| PW-2 | done | `wolong-workspace:create/1` creates retrying unique `dispatch-*` dirs under configured `workdir.base-dir`; CT covers uniqueness and `base-unavailable`. |
| PW-3 | done | Stable artifact roles are `parser.htn`, `grounder.sas`, `engine.plan`; `wolong-gate:run-*-to` helpers execute gates with explicit output paths; CT asserts role names and one dispatch directory. |
| PW-4 | done | Keep-true CT cases leave solved and no-plan workspaces inspectable; solved preserves parser/grounder/engine artifacts, no-plan preserves parser/grounder artifacts and no required plan artifact. |
| PW-5 | done | Keep-false CT removes only the dispatch dir, leaves base/sentinel intact, and preserves returned metadata; direct cleanup safety CT rejects deleting the base dir as `unsafe-delete`. |
| PW-6 | done | `wolong-pipeline:run/2` composes config validation, parser/grounder/engine binary resolution, workspace creation, and sequential gate execution through `wolong-gate`. |
| PW-7 | done | Fixture CT returns `#(ok Detail)` for minimal solved pipeline with gate details, complete artifacts, and empty stdout; local real-binary probe returned `minimal_top=ok` with parser/grounder/engine files present and engine `outcome=solved`. |
| PW-8 | done | Fixture CT returns `#(domain-no-plan Detail)` for no-plan with parser/grounder artifacts and no plan artifact; local real-binary probe returned `no_plan_top='domain-no-plan'`, engine `status=domain_no_plan`, `outcome=no_plan`, and no engine file. |
| PW-9 | done | Parser failure CT returns `#(error #(parser input-unavailable Detail))`; marker files prove grounder and engine were not invoked. |
| PW-10 | done | Grounder failure CT returns `#(error #(grounder input-invalid Detail))`; marker files prove engine was not invoked. |
| PW-11 | done | Engine invalid CT returns `#(error #(engine input-invalid Detail))`, preserves parser/grounder artifacts, invokes engine, and remains distinct from no-plan. |
| PW-12 | done | Slice01 residual fixed: `wolong-gate` returns `status-exit-mismatch` on contradictory observed exit/status-line `exit_code`; CT covers mismatch and `wolong:validate/2` adapts it as a parser error. |
| PW-13 | done | Scope grep found no new public `wolong:plan`, `wolong:verify`, `gen_statem`, dispatch supervisor/concurrency, downloader/provisioner, or legacy runtime fallback. Hits are slice prose plus pre-existing app supervisor/test shell probe. |
| PW-14 | done | Local gates passed: compile; EUnit 9 tests; CT 42 tests; xref; Dialyzer. CI run `31842233200` passed the same matrix on Ubuntu 22.04 and macOS 15 for implementation commit `6b5a67a`. |
| PW-15 | done | Tamper changed keep-false cleanup to keep workspaces. Pipeline CT failed nonzero at cleanup ownership tests; after revert, isolated pipeline CT passed 8/8 and full CT passed 42/42. |

Rows: 15. Done: 15. Deferred: 0. No-op: 0.

## Local Real-Binary Evidence

Local probe used `../chengdu/bin/pandapi-parser`,
`../chengdu/bin/pandapi-grounder`, and `../chengdu/bin/pandapi-engine` through
`wolong-pipeline:run/2` with `keep-artifacts=true`.

```text
minimal_top=ok minimal_workspace=/tmp/wolong-real-pipeline/dispatch-1 parser_file=true grounder_file=true engine_file=true engine_status=<<"ok">> engine_outcome=<<"solved">>
no_plan_top='domain-no-plan' no_plan_workspace=/tmp/wolong-real-pipeline/dispatch-2 parser_file=true grounder_file=true engine_file=false engine_status=<<"domain_no_plan">> engine_outcome=<<"no_plan">>
```

This evidence is local-only. Remote CI uses checked-in Wolong fixture
executables and does not depend on the sibling Chengdu checkout.

## Tooling Finding

The existing rebar3_lfe/EUnit autoexport workaround remains the unit-test path:
`rebar3 as test eunit` ran the ltest-backed unit tests and passed 9 tests.
Workspace and process behavior belong in Common Test; `wolong_pipeline_SUITE`
is runnable independently and starts the app after setting test env.

## Bubble-Up to the Arc

- Slice02 delivered the workspace/orchestration line in `arc-plan.md`: one
  unique workspace per dispatch, stable artifact roles, cleanup policy, and
  sequential parser -> grounder -> engine orchestration over `wolong-gate`.
- OQ4 is resolved for 0.1.0: file-backed artifacts plus capped diagnostics are
  sufficient. Stream-to-file runner capture is deferred with a concrete
  re-entry condition: a supported Chengdu surface or public API requirement
  must need full non-artifact stream retention beyond the configured cap.
- The Slice01 status mismatch residual is fixed, not deferred:
  contradictory observed exit/status-line `exit_code` now returns
  `status-exit-mismatch`.
- Slice03 can wrap `wolong-pipeline:run/2` into public `wolong:plan` and
  translate internal `#(domain-no-plan Detail)` to the project-level
  `#(unsolvable ...)`; Slice03 still owns the solved plan term shape and public
  error surface.
- Scope-as-specified equals scope-as-delivered for this slice. No public
  `wolong:plan`, public `wolong:verify`, dispatch supervision/concurrency,
  release provisioning, or legacy binary fallback was added.

CDC verification remains separate; no `cdc-verification.md` was created by CC.
