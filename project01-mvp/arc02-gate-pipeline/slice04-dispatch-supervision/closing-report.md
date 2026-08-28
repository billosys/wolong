# Slice 04 Closing Report: Dispatch Supervision

Closed by CC on 2026-08-15.

Implementation commit:
`815b00f769f16ff57df80022d2b675b4151a7834`
(`Implement dispatch supervision`).

CI evidence:
No new GitHub Actions run was triggered by CC. The implementation commit is
local on `main`, ahead of `origin/main`; remote Ubuntu/macOS CI should be
recorded after push. CI uses checked-in Wolong fixture executables and does not
depend on `../chengdu`.

## Per-Row Walk

| Row | Status | Evidence |
|-----|--------|----------|
| DS-1 | done | `wolong-sup` now owns permanent child supervisor `wolong-dispatch-sup`; dispatch CT `app_start_has_dispatch_supervision` passed. |
| DS-2 | done | `wolong:plan/3` routes valid requests through `wolong-dispatch:run/2`; `plan/2` remains a default wrapper. Tamper routing directly to `wolong-pipeline:run/2` failed dispatch CT. |
| DS-3 | done | `wolong:validate/2` remains parser-only and dispatch-free; CT proved it succeeds with only the parser binary configured. |
| DS-4 | done | Dispatch worker delegates exactly one request to `wolong-pipeline:run/2`; no argv/status/erlexec/workspace/cleanup logic was duplicated in dispatch modules. |
| DS-5 | done | Public solved/no-plan shapes remain `#(ok Plan)` and `#(unsolvable Detail)`; solved plans retain payload, provenance, workspace, and `verification-boundary`. |
| DS-6 | done | Public supervised failures remain typed for parser, grounder, engine, binary, config, and workspace boundaries. |
| DS-7 | done | Engine timeout returns `#(error #(engine timeout Detail))` with bounded stdout/stderr details retained. |
| DS-8 | done | TERM-resistant timeout fixture leaves no surviving OS process by `kill -0` wait and a later solved dispatch succeeds. |
| DS-9 | done | Synthetic worker crash returns `#(error #(dispatch worker-exit Detail))`; supervisor/app stay available and a later plan succeeds. |
| DS-10 | done | Overlapping slow-success dispatches use distinct worker PIDs and workspace paths. |
| DS-11 | done | Concurrent timeout plus success preserves the success result and returns the timeout as a typed engine error. |
| DS-12 | done | Success, parser failure, timeout, and crash cases all drain dispatch worker children back to zero. |
| DS-13 | done | Worker child spec uses `restart=temporary`, `shutdown=5000`, `type=worker`; this report records the lifecycle rationale. |
| DS-14 | done | Solved public plans still carry `separate-verifier=not-run`; no public `wolong:verify` was added. |
| DS-15 | done | Scope stayed within dispatch supervision: no release provisioning, legacy runtime fallback, diagnostic-prose classifier, planner pool/global queue/distribution, or action/decomposition parser was added. |
| DS-16 | done | New supervision coverage lives in `test/wolong_dispatch_SUITE.lfe`; EUnit remains for unit/ltest coverage. |
| DS-17 | done-local; ci-not-triggered | Local gates passed: compile; EUnit 9 tests; CT 62 tests; xref; Dialyzer. Remote CI was not triggered because the commit has not been pushed. |
| DS-18 | done | Tamper bypassed dispatch routing and dispatch CT failed nonzero with 3 failures; after revert, dispatch CT passed 10/10. |

Rows: 18. Done: 17. Done-local/CI-not-triggered: 1. Deferred: 0. No-op: 0.

## Worker Lifecycle

The dispatch supervisor is permanent under `wolong-sup`; dispatch workers are
temporary, one-shot `gen_server` children. A worker owns exactly one request,
calls `wolong-pipeline:run/2`, sends one result to the caller, then exits
normally.

Temporary restart is intentional. A crashed worker returns a typed dispatch
failure to its caller and is not replayed, avoiding duplicate planner side
effects or duplicate artifact ownership. Crash isolation is provided by the
supervisor boundary staying alive and accepting later dispatches.

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

Tamper:

```text
tamper: route wolong:plan/3 directly to wolong-pipeline:run/2
rebar3 as test ct --suite test/wolong_dispatch_SUITE.lfe
Failed 3 tests. Passed 7 tests.
failures: missing dispatch metadata; missing timeout dispatch detail; expected overlapping worker count >= 2 but actual 0

after revert:
rebar3 as test ct --suite test/wolong_dispatch_SUITE.lfe
All 10 tests passed.
```

## Bubble-Up to the Arc

- Slice04 delivered the `dispatch-supervision` line in `arc-plan.md`: each
  public planning dispatch now runs through an OTP-supervised dispatch boundary,
  with timeout/no-zombie recovery and concurrent dispatch isolation covered by
  CT.
- Arc ledger W4/A6 should be read as crash isolation plus subsequent dispatch
  recovery, not automatic replay of a crashed one-shot planning request.
  Temporary workers are the chosen policy because replay could duplicate
  externally visible planner side effects and artifact ownership.
- Slice05 must preserve `verification-boundary.separate-verifier=not-run` until
  it either implements a supported verifier contract or explicitly keeps
  verification deferred in project/README wording.
- Project-plan W4 wording should be clarified from "restarts a crashed dispatch
  worker" to "isolates a crashed one-shot dispatch worker, keeps the app alive,
  and starts later dispatch workers normally." The implemented behavior is
  stricter about not replaying a failed request.
- Scope-as-specified equals scope-as-delivered except remote CI: no release
  provisioning, legacy binary fallback, diagnostic-prose classifier,
  long-lived planner pool, global queue, distribution, action parser, or
  decomposition parser was added. Remote CI remains to be recorded after push.

CDC verification remains separate; no `cdc-verification.md` was created by CC.
