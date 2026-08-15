# CDC Verification: Slice 03 Plan API

Verified by CDC on 2026-08-15.

Reviewed commits:

- `f5b1a9dbb744c16da8d437f4a2e45f48e577a3de` -
  `Implement public plan API`
- `e0e28ad3153df5c7bdc8e10f1a3bd368386e7c21` -
  `Close plan API slice`

CDC result: accepted.

## Scope Reviewed

Changed files from the slice open commit:

```text
docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md
docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/closing-report.md
docs/design-v0.1.0/arc02-gate-pipeline/slice03-plan-api/ledger.md
src/wolong-pipeline.lfe
src/wolong.lfe
test/wolong_plan_SUITE.lfe
```

`git diff --check 192bf8c..e0e28ad` passed.

The close set contains the expected `closing-report.md`; CC did not create
this CDC verification file. The ledger still has 16 rows and all 16 are final
`done`.

## Reproduced Gates

Local gates reproduced:

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

passed: all 52 tests passed, including:

```text
%%% wolong_plan_SUITE: ..........
```

```text
rebar3 xref
```

passed.

```text
rebar3 dialyzer
```

exited 0 after success typing analysis.

Remote close-out CI was checked through GitHub Actions API:

- run `31856451630`
- head SHA `e0e28ad3153df5c7bdc8e10f1a3bd368386e7c21`
- `build (ubuntu-22.04)`: success
- `build (macos-15)`: success
- both jobs completed compile, EUnit, Common Test, xref, and Dialyzer.

## Source Checks

`src/wolong.lfe` now exports `plan/2`, `plan/3`, and `validate/2`.

Observed API shape:

- `plan/2` delegates to `plan/3` with an empty map.
- `plan/3` validates path and option shape before dispatch.
- `plan/3` delegates to `wolong-pipeline:run/2`.
- `validate/2` remains parser-only and does not route through the full
  pipeline.

`src/wolong.lfe` has no direct `wolong-exec`, argv-builder, workspace creation,
or cleanup calls. The public module remains an adapter over the lower pipeline
substrate.

Solved plan behavior is implemented by capturing `plan-payload` in
`wolong-pipeline:attach-plan-payload/1` before cleanup. The public plan map
contains:

- `outcome`
- durable `payload`
- `payload-bytes`
- engine `artifact`
- gate `provenance`
- `workspace`
- `verification-boundary`

The public boundary translates internal `#(domain-no-plan Detail)` to
`#(unsolvable Detail)`.

Scope fence checks found forbidden terms only in slice planning/closing prose,
not as implementation additions. No public `wolong:verify`, `gen_statem`,
dispatch worker/supervisor, release downloader/provisioner, legacy
`pandaPI*` runtime fallback, or diagnostic-prose classifier landed.

## Tamper Reproduction

CDC reproduced the tamper row by temporarily changing:

```text
#(domain-no-plan Detail) -> #(domain-no-plan Detail)
```

instead of the public:

```text
#(domain-no-plan Detail) -> #(unsolvable Detail)
```

The owning suite failed nonzero:

```text
rebar3 as test ct --suite test/wolong_plan_SUITE.lfe
```

failure:

```text
%%% wolong_plan_SUITE ==> no_plan_returns_unsolvable: FAILED
%%% wolong_plan_SUITE ==> {test_case_failed,{expected,unsolvable,actual,'domain-no-plan'}}
Failed 1 tests. Passed 9 tests.
```

After restoring the implementation, the same isolated suite passed:

```text
%%% wolong_plan_SUITE: ..........
All 10 tests passed.
```

## Local Chengdu Binary Check

The sibling Chengdu binaries are present and identify as the expected 0.3.0
pre-release managed commands:

```text
../chengdu/bin/pandapi-parser --version
../chengdu/bin/pandapi-grounder --version
../chengdu/bin/pandapi-engine --version
```

all exited 0 and reported `managed_process_contract=0.3.0`.

CDC did not claim independent reproduction of CC's full local real-binary
`wolong:plan/3` probe. A local LFE eval attempt against the real Chengdu
pipeline was killed with exit 137 before producing output. This does not block
slice closure because the slice acceptance evidence is the checked-in fixture
CT suite plus remote CI; real Chengdu binary evidence remains explicitly
local-only and supplemental until arc03 release provisioning.

## Ledger Disposition

| Row | CDC disposition |
|-----|-----------------|
| PA-1 | accepted |
| PA-2 | accepted |
| PA-3 | accepted |
| PA-4 | accepted |
| PA-5 | accepted |
| PA-6 | accepted |
| PA-7 | accepted |
| PA-8 | accepted |
| PA-9 | accepted |
| PA-10 | accepted |
| PA-11 | accepted |
| PA-12 | accepted |
| PA-13 | accepted |
| PA-14 | accepted |
| PA-15 | accepted |
| PA-16 | accepted |

Rows: 16. Accepted: 16. Rejected: 0. Deferred: 0.

## Notes For Next Slice

- Slice04 can wrap the public adapter with dispatch supervision, but should
  preserve the public `#(ok Plan)`, `#(unsolvable Detail)`, and typed
  `#(error #(Gate Reason Detail))` shapes.
- The `verification-boundary.separate-verifier=not-run` field is load-bearing
  for Slice05; do not let Slice04 supervision language imply verified-plan
  semantics.
- The CT suite uses fixed `/tmp/wolong-plan-*` base directories with unique
  dispatch subdirectories. This reproduced locally and in CI; if future flakes
  appear, move the base directory generation to a per-test unique path.
