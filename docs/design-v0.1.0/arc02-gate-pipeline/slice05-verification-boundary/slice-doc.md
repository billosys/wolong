# Slice 05 (wolong arc02): verification-boundary

> Open-set plan-of-record for `slice05-verification-boundary`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened 2026-08-15.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Resolve Arc02's public verification boundary honestly.

At slice close, Wolong's public docs and API must no longer imply that a
separate verifier, action-sequence parser, or decomposition-tree parser exists
when the current supported Chengdu 0.3.0 managed-process surface exposes only:

```text
pandapi-parser -> pandapi-grounder -> pandapi-engine
```

The likely outcome for this slice is explicit deferral: keep `wolong:verify`
out of the 0.1.0 public API, preserve solved plan metadata that says
`separate-verifier=not-run`, and update README/project/arc wording with a
concrete re-entry condition.

If CC discovers a currently supported Chengdu verifier contract in the live
0.3.0 pre-release docs or binaries, pause and report before implementing it.
Adding a verifier would be a different slice shape with more code, fixtures,
and acceptance criteria than this open set assumes.

## 2. Context From Earlier Slices

- Arc01 proved process execution through erlexec and parser validation.
- Arc02 slice01 shared the current `pandapi-*` gate contract: parser, grounder,
  engine, status-field classification, and binary lookup.
- Arc02 slice02 added the per-dispatch workspace and internal
  parse -> ground -> solve pipeline.
- Arc02 slice03 added public `wolong:plan/3` and `plan/2`; solved results
  include durable plan payload bytes, provenance, workspace metadata, and a
  `verification-boundary` map with `separate-verifier=not-run`,
  `action-sequence=deferred`, and `decomposition-tree=deferred`.
- Arc02 slice04 routed public planning through supervised one-shot dispatch
  workers without changing the public solved/no-plan/error shapes.
- The current README is stale: it still describes the old five-gate
  parse -> ground -> solve -> convert -> verify sequence and says no
  `plan`/`verify`/`validate` API exists yet.

## 3. In Scope

- Re-survey the current Chengdu 0.3.0 pre-release CLI and managed-process
  surfaces:
  - `../chengdu/docs/reference/cli.md`
  - `../chengdu/docs/managed-process.md`
  - `../chengdu/bin/pandapi-parser`
  - `../chengdu/bin/pandapi-grounder`
  - `../chengdu/bin/pandapi-engine`
- Resolve Arc02 OQ1 in `../arc-plan.md`.
- Update `docs/design-v0.1.0/project-plan.md` so the 0.1.0 implemented public
  surface is truthful:
  - `wolong:validate/2` is parser validation;
  - `wolong:plan/2` and `wolong:plan/3` run the supported parse -> ground ->
    solve chain and return solved, unsolvable, or typed errors;
  - `wolong:verify` is deferred unless a supported verifier contract is
    proven;
  - action-sequence and decomposition-tree parsing are deferred unless a
    stable supported contract is proven.
- Update `README.md` to reflect current project status and current binary
  names:
  - arc01 closed, arc02 nearly closed, arc03 provisioning still future;
  - current dev binaries are `pandapi-parser`, `pandapi-grounder`, and
    `pandapi-engine`;
  - public `plan` and `validate` exist;
  - public verification is explicit metadata/deferral, not an implemented
    verifier claim.
- Preserve `wolong:plan` public result behavior and tests:
  - solved results carry `verification-boundary.separate-verifier=not-run`;
  - no-plan remains `#(unsolvable Detail)`;
  - typed gate and dispatch errors remain typed.
- Add or tighten tests/checks only where needed to make the boundary
  falsifiable. Prefer narrow CT assertions and grep-verifiable documentation
  checks over broad rewrites.

## 4. Out of Scope

- No public `wolong:verify` unless a currently supported Chengdu verifier
  contract is proven first and the operator accepts rescoping.
- No claim that a separate verifier ran.
- No action-sequence parser.
- No decomposition-tree parser.
- No plan-format parser beyond preserving the current durable plan payload.
- No diagnostic-prose classification.
- No release download, checksum verification, binary provisioning, or
  hex.pm/package work.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No planner pooling, queueing policy, back-pressure API, or distributed
  Erlang.
- No broad public options redesign.
- No repo-wide formatting sweep. The formatter exists, but the current tree is
  not formatter-normalized.

## 5. Design Constraints

This slice is about public truth, not feature expansion.

The project invariant remains: Wolong must not return a confident verified
plan when no separate verification contract ran. The current implementation
satisfies that by returning a solved plan artifact plus explicit boundary
metadata. Slice05 should make the surrounding docs and arc/project plan match
that reality.

Do not delete historical context silently. If old five-gate or verifier
language is still useful as history, mark it as inherited/historical context
and replace the current implementation promise with the supported surface.

If source changes are needed, keep them minimal. Public adaptation remains in
`src/wolong.lfe`; pipeline, gate, exec, workspace, and dispatch ownership from
earlier slices should not move.

## 6. Verification Approach

Primary verification is source/doc inspection plus the existing local gates:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

Boundary checks should include targeted greps for:

- no public `wolong:verify` export or `defun`;
- `verification-boundary` still reports `separate-verifier=not-run`;
- README no longer claims the implemented sequence is
  parse -> ground -> solve -> convert -> verify;
- README no longer says `plan` or `validate` are absent;
- project/arc docs resolve verifier deferral with a re-entry condition;
- no action-sequence or decomposition-tree parser landed;
- no diagnostic-prose classifier landed;
- no release/provisioning/legacy-binary fallback landed.

Use Common Test for runtime assertions when runtime behavior is touched. If the
slice is docs-only except for test hardening, keep the test changes narrow and
run the full existing suite.

## 7. Exit Criteria

- Chengdu source survey is recorded: current supported 0.3.0 managed-process
  normal surfaces are parser, grounder, and engine; no separate supported
  verifier contract is accepted silently.
- Arc02 OQ1 is resolved in `arc-plan.md`.
- `project-plan.md` no longer promises implemented `wolong:verify`,
  action-sequence parsing, or decomposition-tree parsing for 0.1.0 unless
  backed by a supported contract.
- `README.md` reflects current status, current `pandapi-*` binary names, and
  current public API reality.
- Solved plans still carry explicit verification-boundary metadata with
  `separate-verifier=not-run`.
- No public `wolong:verify` lands on the deferral path.
- No diagnostic-prose classifier, release provisioning, legacy binary fallback,
  action parser, or decomposition parser lands.
- Local gates and CI are green.
- A meaningful tamper cycle proves the boundary checks would fail if the
  verifier claim regressed.
