# CC iteration 02 prompt: wolong arc01 / slice02 exec-runner

The OTP pin correction exposed a test-tooling boundary issue. Do not gut
`ltest`, do not replace ltest assertions with custom helpers, and do not keep
iterating blindly on EUnit export collisions. Move integration-style coverage
to Common Test using the canonical LFE CT shape, then reassess.

## Context

The recent CI failures under OTP `28.5.0.5` occurred during
`rebar3 as test eunit`, with `erl_lint` reporting duplicate exports for
generated/manual EUnit test functions such as:

- `start_stop_clean_test/0`
- `run_trivial_command_ok_test/0`
- `run_nonexistent_command_errors_test/0`

The failure mode appears to be an OTP 28.5.0.5 + LFE/ltest/EUnit
export-generation interaction, not a reason to abandon ltest. The correct next
move is to put the integration tests under Common Test, where application
lifecycle and external process behavior belong.

## Required Examples

Read the canonical LFE Common Test examples before editing:

- `/Users/oubiwann/lab/lfe/lfe/test/example_SUITE.lfe`
- `/Users/oubiwann/lab/lfe/lfe/test/lfe_init_SUITE.lfe`
- `/Users/oubiwann/lab/lfe/lfe/test/examples_SUITE.lfe`
- `/Users/oubiwann/lab/lfe/lfe/rebar.config`

Use their idioms: `*_SUITE.lfe`, `(include-file "test_server.lfe")` only if
the needed helpers are available/appropriate, explicit `(export (all 0) ...)`,
`all/0`, optional `suite/0`, optional `init_per_suite/1` and
`end_per_suite/1`, and one exported CT testcase function per scenario with
arity 1.

## Test Boundary

Keep ltest/EUnit for unit-level tests such as `wolong-config` validation.

Move integration/system behavior to Common Test:

- application start/stop and supervisor assertions from
  `unit-wolong-app-tests.lfe`;
- direct erlexec probe behavior from `unit-wolong-exec-probe-tests.lfe`;
- `wolong-exec` fixture flows that start OS processes, enforce timeouts, check
  no-zombie cleanup, and prove post-failure recovery.

It is acceptable for a small pure helper assertion about `wolong-exec` result
shape to remain in EUnit only if it does not start the app or spawn OS
processes. Prefer moving the whole runner fixture suite to CT for this
iteration so the boundary is simple and auditable.

## Directory Rule

Use wolong's existing project test tree. At the time of this prompt the repo
uses `test/`; put CT suites and CT data under that tree, e.g.:

```text
test/wolong_exec_SUITE.lfe
test/wolong_exec_SUITE_data/...
```

If the repo has already been renamed to `tests/` by the time you receive this,
use that existing tree instead. Do not create a second parallel `test/` or
`tests/` directory.

## Rebar Wiring

Wire CT in the repo's existing rebar3/LFE style. The LFE repo's
`rebar.config` is the canonical example: it compiles `test/*_SUITE.lfe` before
`ct` with an LFE compiler hook.

Expected CI shape after this iteration:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
```

Run `rebar3 dialyzer` locally and record the result, but do not spend this
iteration forcing dialyzer to be a hard CI gate if LFE/macro/test-profile
interaction makes it fragile. If dialyzer remains green cleanly, keep it. If it
fails for LFE/tooling reasons unrelated to production code, record the exact
failure and propose disabling it in CI while preserving local/manual use.

## Dependency Policy

Do not revert Erlang-compatible dependency constraints such as `~> 2.2` merely
to imitate chengdu's C/C++ micro-pin rule. In wolong, `rebar.lock` is the
resolved-package reproducibility artifact. CI OTP/rebar3 versions and GitHub
Action majors remain explicit toolchain pins.

## Export Collision Guard

After moving integration tests to CT:

1. Keep ltest includes for remaining EUnit unit tests.
2. Prefer ltest's normal `deftest` form for ltest/EUnit unit modules.
3. Avoid manual `*_test/0` plus `(export all)` unless there is reproduced
   evidence that it is required.
4. If duplicate-export or `erl_lint` failures persist after the CT move, stop
   and report the exact module, line, generated function, OTP version, LFE
   version, ltest version, and rebar3_lfe version. Do not continue by removing
   ltest or inventing custom assertion helpers.

## Ledger and Close Updates

Update Slice02 `ledger.md` and `closing-report.md` for the new verification
shape:

- R-5/R-7 runner lifecycle evidence should point at CT, not EUnit, once moved.
- R-8 should require EUnit + CT in CI on Ubuntu and macOS for the corrected
  commit.
- The close report should name the test-boundary correction as an iteration
  finding, not as original-slice evidence.

Before handing back, run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

Then push, wait for GitHub Actions, and record the green run URL. If CI still
fails with export collisions after this move, stop and hand the exact failure
back for CDC/operator discussion. Do not create `cdc-verification.md`; CDC
writes that only after the corrected close is independently reproduced.

