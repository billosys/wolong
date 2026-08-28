# Slice 05 Closing Report: Verification Boundary

Closed by CC on 2026-08-15.

Implementation commit:
`b33ee7ec5e7f0f84ed97d94e35d2c92bae47abf5`
(`Resolve verification boundary docs`).

CI evidence:
No new GitHub Actions run was triggered by CC. The implementation commit is
local on `main`, ahead of `origin/main`; remote Ubuntu/macOS CI should be
recorded after push. CI uses checked-in Wolong fixture executables and does not
depend on `../chengdu`.

## Per-Row Walk

| Row | Status | Evidence |
|-----|--------|----------|
| VB-1 | done | Chengdu docs and binaries were surveyed first. `../chengdu/bin` contains `pandapi-parser`, `pandapi-grounder`, and `pandapi-engine`; docs and help output expose those three supported normal managed surfaces; version output reports `managed_process_contract=0.3.0`. |
| VB-2 | done | `arc-plan.md` resolves OQ1 as verifier deferred and adds slice05 v1.5 version history. |
| VB-3 | done | `project-plan.md` now states the implemented 0.1.0 surface: parser-only `validate`, `plan/2`, `plan/3`, explicit `verification-boundary`, and deferred `verify` with re-entry condition. |
| VB-4 | done | README no longer contains the stale implemented-sequence phrase `parse -> ground -> solve -> convert -> verify`; absence greps returned no matches. |
| VB-5 | done | README lists current public API, defers `wolong:verify`, names `verification-boundary`, and updates arc01/arc02/arc03 status. Stale "No plan"/"No validate"/"arc01 in progress" wording is absent. |
| VB-6 | done | README dev setup uses `pandapi-parser`, `pandapi-grounder`, and `pandapi-engine`; legacy `pandaPIparser`/`pandaPIgrounder`/`pandaPIengine` names are absent. |
| VB-7 | done | `src/wolong.lfe` still returns `separate-verifier=not-run`, `action-sequence=deferred`, and `decomposition-tree=deferred`; `wolong_plan_SUITE` passed 10/10. |
| VB-8 | done | No `defun verify`, `verify` export, or direct `wolong:verify` appears in `src` or `test`; `src/wolong.lfe` exports only `plan/2`, `plan/3`, and `validate/2`. |
| VB-9 | done | `action-sequence` and `decomposition-tree` hits in `src`/`test` are only boundary metadata and assertions, not parsers. |
| VB-10 | done | No diagnostic-prose classifier patterns appeared in `src` or `test`; classification remains exit/status-field based. |
| VB-11 | done | No source/test release provisioning, downloader, checksum verifier, hex packaging, or legacy binary fallback landed; README hits assign those responsibilities to Arc03. |
| VB-12 | done | Full Common Test passed 62 tests, including plan, dispatch, and parser suites. |
| VB-13 | done | Local gates passed: compile; EUnit 9 tests; CT 62 tests; xref; Dialyzer. |
| VB-14 | done-local; ci-not-triggered | Remote CI was not triggered because CC did not push. Record GitHub Actions after push. |
| VB-15 | done | Tamper changed `separate-verifier` to `skipped`; `wolong_plan_SUITE` failed with `{expected,'not-run',actual,skipped}`. After revert, the suite passed 10/10. |
| VB-16 | done | This closing report walks VB-1 through VB-16 and includes the required bubble-up. |

Rows: 16. Done: 15. Done-local/CI-not-triggered: 1. Deferred: 0. No-op: 0.

## Gate Evidence

```text
rebar3 compile
exit 0

rebar3 as test eunit
9 tests, 0 failures

rebar3 as test ct
All 62 tests passed.

rebar3 xref
exit 0

rebar3 dialyzer
exit 0
```

An initial compile/EUnit load printed a transient BEAM `not_purged` report but
the commands exited 0. `rebar3 compile` was rerun cleanly, and the full required
gate set passed.

Tamper:

```text
tamper: change verification-boundary separate-verifier from not-run to skipped
rebar3 as test ct --suite test/wolong_plan_SUITE.lfe
Failed 1 tests. Passed 9 tests.
failure: {expected,'not-run',actual,skipped}

after revert:
rebar3 as test ct --suite test/wolong_plan_SUITE.lfe
All 10 tests passed.
```

## Chengdu Survey

The required source survey found no supported verifier contract:

- `ls -al ../chengdu/bin` showed only `pandapi-parser`, `pandapi-grounder`, and
  `pandapi-engine`.
- `../chengdu/docs/reference/cli.md` lists parser, grounder, and engine as the
  supported 0.3.0 command surfaces.
- `../chengdu/docs/managed-process.md` describes supervised
  parser -> grounder -> engine integration.
- `--help` for all three local binaries exited 0 and described only their
  parser, grounder, or engine supported surface.
- `--version` for all three local binaries exited 0 and reported
  `managed_process_contract=0.3.0`.

Because no supported verifier surface was found, this slice did not implement
`wolong:verify`.

## Bubble-up to the arc

- Slice05 delivered the `verification-boundary` line in `arc-plan.md` by
  resolving OQ1 as explicit deferral rather than implementation.
- OQ1 disposition: current Chengdu 0.3.0 support is parser, grounder, and
  engine only. Public `wolong:verify`, action-sequence parsing, and
  decomposition-tree parsing are deferred until a supported verifier or stable
  machine-readable plan/decomposition contract exists and Wolong has fixtures
  plus tests for verified, invalid, and typed verifier-error outcomes.
- Arc02 is ready for arc close after CDC verification of slice05. The remaining
  remote CI evidence should be recorded after the close commit is pushed.
- Arc03 must own binary release provisioning, checksum/download evidence, and
  clean-machine installation. Arc02 CI remains fixture-backed and should not
  depend on `../chengdu`.
- scope-as-specified equals scope-as-delivered: no public `wolong:verify`, no
  separate-verifier claim, no action/decomposition parser, no diagnostic-prose
  classifier, no release/provisioning work, no legacy `pandaPI*` fallback, no
  planner pool/queue/distribution, and no broad public options redesign landed.

CDC verification remains separate; no `cdc-verification.md` was created by CC.
