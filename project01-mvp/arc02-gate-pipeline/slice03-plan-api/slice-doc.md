# Slice 03 (wolong arc02): plan-api

> Open-set plan-of-record for `slice03-plan-api`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened 2026-08-15.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Add the first public planning API over the verified internal pipeline
substrate.

At slice close, Wolong should expose public `wolong:plan/3` that runs the
current supported parser -> grounder -> engine chain through
`wolong-pipeline`, returning:

- `#(ok Plan)` for solved inputs;
- `#(unsolvable Detail)` for valid engine no-plan outcomes;
- `#(error #(Gate Reason Detail))` for typed parser, grounder, engine,
  binary, config, workspace, timeout, status, and artifact failures.

The API must preserve the project invariant: no valid no-plan outcome may
collapse into generic failure, and no solved plan may cross the API as a
confident opaque success with the verification boundary hidden.

## 2. Context From Earlier Slices

- Arc02 slice01 created the shared gate substrate: `wolong-status`,
  `wolong-gate`, parser/grounder/engine binary lookup, and managed status
  mapping.
- Arc02 slice02 created the internal pipeline workspace substrate:
  per-dispatch workspaces, stable artifact roles, explicit gate output paths,
  cleanup policy, short-circuit behavior, and internal `domain-no-plan`.
- Slice02 resolved OQ4: file-backed artifacts plus capped diagnostics are
  sufficient for 0.1.0; stream-to-file runner capture has a concrete re-entry
  condition.
- Slice02 fixed the status-line `exit_code` mismatch residual with
  `status-exit-mismatch`.
- OQ5 is now active: decide the first public solved-plan representation.

## 3. In Scope

- Export public `wolong:plan/3` from `src/wolong.lfe`.
- Add `wolong:plan/2` only if the implementation chooses a simple default
  wrapper over `plan/3`; if added, it must be tested and documented in the
  close report.
- Define and implement the first public `Plan` term shape for solved results.
  The expected conservative shape is artifact-backed and provenance-rich:
  - a solved outcome field;
  - the engine plan payload as a binary or otherwise directly usable public
    value;
  - plan artifact metadata;
  - parser, grounder, and engine provenance sufficient for debugging;
  - an explicit verification-boundary field stating what has and has not been
    verified in this slice.
- Translate internal `#(domain-no-plan Detail)` from `wolong-pipeline` to
  public `#(unsolvable Detail)`.
- Translate internal pipeline errors to public typed gate errors without
  diagnostic-prose classification.
- Validate public argument and options shape before dispatch. Invalid argument
  or unsupported option errors must be typed and must not start the external
  pipeline.
- Preserve `wolong:validate/2` behavior and compatibility.
- Add Common Test coverage for the public planning API with fixture binaries:
  solved, unsolvable, parser failure, grounder failure, engine failure, invalid
  argument/options, and cleanup/payload behavior.
- Run local real-binary evidence against sibling `../chengdu/bin/pandapi-*` if
  available, keeping it separate from CI fixture evidence.

## 4. Out of Scope

- No public `wolong:verify` yet.
- No dispatch supervisor, `gen_statem`, concurrent dispatch isolation, or
  restart strategy; slice04 owns dispatch supervision.
- No Chengdu release download, checksum verification, or provisioning; arc03
  owns binary provisioning.
- No fallback to legacy `pandaPIparser`, `pandaPIgrounder`, or
  `pandaPIengine`.
- No diagnostic-prose classification.
- No broad config redesign. Use the existing app-env config and make any
  `opts` behavior narrow and explicit.
- No promise that a separate verifier has run. Slice05 owns the verification
  boundary decision.
- No action-sequence or decomposition-tree parsing unless the implementation
  can prove a stable machine-readable plan format with tests. If not proven,
  make that deferral explicit in OQ5 and the close bubble-up.

## 5. Public Contract Notes

The public entry point for this slice is:

```text
wolong:plan(DomainPath, ProblemPath, Opts)
```

`DomainPath` and `ProblemPath` should follow the same path-string expectations
as `wolong:validate/2`.

`Opts` must have an explicit accepted shape. An empty map or empty list is a
reasonable starting point. Unsupported options should produce a typed
`invalid-option` or `unsupported-option` result rather than being silently
ignored.

For solved results, the public `Plan` must remain useful even when
`workdir.keep-artifacts=false` removes the dispatch workspace. A result that
only points at a now-deleted `engine.plan` path is not sufficient. Capture the
engine plan payload, copy the artifact, or otherwise return a durable public
plan value before cleanup.

For valid no-plan results, return public `#(unsolvable Detail)`, preserving the
engine status/provenance and absence of a plan artifact as meaningful domain
metadata. Do not return `#(error ...)` for `domain_no_plan`.

For gate failures, preserve the failing gate and reason:

```text
#(error #(parser Reason Detail))
#(error #(grounder Reason Detail))
#(error #(engine Reason Detail))
#(error #(workspace Reason Detail))
```

The exact `Detail` shape may evolve, but it must remain structured and
matchable.

## 6. Verification Approach

Primary coverage is Common Test:

```bash
rebar3 as test ct
```

Add a suite such as:

```text
test/wolong_plan_SUITE.lfe
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

- public `wolong:plan/3` export and no accidental public `wolong:verify`;
- solved result payload survives `keep-artifacts=false`;
- no direct `wolong-exec` calls in the public adapter;
- no diagnostic-prose classification;
- no legacy binary names in runtime paths;
- `wolong:validate/2` compatibility remains intact.

## 7. Exit Criteria

- Public `wolong:plan/3` exists, is exported, and delegates to the internal
  pipeline substrate rather than re-implementing gate execution.
- Public option handling is explicit: accepted empty/default options work, and
  malformed or unsupported options return typed errors before dispatch.
- Solved fixture returns public `#(ok Plan)` with a durable plan payload,
  artifact/provenance metadata, and an explicit verification-boundary field.
- The solved public plan remains usable when `workdir.keep-artifacts=false`.
- Valid no-plan fixture returns public `#(unsolvable Detail)`, not
  `#(domain-no-plan ...)` and not `#(error ...)`.
- Parser, grounder, and engine failures return typed public errors naming the
  failing gate and preserving structured details.
- `wolong:validate/2` remains compatible with existing tests.
- OQ5 is dispositioned in the closing bubble-up: the solved-plan term is
  defined, and any action-sequence/decomposition parsing deferral has a reason
  and re-entry condition.
- Local gates and CI are green; real Chengdu binary evidence is honestly
  separated from CI fixture evidence.
- The slice closes without adding public verification, dispatch supervision,
  release provisioning, or legacy binary fallback.
