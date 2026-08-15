# CDC Verification: Slice 04 Dispatch Supervision

Verified by CDC on 2026-08-15.

Reviewed commits:

- `815b00f769f16ff57df80022d2b675b4151a7834` -
  `Implement dispatch supervision`
- `ad68aed98f4a1ce19dbb382673989a9c71011144` -
  `Close dispatch supervision slice`

CDC result: accepted.

## Scope Reviewed

Changed files from the slice open commit:

```text
docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md
docs/design-v0.1.0/arc02-gate-pipeline/slice04-dispatch-supervision/closing-report.md
docs/design-v0.1.0/arc02-gate-pipeline/slice04-dispatch-supervision/ledger.md
docs/design-v0.1.0/project-plan.md
src/wolong-dispatch-sup.lfe
src/wolong-dispatch-worker.lfe
src/wolong-dispatch.lfe
src/wolong-sup.lfe
src/wolong.app.src
src/wolong.lfe
test/fixtures/gate-contract-substrate/engine-timeout/domain.hddl
test/fixtures/gate-contract-substrate/engine-timeout/problem.hddl
test/fixtures/gate-contract-substrate/pandapi-engine-fixture.sh
test/fixtures/gate-contract-substrate/pandapi-grounder-fixture.sh
test/fixtures/gate-contract-substrate/pandapi-parser-fixture.sh
test/fixtures/gate-contract-substrate/slow-success/domain.hddl
test/fixtures/gate-contract-substrate/slow-success/problem.hddl
test/wolong_dispatch_SUITE.lfe
```

The close set contains the expected `closing-report.md`; CC did not create
this CDC verification file. The ledger has 18 rows. Rows DS-1 through DS-16
and DS-18 are `done`; DS-17 was correctly left as local-done/CI-not-triggered
until CDC pushed the CC commits and reproduced remote CI.

## Reproduced Gates

Local gates reproduced at `ad68aed98f4a1ce19dbb382673989a9c71011144`:

```text
rebar3 compile
```

passed.

```text
rebar3 as test eunit
```

passed: 9 tests, 0 failures.

```text
rebar3 as test ct
```

passed: all 62 tests passed, including:

```text
%%% wolong_dispatch_SUITE: ..........
```

```text
rebar3 xref
```

passed.

```text
rebar3 dialyzer
```

exited 0 after success typing analysis.

Remote close-out CI was checked with GitHub Actions:

- run `31899697705`
- head SHA `ad68aed98f4a1ce19dbb382673989a9c71011144`
- URL: `https://github.com/billosys/wolong/actions/runs/31899697705`
- `build (ubuntu-22.04)`: success
- `build (macos-15)`: success

Both jobs completed compile, EUnit, Common Test, xref, and Dialyzer.

## Source Checks

The supervision topology is present and narrow:

- `wolong-sup` starts registered permanent child supervisor
  `wolong-dispatch-sup`.
- `wolong-dispatch-sup` uses `simple_one_for_one` with temporary
  `wolong-dispatch-worker` children.
- each worker receives one request, calls `wolong-pipeline:run/2`, sends one
  result back to the caller, and exits normally.

Public API routing is as specified:

- `wolong:plan/2` remains only a wrapper over `wolong:plan/3`.
- `wolong:plan/3` validates input and routes through `wolong-dispatch:run/2`.
- `wolong:validate/2` remains parser-only and does not use dispatch.

Dispatch modules were checked for duplicated lower-layer responsibilities.
No matches were found in `src/wolong-dispatch*.lfe` for:

```text
parser-argv
grounder-argv
engine-argv
wolong-exec
make_dir
del_dir_r
```

Scope-fence checks found forbidden terms only in planning prose or the
pre-existing public verification-boundary deferral fields. No public
`wolong:verify`, release provisioning, legacy `pandaPI*` runtime fallback,
diagnostic-prose classifier, pool/queue/distribution model, action parser, or
decomposition parser landed.

## Behavioral Checks

`test/wolong_dispatch_SUITE.lfe` exercises the slice through the existing
Common Test tree. CDC inspected and reproduced coverage for:

- application start with `wolong-dispatch-sup` under `wolong-sup`;
- public solved/no-plan shapes through supervised dispatch;
- parser, grounder, engine, binary, config, and workspace typed errors;
- engine timeout with bounded stdout/stderr detail;
- TERM-resistant timeout cleanup plus later successful dispatch;
- synthetic worker crash returning typed dispatch failure while the app and
  supervisor remain usable;
- concurrent dispatches with distinct workers and workspaces;
- concurrent timeout plus success without result corruption;
- terminal success, failure, timeout, and crash draining worker count to zero;
- `wolong:validate/2` remaining parser-only.

The project-plan W4 wording and arc-plan v1.4 correctly reflect the selected
policy: one-shot worker crashes are typed and isolated rather than replayed.

## Tamper Reproduction

CDC reproduced the tamper row by temporarily changing `wolong:plan/3` from:

```text
wolong-dispatch:run
```

to:

```text
wolong-pipeline:run
```

The owning suite failed nonzero:

```text
rebar3 as test ct --suite test/wolong_dispatch_SUITE.lfe
```

failures:

```text
solved_and_no_plan_preserve_public_shapes:
  {test_case_failed,{unexpected,undefined}}

engine_timeout_is_typed_with_bounded_detail:
  {badkey,dispatch}

concurrent_dispatches_use_distinct_workers_and_workspaces:
  {test_case_failed,{'expected-at-least',2,actual,0}}

Failed 3 tests. Passed 7 tests.
```

After restoring the implementation, the same isolated suite passed:

```text
%%% wolong_dispatch_SUITE: ..........
All 10 tests passed.
```

## Ledger Disposition

| Row | CDC disposition |
|-----|-----------------|
| DS-1 | accepted |
| DS-2 | accepted |
| DS-3 | accepted |
| DS-4 | accepted |
| DS-5 | accepted |
| DS-6 | accepted |
| DS-7 | accepted |
| DS-8 | accepted |
| DS-9 | accepted |
| DS-10 | accepted |
| DS-11 | accepted |
| DS-12 | accepted |
| DS-13 | accepted |
| DS-14 | accepted |
| DS-15 | accepted |
| DS-16 | accepted |
| DS-17 | accepted |
| DS-18 | accepted |

Rows: 18. Accepted: 18. Rejected: 0. Deferred: 0.

## Notes For Next Slice

- Slice05 owns the verification boundary. Dispatch supervision must not be
  allowed to imply a verified-plan result.
- Preserve `verification-boundary.separate-verifier=not-run` unless Slice05
  implements a supported verifier contract.
- The selected dispatch crash policy is no replay: typed worker failure,
  supervisor remains alive, later dispatches start normally.

## Closure

CDC closes slice04 at
`ad68aed98f4a1ce19dbb382673989a9c71011144`. This document records the
independent verification.
