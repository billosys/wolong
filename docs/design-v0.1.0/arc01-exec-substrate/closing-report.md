# wolong arc01 - exec-substrate - closing report

> Arc close prepared by CDC on 2026-08-14, per
> `PROJECT-MANAGEMENT.md` v2.1 and `LEDGER-DISCIPLINE.md` v2.0. Parent:
> [`../project-plan.md`](../project-plan.md). Plan:
> [`arc-plan.md`](./arc-plan.md).

## Verdict

Arc01 closes as delivered.

The three planned slices are closed, the arc ledger rows A1-A4 are discharged,
and the arc composes into the promised substrate: wolong can run one
supervised pandaPI process through erlexec and return typed results with
timeout/kill behavior and parser exit/status mapping proven.

## Slice Walk

| Slice | Status | Evidence | Notes |
|-------|--------|----------|-------|
| slice01 `app-skeleton` | closed | [`slice01-app-skeleton/cdc-verification.md`](slice01-app-skeleton/cdc-verification.md) | OTP app skeleton, config validation, direct erlexec probe, and CI scaffold landed. |
| slice02 `exec-runner` | closed | [`slice02-exec-runner/cdc-verification.md`](slice02-exec-runner/cdc-verification.md) | `wolong-exec:run/3` landed with typed results, argv execution, bounded output, timeout kill cleanup, no-zombie evidence, and CT coverage. |
| slice03 `parser-validate` | closed | [`slice03-parser-validate/cdc-verification.md`](slice03-parser-validate/cdc-verification.md) | `wolong-binaries:parser/0` and `wolong:validate/2` landed against current `pandapi-parser`, with local real-parser evidence and CI fixture coverage. |

Silent drops at slice scale: none.

## Composition Check

CDC reproduced the arc-scale gates at commit
`922a515c005839a75625bc028b79dadbdae575b0` before writing this close.

Local gates:

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 9 tests, 0 failures, exit 0
rebar3 as test ct     # wolong_exec_SUITE: 10; wolong_parser_SUITE: 6; all 16 passed, exit 0
rebar3 xref           # exit 0
rebar3 dialyzer       # exit 0
```

Real parser contract evidence, run directly against
`../chengdu/bin/pandapi-parser`:

```text
valid            exit=0  stdout_bytes=0 artifact_bytes=2444 status=ok
missing domain   exit=20 stdout_bytes=0 artifact_bytes=0    status=input_unavailable
broken syntax    exit=22 stdout_bytes=0 artifact_bytes=0    status=input_invalid
broken reference exit=22 stdout_bytes=0 artifact_bytes=0    status=input_invalid
```

Arc-scale Wolong API evidence, with app env configured to
`../chengdu/bin/pandapi-parser` and workdir `/tmp/wolong-arc01-close`:

- valid minimal pair returned `#(ok Detail)` with `status=ok`,
  `component=parser`, `exit-code=0`, empty stdout, and a 2444-byte artifact;
- missing domain returned `#(error #(missing-file Detail))` with
  `status=input_unavailable`, `exit-code=20`, and `path-role=domain`;
- broken syntax returned `#(error #(invalid-hddl Detail))` with
  `status=input_invalid`, `exit-code=22`, and
  `invalid-kind=undistinguished`;
- broken reference returned the same typed invalid-HDDL shape and
  `invalid-kind=undistinguished`.

Remote CI evidence for the CDC slice03 state:

- Run `31826073648`, head SHA
  `922a515c005839a75625bc028b79dadbdae575b0`, completed with conclusion
  `success`.
- Job `94850409970`, `build (ubuntu-22.04)`, passed compile, EUnit, CT, xref,
  and dialyzer.
- Job `94850409737`, `build (macos-15)`, passed compile, EUnit, CT, xref, and
  dialyzer.

## Arc Ledger Walk

| Row | Criterion | Status | Evidence | Notes |
|-----|-----------|--------|----------|-------|
| A1 | `rebar3 compile` + app start/stop clean on a machine with configured binaries; test suite green. | done | Local `rebar3 compile`, EUnit, CT, xref, and dialyzer all exit 0 at `922a515c005839a75625bc028b79dadbdae575b0`. CI run `31826073648` succeeded on `ubuntu-22.04` job `94850409970` and `macos-15` job `94850409737`. | CT includes app start/stop, erlexec lifecycle, runner recovery, and parser validation coverage. |
| A2 | `wolong_exec` kills a deliberately-hanging process at timeout, returns a typed timeout, and leaves no OS process behind. | done | `rebar3 as test ct` passes `wolong_exec_SUITE` 10/10, including `simple_timeout_returns_partial_output` and `term_resistant_timeout_kills_process_and_recovers`. CDC previously reproduced the no-zombie and recovery evidence in [`slice02-exec-runner/cdc-verification.md`](slice02-exec-runner/cdc-verification.md). | Timeout cleanup is process-group oriented via erlexec `kill_group`, `{group, 0}`, and `kill_timeout`. |
| A3 | `(wolong:validate ...)` returns typed results for valid pair, missing file, syntax-invalid HDDL, and broken-reference/undeclared-predicate HDDL. | done | Direct `pandapi-parser` runs and `wolong:validate/2` runs against the real sibling binary reproduce success, missing-file, and invalid-HDDL results. CT passes the same scenarios through the CI-safe parser fixture. | Current Chengdu parser exposes both invalid-HDDL cases as `input_invalid`/22 with no subtype, so wolong records `invalid-kind=undistinguished`. |
| A4 | No dispatch path returns an untyped or stringly error; every error term names its gate/reason. | done | Source review and grep over `src test docs/design-v0.1.0/arc01-exec-substrate` show typed config, binary, exec, timeout, missing-file, output-unavailable, and invalid-HDDL shapes. Runtime parser and runner call sites return tuples/maps, not prose. | Diagnostic prose is retained as metadata (`stderr`) but not used as the primary classification contract. |

