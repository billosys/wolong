# Slice 02 (wolong arc02): pipeline-workspace

> Open-set plan-of-record for `slice02-pipeline-workspace`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened 2026-08-14.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Add the internal workspace and sequential pipeline layer that later public API
slices will wrap.

At slice close, Wolong should be able to run a private/internal
parse -> ground -> solve dispatch over `wolong-gate`, using a unique
per-dispatch workspace under the configured workdir. The pipeline should
produce predictable artifact roles, short-circuit on the first failing gate,
preserve engine `domain_no_plan` as a success-shaped domain outcome, and apply
the configured keep/delete artifact policy without deleting anything outside
the dispatch workspace.

This is still not the public planning API. It is the internal dispatch
workspace and orchestration substrate for `wolong:plan` in slice03.

## 2. Context From Earlier Slices

- Arc01 proved `wolong-exec:run/3`, parser validation, timeout cleanup,
  bounded stdout/stderr, and current `pandapi-parser` result mapping.
- Arc02 slice01 added `wolong-status` and `wolong-gate`, extended
  `wolong-binaries` to parser/grounder/engine, proved strict CI fixtures, and
  reproduced real local Chengdu minimal/no-plan pipeline behavior.
- Slice01 resolved OQ2 and OQ3 in `../arc-plan.md`; OQ4 remains open for this
  slice: decide whether engine-scale output requires runner stream-to-file
  support now, or whether file-backed artifacts plus capped diagnostics are
  sufficient for 0.1.0.
- Slice01 left one residual hardening note: `wolong-gate` classifies from OS
  exit status plus final `status` and preserves status-line `exit_code`, but
  does not yet reject contradictory status-line `exit_code`. Slice02 should
  disposition that before public `wolong:plan` relies on the pipeline.

## 3. In Scope

- Add an internal pipeline module, likely `src/wolong-pipeline.lfe`, that runs
  parser -> grounder -> engine sequentially through `wolong-gate`.
- Add an internal workspace helper, either in the pipeline module or a small
  `wolong-workspace` module, to create a unique per-dispatch directory under
  configured `workdir.base-dir`.
- Give every dispatch stable artifact roles and predictable names inside the
  dispatch workspace, for example:

  ```text
  parser.htn
  grounder.sas
  engine.plan
  ```

- Extend `wolong-gate` as needed so pipeline orchestration can choose explicit
  output paths rather than relying only on gate-generated paths in the base
  workdir.
- Honor configured `workdir.keep-artifacts`: keep the dispatch directory when
  `true`, remove it after result construction when `false`, and always preserve
  enough metadata in the returned detail to debug the dispatch.
- Return typed internal pipeline results for:
  - solved minimal pipeline;
  - engine no-plan pipeline;
  - parser failure;
  - grounder failure;
  - engine failure;
  - workspace creation/cleanup failure.
- Preserve gate details from `wolong-gate`, including status fields, stdout,
  stderr, artifact metadata, duration, and truncation metadata.
- Add Common Test coverage for workspace creation, artifact roles, cleanup
  policy, solved/no-plan pipelines, and short-circuit failure behavior.
- Reuse existing strict gate-contract fixtures where possible. Add small
  pipeline-specific fixture behavior only where necessary to prove
  short-circuit failure or cleanup.
- Run local real-binary evidence against sibling `../chengdu/bin/pandapi-*`
  if available, keeping it separate from CI fixture evidence.

## 4. Out of Scope

- No public `wolong:plan` yet.
- No public `wolong:verify`.
- No `gen_statem`, dispatch worker, dispatch supervisor, concurrent dispatch
  isolation, or restart strategy; those belong to later slices.
- No planner result term finalization, action-sequence parsing, or
  decomposition-tree model; slice03 owns the first public plan shape.
- No Chengdu release download, checksum verification, or provisioning.
- No fallback to legacy `pandaPIparser`, `pandaPIgrounder`, or
  `pandaPIengine`.
- No diagnostic-prose classification.
- No broad config redesign beyond what is required to use existing
  `workdir.base-dir` and `workdir.keep-artifacts` safely.

## 5. Contract Notes

The current supported external pipeline remains:

```text
pandapi-parser   --supervised --status=stderr --output OUT.htn DOMAIN.hddl PROBLEM.hddl
pandapi-grounder --supervised --status=stderr --output OUT.sas INPUT.htn
pandapi-engine   --supervised --status=stderr --output OUT.plan INPUT.sas
```

Each step should run only after the prior step produced an acceptable result
and artifact for the next step. Programmatic classification comes from the OS
exit code and final `PANDAPI_STATUS`, not diagnostic prose.

Engine `domain_no_plan`/exit `2` is a valid domain result. The internal
pipeline may continue returning `#(domain-no-plan Detail)` until slice03 maps
it to the project-level `#(unsolvable ...)`, but it must not return
`#(error ...)` for valid no-plan.

The intended workspace shape is one dispatch directory per pipeline attempt.
The dispatch directory is the only tree the pipeline may remove.

## 6. Verification Approach

Primary coverage is Common Test:

```bash
rebar3 as test ct
```

Add a suite such as:

```text
test/wolong_pipeline_SUITE.lfe
```

EUnit/ltest may remain for pure config tests. Do not put OS-process,
workspace, or binary integration behavior into EUnit.

CDC should independently re-run:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

CDC should also inspect source for:

- explicit output paths under a per-dispatch workspace;
- cleanup constrained to the dispatch workspace;
- no public `wolong:plan`/`wolong:verify`;
- no `gen_statem` or supervision/concurrency additions;
- no shell command concatenation;
- no diagnostic-prose classification;
- no legacy binary names in runtime paths.

## 7. Exit Criteria

- A private/internal pipeline function exists and composes config validation,
  binary resolution, workspace creation, parser, grounder, and engine.
- Per-dispatch workspaces are unique, under configured `workdir.base-dir`, and
  carry stable artifact roles/names.
- `keep-artifacts=true` leaves the dispatch workspace inspectable.
- `keep-artifacts=false` removes only the dispatch workspace after result
  construction, while preserving debug metadata.
- Solved and no-plan fixture pipelines return distinct success-shaped internal
  results.
- Parser, grounder, and engine failures short-circuit subsequent gates and
  return typed errors naming the failing gate.
- OQ4 is dispositioned in the closing bubble-up: either stream-to-file runner
  capture is implemented, or file-backed artifacts plus capped diagnostics are
  explicitly accepted for 0.1.0 with a re-entry condition.
- The status-line `exit_code` mismatch residual from slice01 is either fixed
  with a typed mismatch result or explicitly deferred with a reason and
  re-entry condition before public API work begins.
- Local gates and CI are green; real Chengdu binary evidence is honestly
  separated from CI fixture evidence.
- The slice closes without adding public planning/verification API,
  supervision/concurrency, release provisioning, or legacy binary fallback.
