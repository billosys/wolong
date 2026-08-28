# Slice 03 Closing Report: Plan API

Closed by CC on 2026-08-15.

Implementation commit:
`f5b1a9dbb744c16da8d437f4a2e45f48e577a3de`
(`Implement public plan API`).

CI evidence:
GitHub Actions run `31856297784`
(`https://github.com/billosys/wolong/actions/runs/31856297784`) passed on
Ubuntu 22.04 and macOS 15: compile, EUnit, Common Test, xref, and Dialyzer.

## Per-Row Walk

| Row | Status | Evidence |
|-----|--------|----------|
| PA-1 | done | `wolong:plan/3` is exported, and `wolong:plan/2` is a default wrapper over `plan/3`; compile and public CT calls passed. |
| PA-2 | done | Public input validation rejects malformed paths and non-empty/malformed opts before dispatch; fixture invocation markers/base dirs remain absent in the invalid-options CT case. |
| PA-3 | done | `wolong:plan/3` delegates to `wolong-pipeline:run/2`; source inspection shows no argv building, status parsing, erlexec call, workspace creation, or cleanup in the public adapter. |
| PA-4 | done | OQ5 is resolved in `../arc-plan.md` v1.3: the public plan is artifact-backed and provenance-rich; action-sequence and decomposition parsing are deferred with re-entry conditions. |
| PA-5 | done | Solved fixture returns `#(ok Plan)` with `outcome=solved`, artifact/provenance fields, and status-field classification rather than diagnostic-prose classification. |
| PA-6 | done | `wolong-pipeline` captures engine plan bytes before cleanup; CT proves payload survives after `keep-artifacts=false` removes the dispatch workspace. |
| PA-7 | done | Public `Plan` carries `verification-boundary` metadata with `separate-verifier=not-run` plus action/decomposition deferrals. |
| PA-8 | done | Valid no-plan fixture returns public `#(unsolvable Detail)` from engine `domain_no_plan`/exit `2`, preserving gate provenance and no required plan artifact. |
| PA-9 | done | Parser failure returns `#(error #(parser input-unavailable Detail))` and marker files prove grounder/engine were not invoked. |
| PA-10 | done | Grounder failure returns `#(error #(grounder input-invalid Detail))` and marker files prove engine was not invoked. |
| PA-11 | done | Engine invalid returns `#(error #(engine input-invalid Detail))`, distinct from the valid no-plan public `unsolvable` result. |
| PA-12 | done | Workspace and binary failures remain structured as `#(error #(workspace ...))` and `#(error #(engine binary Detail))`. |
| PA-13 | done | Existing `wolong:validate/2` remains parser-only; EUnit and CT suites covering prior validation behavior passed. |
| PA-14 | done | Scope grep found no public `wolong:verify`, `gen_statem`, dispatch supervision/concurrency, downloader/provisioner, legacy binary fallback, or diagnostic-prose classifier. |
| PA-15 | done | Local gates passed: compile; EUnit 9 tests; CT 52 tests; xref; Dialyzer. CI run `31856297784` passed the same matrix on Ubuntu 22.04 and macOS 15 for implementation commit `f5b1a9d`. |
| PA-16 | done | Tamper leaked internal `domain-no-plan`; public plan CT failed nonzero at `no_plan_returns_unsolvable`. After revert, isolated public plan CT passed 10/10. |

Rows: 16. Done: 16. Deferred: 0. No-op: 0.

## Public Plan Shape

The first solved `Plan` term is a map with these committed fields:

- `outcome`: `solved`
- `payload`: durable engine plan artifact bytes
- `payload-bytes`: byte size of the payload
- `artifact`: engine plan artifact metadata
- `provenance`: parser, grounder, and engine structured gate details
- `workspace`: dispatch workspace and cleanup metadata
- `verification-boundary`: explicit statement that no separate verifier ran

Action-sequence parsing and decomposition-tree parsing are not implemented in
this slice. Re-enter them when a stable machine-readable plan/decomposition
format is proven by fixture and real-binary tests, or when a supported verifier
contract makes those fields meaningful at the public API boundary.

## Local Real-Binary Evidence

Local probe used `../chengdu/bin/pandapi-parser`,
`../chengdu/bin/pandapi-grounder`, and `../chengdu/bin/pandapi-engine` through
public `wolong:plan/3` with `keep-artifacts=false`.

```text
minimal_top=ok payload_bytes=2046 cleanup=removed workspace_exists=false verifier='not-run' no_plan_top=unsolvable no_plan_status=<<"domain_no_plan">> no_plan_outcome=<<"no_plan">>
```

This evidence is local-only. Remote CI uses checked-in Wolong fixture
executables and does not depend on the sibling Chengdu checkout.

## Tamper Evidence

Tamper changed `wolong:adapt-plan-result/1` so internal
`#(domain-no-plan Detail)` leaked through the public API. The owning CT gate
failed nonzero:

```text
%%% wolong_plan_SUITE ==> no_plan_returns_unsolvable: FAILED
%%% wolong_plan_SUITE ==> {test_case_failed,{expected,unsolvable,actual,'domain-no-plan'}}
Failed 1 tests. Passed 9 tests.
```

After reverting the tamper:

```text
%%% wolong_plan_SUITE: ..........
All 10 tests passed.
```

## Bubble-Up to the Arc

- Slice03 delivered the `plan-api` line in `arc-plan.md`: public
  `wolong:plan/3` now returns solved, unsolvable, or typed gate/workspace
  errors over the verified internal pipeline. `plan/2` is only a convenience
  wrapper.
- OQ5 is resolved conservatively. The solved public plan is artifact-backed:
  durable payload bytes plus artifact metadata, gate provenance, workspace
  cleanup metadata, and an explicit verification boundary.
- Slice04 can add dispatch supervision around this public adapter; it must
  preserve the solved/unsolvable/error shapes and prove timeout/no-zombie and
  concurrent-dispatch isolation without moving verification claims.
- Slice05 must treat `verification-boundary.separate-verifier=not-run` as
  load-bearing. It either implements a supported verifier surface or updates
  project/README wording so `wolong:verify` remains explicitly deferred.
- Scope-as-specified equals scope-as-delivered for this slice. No public
  `wolong:verify`, dispatch supervision/concurrency, release provisioning,
  legacy runtime fallback, diagnostic-prose classifier, action parser, or
  decomposition parser was added.

CDC verification remains separate; no `cdc-verification.md` was created by CC.
