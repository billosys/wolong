# CDC verification: arc02 slice01 gate-contract-substrate

> Independent verification by CDC on 2026-08-14, per
> `PROJECT-MANAGEMENT.md` v2.1 and `LEDGER-DISCIPLINE.md` v2.0. Verified
> commits: implementation `5f0e926f718c9a89da57718dfd25702fbdbdc6b5`,
> close-out `62e7b2c8e3be702413db36f266fcf38e78513e2e`.

## Verdict

Slice01 is accepted as closed.

The ledger has 12 rows and the closing report addresses all 12. CDC reproduced
the local gates, real Chengdu binary survey, scope greps, tamper cycle, and
remote CI evidence. No blocking findings were found.

## Reproduced Gates

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 9 tests, 0 failures, exit 0
rebar3 as test ct     # wolong_exec_SUITE: 10; wolong_gate_SUITE: 14; wolong_parser_SUITE: 9; all 33 passed, exit 0
rebar3 xref           # exit 0
rebar3 dialyzer       # exit 0
```

Remote CI:

- Run `31828779968`, head SHA
  `62e7b2c8e3be702413db36f266fcf38e78513e2e`, completed with conclusion
  `success`.
- `build (macos-15)`: success.
- `build (ubuntu-22.04)`: success.

## Real Chengdu Binary Survey

CDC reproduced the real local process contract against
`../chengdu/bin/pandapi-parser`, `../chengdu/bin/pandapi-grounder`, and
`../chengdu/bin/pandapi-engine`.

Minimal fixture:

```text
parser/grounder/engine exits: 0/0/0
artifact bytes: htn=2444 sas=446 plan=2076
stdout bytes: parser=0 grounder=0 engine=0
status: parser ok, grounder ok, engine ok outcome=solved
```

Unsolvable fixture:

```text
parser/grounder/engine exits: 0/0/2
plan artifact: absent
stdout bytes: parser=0 grounder=0 engine=0
engine status: status=domain_no_plan, exit_code=2, outcome=no_plan
```

This supports the slice's split: CI proves Wolong's side through checked-in
fixtures; real sibling Chengdu binary behavior is local evidence until arc03
owns release provisioning.

## Ledger Verification

| Row | CDC status | Evidence |
|-----|------------|----------|
| G-1 | reproduced | Read Chengdu CLI/process docs and contract records; local `pandapi-*` survey reproduced minimal solved and unsolvable no-plan process shapes. |
| G-2 | reproduced | `src/wolong-binaries.lfe` exports `parser/0`, `grounder/0`, `engine/0`, and `resolve/1`; CT covers all-component resolution, missing grounder config, and non-executable grounder; `rg -n "os:getenv" src test ...` found no implementation/test fallback. |
| G-3 | reproduced | `src/wolong-status.lfe` is the only shared `PANDAPI_STATUS` parser in source; CT covers valid records, missing records, malformed fields, numeric exit code parsing, final-record selection, and unknown field preservation. |
| G-4 | reproduced | `wolong:validate/2` delegates through `wolong-gate:run-parser/4` and preserves Arc01 public parser shapes; `wolong_parser_SUITE` passed 9/9, including output-unavailable, timeout, and missing-status cases. |
| G-5 | reproduced | `src/wolong-gate.lfe` maps the current managed vocabulary; CT cases `mapper_covers_managed_status_vocabulary`, `mapper_exec_error_is_typed`, `engine_domain_no_plan_success_shape`, and `engine_domain_no_plan_distinct_from_failures` passed. |
| G-6 | reproduced | `wolong-gate` argv builders produce `--supervised --status=stderr --output PATH ...`; production source uses `wolong-exec:run/3`; shell references are fixture-only. |
| G-7 | reproduced | `wolong_gate_SUITE:supervised_parse_ground_solve_fixture/1` passed through parser -> grounder -> engine with artifact/status/stdout assertions. |
| G-8 | reproduced | Engine `domain_no_plan` maps to `#(domain-no-plan Detail)` internally; tamper changed it to error-shaped and `engine_domain_no_plan_success_shape` failed; restore passed all 14 gate tests. |
| G-9 | reproduced | Checked-in fixture executables are present under `test/fixtures/gate-contract-substrate/`; closing report and ledger separate CI fixture evidence from local real-binary evidence. |
| G-10 | reproduced | Scope grep found forbidden terms only in planning prose, not `src/` or `test/`; no public `plan`/`verify`, `gen_statem`, dispatch supervisor, downloader, or legacy `pandaPI*` runtime fallback landed. |
| G-11 | reproduced | Local compile, EUnit, CT, xref, and dialyzer passed; final remote CI run `31828779968` passed both platform jobs. |
| G-12 | reproduced | CDC repeated the tamper cycle: poisoned engine no-plan mapping, observed CT nonzero with `engine_domain_no_plan_success_shape` failing, restored mapping, and observed `wolong_gate_SUITE` pass 14/14. |

Rows: 12. Done: 12. Deferred: 0. No-op: 0.

## Bubble-Up Check

Slice01 delivered the arc-plan assignment: shared gate machinery now resolves
parser/grounder/engine, parses final `PANDAPI_STATUS` once, maps current
managed statuses per gate, and proves a one-shot supervised
parse -> ground -> solve fixture without public `plan`.

The closing report's silent-drop diff is complete. No public `wolong:plan`,
public `wolong:verify`, `gen_statem`, dispatch supervisor, release
provisioning, or legacy binary fallback landed.

Arc-plan update required: yes. CDC updated `../arc-plan.md` to v1.1, resolving
OQ2 and OQ3 from Slice01 and recording that `wolong-binaries` is now
parser/grounder/engine-proven. OQ1, OQ4, and OQ5 remain open for later slices.

Residual hardening note: `wolong-gate` classifies from the observed OS exit
status plus the final `status` field and preserves the status-line
`exit_code`; it does not yet reject a contradictory status-line `exit_code`.
This is not blocking for Slice01 because the current Chengdu binaries and
fixtures emit consistent fields, but later public API slices should decide
whether to treat an exit/status-field mismatch as `unmapped-status` or
`status-mismatch`.

## What Worked

- Extracting `wolong-status` before adding pipeline orchestration kept the
  status contract testable on its own.
- The strict fixture binaries make CI meaningful without pretending the
  sibling Chengdu checkout exists on GitHub runners.
- The tamper row targets the real project invariant: engine no-plan must not
  become an error before `wolong:plan` translates it to `#(unsolvable ...)`.

## Closure

CDC accepts arc02 slice01 closed at
`62e7b2c8e3be702413db36f266fcf38e78513e2e` on 2026-08-14.
