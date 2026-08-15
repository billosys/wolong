# Slice 04 (wolong arc02): dispatch-supervision

> Open-set plan-of-record for `slice04-dispatch-supervision`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened 2026-08-15.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Put each public planning dispatch under OTP supervision without changing the
public planning contract delivered by Slice03.

At slice close, calls to `wolong:plan/3` should run through a supervised
dispatch boundary that starts one dispatch worker per planning request,
preserves timeout/no-zombie behavior at engine scale, isolates concurrent
dispatches, and keeps the application supervision tree alive after failed,
timed-out, or crashing dispatches.

The external API must remain:

- `#(ok Plan)` for solved inputs;
- `#(unsolvable Detail)` for valid no-plan outcomes;
- `#(error #(Gate Reason Detail))` or a typed dispatch/workspace/config error
  for failures.

The verification boundary must remain explicit. A supervised dispatch is not a
plan verifier.

## 2. Context From Earlier Slices

- Arc01 proved the generic erlexec runner: argv-list execution, stdout/stderr
  separation, output caps, process-group timeout cleanup, no-zombie behavior,
  and post-failure recovery.
- Arc02 slice01 created shared gate classification over the current
  `pandapi-parser`, `pandapi-grounder`, and `pandapi-engine` managed-process
  contract.
- Arc02 slice02 created the internal workspace/pipeline substrate:
  per-dispatch workspaces, explicit artifact roles, cleanup/keep policy,
  short-circuit gate behavior, and internal `domain-no-plan`.
- Arc02 slice03 created public `wolong:plan/3` and `plan/2`, with solved plan
  payload capture before cleanup, public `#(unsolvable Detail)`, and explicit
  `verification-boundary.separate-verifier=not-run`.
- Slice03 CDC verification notes a small future-flake guard: plan CT currently
  uses fixed `/tmp/wolong-plan-*` base directories plus unique dispatch
  subdirectories. Slice04 concurrency tests should prefer per-test unique base
  directories.

## 3. In Scope

- Add an OTP supervision boundary for planning dispatches under the existing
  Wolong application supervision tree.
- Add a supervised dispatch worker or equivalent supervised one-shot child for
  each `wolong:plan/3` call.
- Route public `wolong:plan/3` through the supervised dispatch boundary while
  preserving `wolong:plan/2` as a default wrapper and `wolong:validate/2` as
  parser-only validation.
- Keep the actual gate execution and workspace orchestration in the existing
  pipeline/gate/exec substrate. Dispatch supervision should wrap the pipeline,
  not duplicate it.
- Define public behavior for dispatch-worker crashes as a typed, matchable
  result that does not take down the application or corrupt other dispatches.
- Prove engine-scale timeout behavior through the public planning API:
  timeout returns a typed engine timeout, the OS process group is gone, and a
  later dispatch succeeds.
- Prove concurrent dispatch isolation: independent workers, independent
  workspaces, no artifact collision, and no cross-contamination between a
  successful dispatch and a failing or timed-out dispatch.
- Prove no lingering dispatch workers after success, failure, timeout, or
  crash.
- Add Common Test coverage for app/supervision/dispatch behavior in the
  existing `test` tree.
- Preserve local-only real Chengdu binary evidence as supplemental. Remote CI
  must continue using Wolong-owned fixtures and must not depend on
  `../chengdu`.

## 4. Out of Scope

- No public `wolong:verify`.
- No claim that a separate verifier ran.
- No release download, checksum verification, or binary provisioning.
- No planner pooling, queueing policy, back-pressure API, global dispatcher,
  or distributed Erlang.
- No broad public options redesign. Only add options if required to exercise
  supervised dispatch behavior, and keep them explicit and tested.
- No fallback to legacy `pandaPIparser`, `pandaPIgrounder`, or
  `pandaPIengine`.
- No diagnostic-prose classification.
- No action-sequence or decomposition-tree parsing.
- No rewrite of the existing erlexec runner, gate mapper, or pipeline unless a
  narrow seam is needed for supervised dispatch.

## 5. Design Constraints

The supervision tree should remain small and legible. Supervisors should wire
children and keep restart policy; business logic belongs in workers or the
existing pipeline.

Each planning dispatch should have one clear owner process. If the
implementation uses a `gen_server` or similar behavior, long-running planning
work must not block a shared coordinator process that serializes unrelated
dispatches. One slow or hung engine must not prevent another dispatch from
starting or completing.

The worker restart policy must be explicit. One-shot dispatch workers are not
ordinary permanent services; if CC chooses `temporary`, `transient`, or another
strategy, the closing report must explain how that choice satisfies the
project's crash-isolation goal without accidentally re-running a completed or
externally side-effectful planning request. If crash restart of the same
request is implemented, tests must prove the caller receives one coherent
typed result and no duplicate artifact ownership leaks.

Public result adaptation remains owned at the public API boundary. The
supervised dispatch layer may return internal dispatch details, but callers of
`wolong:plan/3` must still see the Slice03 public contract.

## 6. Verification Approach

Primary coverage is Common Test:

```bash
rebar3 as test ct
```

Add a suite such as:

```text
test/wolong_dispatch_SUITE.lfe
```

or extend an existing CT suite only if the resulting suite remains clearly
organized around supervision and dispatch behavior.

Required CT scenarios:

- application starts with the dispatch supervisor alive under `wolong-sup`;
- public solved and no-plan calls still return the Slice03 shapes through the
  supervised path;
- a parser, grounder, or engine failure returns a typed public error and the
  dispatch supervisor remains alive;
- an engine timeout through the public planning API kills the OS process group,
  leaves no zombie, and a later dispatch succeeds;
- a synthetic dispatch-worker crash is isolated and returns a typed dispatch
  error or other ledgered typed result;
- concurrent dispatches use distinct workers and workspaces;
- one concurrent failure or timeout does not corrupt a concurrent success;
- completed, failed, timed-out, and crashing dispatches do not leave live
  dispatch worker children behind;
- `wolong:validate/2` remains parser-only.

CDC should independently re-run:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

CDC should also inspect source for:

- dispatch supervisor child spec under `wolong-sup`;
- public `wolong:plan/3` routing through the dispatch boundary;
- no duplicated gate execution in the dispatch layer;
- no public `wolong:verify`;
- no diagnostic-prose classifier;
- preservation of `verification-boundary.separate-verifier=not-run`.

## 7. Exit Criteria

- The Wolong application supervision tree includes a clear dispatch
  supervision boundary.
- Public `wolong:plan/3` runs through supervised dispatch and preserves
  `wolong:plan/2` and `wolong:validate/2` compatibility.
- Solved, unsolvable, and typed gate-error public result shapes are unchanged
  from Slice03.
- Engine timeout through the public planning API returns a typed timeout,
  cleans up the OS process group, leaves no surviving child process, and a
  subsequent dispatch succeeds.
- Concurrent dispatches are isolated by worker and workspace; one failure or
  timeout does not take down the app or corrupt another dispatch.
- Dispatch-worker crashes are isolated and reported as typed results or a
  clearly ledgered typed failure shape.
- No live dispatch worker children remain after terminal public results.
- The verification boundary remains explicit and no public `wolong:verify`
  lands in this slice.
- Local gates and CI are green.