Rows: 4. Done: 4. Deferred: 0. No-op: 0.

## Accumulated Arc-Plan Changes

The arc plan changed four times during arc01:

- v1.1, surfaced by slice01: erlexec is called directly from LFE; no thin
  wrapper macro was needed.
- v1.2, surfaced by slice02: output capture is bounded in memory for arc01;
  stream-to-file capture is deferred until arc02/engine scale. Slice02 also
  exposed the missing-command normalization edge and process-group timeout
  cleanup requirement.
- v1.3, operator correction before slice03: the parser integration target is
  current Chengdu pre-release `pandapi-parser` from `../chengdu/bin/`, not
  legacy `pandaPIparser` or unreleased 0.3.0 artifacts.
- v1.4, surfaced by slice03: OQ3 is resolved app-env-only for 0.1.0, and
  current `pandapi-parser` does not machine-distinguish syntax invalidity from
  broken reference/undeclared predicate invalidity.

## Silent-Drop Diff

Specified:

- OTP/LFE app skeleton with config surface.
- Generic erlexec runner with typed results, timeout kill behavior, bounded
  output, no-zombie evidence, and recovery after failure.
- Config-driven parser binary lookup and first real `wolong:validate/2`
  integration through current `pandapi-parser`.

Delivered:

- All specified arc01 slices are closed with CDC verification.
- The runner and parser integration compose through the public
  `wolong:validate/2` facade.
- CI is green for fixture-backed parser coverage; local real-parser evidence
  is recorded against `../chengdu/bin/pandapi-parser`.

Disclosed deferrals:

- Real Chengdu binaries do not run in CI yet; arc03 owns release provisioning.
- Stream-to-file runner capture remains deferred to arc02 when engine-scale
  output makes it necessary.
- Parser invalid-HDDL subtype classification is `undistinguished` until
  Chengdu emits a stable machine field.
- `cwd`/`env` runner options remain optional future work.
- The ltest/EUnit autoexport workaround remains tooling debt outside arc01's
  product capability.

Silent drops: none.

## Bubble-up to the Project

**1. Did arc01 deliver its project-roadmap capability?** Yes. The project plan
assigned arc01 the substrate: one supervised pandaPI process via erlexec with
typed result, timeout/kill behavior, and exit/status mapping proven. Arc01
delivers that for the current parser gate, which is the intentionally smallest
real pandaPI process.

**2. What did arc01 reveal that the project plan did not anticipate?**

- The old parser exit-code vocabulary in project-level W3 is stale for current
  Chengdu 0.3.0 pre-release CLIs. Wolong should classify from the current
  managed-process contract: numeric exit code plus final `PANDAPI_STATUS`.
- Parser invalid-HDDL subtype granularity is not currently available from
  Chengdu. Arc02 must treat parser invalidity as typed but
  `undistinguished`, unless Chengdu adds a stable field such as
  `error_kind`, `rule`, or `location`.
- CI cannot yet prove real Chengdu binary execution. The checked-in fixture
  proves Wolong's side of the contract; release-binary provisioning remains
  arc03.
- The LFE/ltest/rebar3_lfe toolchain exposed a duplicate-export interaction on
  modern CI. The workaround is acceptable for now, but ltest deserves a later
  maintenance pass.

**3. The silent-drop diff at arc scale.** Arc01 promised substrate, not the
full planner pipeline. It delivered the substrate and deliberately stayed out
of arc02 responsibilities: grounder, engine, `plan`, `verify`, dispatch state
machine, scratch-dir lifecycle, and provisioning.

## Project-Plan Updates Made

This close updates `../project-plan.md` to:

- mark arc01 closed and arc02 next;
- update W3 away from legacy parser `0/2/255` wording and toward the current
  managed-process contract;
- add a version-history entry recording arc01's findings.

## Closure

Closed against commit `922a515c005839a75625bc028b79dadbdae575b0` on
2026-08-14.

Arc rows: 4. Done: 4. Deferred: 0. No-op: 0.
