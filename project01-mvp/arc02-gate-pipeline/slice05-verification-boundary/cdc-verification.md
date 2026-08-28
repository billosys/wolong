# CDC Verification: Slice 05 Verification Boundary

Verified by CDC on 2026-08-19.

Reviewed commits:

- `b33ee7ec5e7f0f84ed97d94e35d2c92bae47abf5` -
  `Resolve verification boundary docs`
- `0693815347233ac146343941e292deb2d6bf2196` -
  `Close verification boundary slice`
- `a86e0aa` - `Format LFE sources and tests`
- `a84cf14` - `Updated formatting instructions.`

CDC result: accepted.

## Scope Reviewed

Changed files from the slice open commit `e0636ac` to pushed `main`:

```text
AGENTS.md
README.md
docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md
docs/design-v0.1.0/arc02-gate-pipeline/slice05-verification-boundary/closing-report.md
docs/design-v0.1.0/arc02-gate-pipeline/slice05-verification-boundary/ledger.md
docs/design-v0.1.0/project-plan.md
src/wolong-binaries.lfe
src/wolong-config.lfe
src/wolong-dispatch-sup.lfe
src/wolong-dispatch-worker.lfe
src/wolong-dispatch.lfe
src/wolong-exec.lfe
src/wolong-gate.lfe
src/wolong-pipeline.lfe
src/wolong-status.lfe
src/wolong-sup.lfe
src/wolong-workspace.lfe
src/wolong.lfe
test/unit-wolong-config-tests.lfe
test/wolong-test-log-collector.lfe
test/wolong_dispatch_SUITE.lfe
test/wolong_exec_SUITE.lfe
test/wolong_gate_SUITE.lfe
test/wolong_parser_SUITE.lfe
test/wolong_pipeline_SUITE.lfe
test/wolong_plan_SUITE.lfe
```

`git diff --check e0636ac..a84cf14` passed. The broad LFE source/test changes
are isolated in the formatter commit `a86e0aa`; the verification-boundary slice
itself is docs-boundary work. `a84cf14` updates standing formatter instructions.

The close set contains the expected `closing-report.md`; CC did not create this
CDC verification file. The ledger has 16 rows. CDC updated VB-14 after pushing
and reproducing remote CI.

## Reproduced Gates

Local gates reproduced on the current committed tree:

```text
rebar3 compile
```

passed.

```text
rebar3 as test eunit
```

passed: 9 tests, 0 failures. The command printed transient BEAM
`not_purged`/sticky-dir reports while still exiting 0; the separate compile
gate was clean.

```text
rebar3 as test ct
```

passed: all 62 tests passed.

```text
rebar3 xref
```

passed.

```text
rebar3 dialyzer
```

exited 0 after success typing analysis.

Remote CI was checked with GitHub Actions:

- run `32327496023`
- head SHA `a84cf14`
- URL: `https://github.com/billosys/wolong/actions/runs/32327496023`
- `build (ubuntu-22.04)`: success
- `build (macos-15)`: success

Both jobs completed compile, EUnit, Common Test, xref, and Dialyzer.

## Chengdu Survey

CDC reproduced the supported-surface survey:

- `../chengdu/bin` contains executable `pandapi-parser`, `pandapi-grounder`,
  and `pandapi-engine`.
- `../chengdu/docs/reference/cli.md` lists those three `pandapi-*` commands as
  the supported normal surfaces.
- `../chengdu/docs/managed-process.md` describes supervised parser, grounder,
  and engine integration.
- `--help` for all three local binaries exited 0 and described only parser,
  grounder, or engine supported surface.
- `--version` for all three local binaries exited 0 and reported
  `managed_process_contract=0.3.0`.

No supported verifier surface was found, so the deferral path is correct.

## Source And Documentation Checks

The public boundary is honest in the plan documents:

- `arc-plan.md` resolves OQ1 as `RESOLVED - verifier deferred` and adds v1.5
  version history naming slice05.
- `project-plan.md` lists the implemented 0.1.0 public surface as
  `wolong:validate/2`, `wolong:plan/2`, and `wolong:plan/3`; public
  `wolong:verify` is deferred with a re-entry condition.
- README names the current `pandapi-parser -> pandapi-grounder ->
  pandapi-engine` chain, documents `validate` and `plan`, and defers `verify`.

Absence checks reproduced:

```text
rg -n 'defun verify|\(verify [0-9]|wolong:verify' src test
```

exited 1 with no matches.

```text
rg -n 'parse -> ground -> solve -> convert -> verify|parse.*convert.*verify' README.md
```

exited 1 with no matches.

```text
rg -n 'pandaPIparser|pandaPIgrounder|pandaPIengine' README.md src test
```

exited 1 with no matches.

`action-sequence` and `decomposition-tree` hits in `src` and `test` remain
limited to boundary metadata and assertions, not parser implementations. No
diagnostic-prose classifier, release provisioning, downloader, checksum
verifier, hex packaging, or legacy binary fallback landed.

## Tamper Reproduction

CDC reproduced the tamper row by temporarily changing
`src/wolong.lfe` from:

```text
separate-verifier not-run
```

to:

```text
separate-verifier skipped
```

The owning suite failed nonzero:

```text
rebar3 as test ct --suite test/wolong_plan_SUITE.lfe
```

failure:

```text
solved_plan3_returns_public_plan:
  {test_case_failed,{expected,'not-run',actual,skipped}}
Failed 1 tests. Passed 9 tests.
```

After restoring the implementation, the same isolated suite passed:

```text
%%% wolong_plan_SUITE: ..........
All 10 tests passed.
```

## Ledger Disposition

| Row | CDC disposition |
|-----|-----------------|
| VB-1 | accepted |
| VB-2 | accepted |
| VB-3 | accepted |
| VB-4 | accepted |
| VB-5 | accepted |
| VB-6 | accepted |
| VB-7 | accepted |
| VB-8 | accepted |
| VB-9 | accepted |
| VB-10 | accepted |
| VB-11 | accepted |
| VB-12 | accepted |
| VB-13 | accepted |
| VB-14 | accepted |
| VB-15 | accepted |
| VB-16 | accepted |

Rows: 16. Accepted: 16. Rejected: 0. Deferred: 0.

## Bubble-up Check

Slice05 delivered the assigned verification-boundary piece of Arc02: it resolved
OQ1 without inventing an unsupported verifier surface, kept public `wolong:verify`
out of the implemented API, preserved `verification-boundary.separate-verifier=not-run`,
and made action/decomposition parsing explicit deferrals.

The silent-drop diff is complete: no public verifier, no separate-verifier claim,
no action/decomposition parser, no diagnostic-prose classifier, no provisioning,
no legacy `pandaPI*` fallback, and no pool/queue/distribution work landed.

No further arc-plan change is required before arc close. Arc03 still owns binary
release provisioning and checksum/download evidence.

## Notes For Arc Close

- Arc02 is ready for an arc-level composition close.
- Arc close should reproduce the arc ledger composition rows, not merely inherit
  the five slice closures.
- Keep the public contract phrased as validated solved plan or explicit
  unsolvable, with verifier deferral visible until a supported verifier contract
  exists.
