# Slice 02 (wolong arc01): exec-runner

> Open-set plan-of-record for `slice02-exec-runner`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened
> 2026-08-13. Implementer: CC. Verifier: CDC.

## 1. Goal

Build the owned process-execution contract that every later pandaPI gate will
stand on: `wolong-exec`, a small LFE module that runs an explicit executable
plus argv under erlexec, captures stdout/stderr and exit status, enforces a
timeout with kill escalation, and returns typed results without leaking OS
processes.

This slice is deliberately pandaPI-free. It proves lifecycle mechanics under
fixture abuse before slice03 binds the runner to `pandaPIparser`.

## 2. Context From Slice01

Slice01 closed the OTP skeleton, config validation, direct erlexec probe, and
CI runner. Inputs this slice must carry forward:

- Use direct erlexec calls. Arc-plan OQ1 resolved to direct `exec:run/2` /
  related erlexec calls from LFE, with `wolong-exec` serving as the domain
  contract rather than an ergonomics wrapper.
- Use `rebar3 as test eunit` as the canonical local and CI test runner.
  `rebar3 lfe ltest` is not an acceptable gate because Slice01 found it does
  not propagate failing tests as a nonzero process exit.
- Do not rely on `ltest` wildcard pattern matching without rechecking it.
  Prefer concrete tag checks and shape checks based on `element/2`,
  `maps:get/3`, and helper predicates.
- Disposition Slice01 CDC finding F-1 before relying on CI pins: either move
  the workflow to the current OTP 28 branch head after a live survey, or record
  an operator-approved rationale for staying on `28.1.1`.

## 3. In Scope

- Add `src/wolong-exec.lfe` with an explicit contract:
  `(wolong-exec:run command args opts)`.
- Accept `command` as a string or binary executable path/name and `args` as a
  list of string/binary argv entries. The implementation must execute argv,
  not concatenate a shell command string.
- Accept an opts map with, at minimum:
  - `timeout-ms`: positive integer milliseconds.
  - `kill-timeout-sec`: non-negative integer seconds for erlexec escalation.
  - `output-limit-bytes`: positive integer cap applied independently to stdout
    and stderr capture.
  - optional `cwd` and `env` only if they can be tested cleanly in this slice.
- Return typed results:
  - `#(ok Result)` for a completed process, including `exit-status`, `stdout`,
    `stderr`, output truncation metadata, and duration metadata.
  - `#(timeout Result)` for a timed-out process, including partial stdout,
    partial stderr, timeout metadata, kill metadata, and duration metadata.
  - `#(error #(exec Reason Detail))` for runner or erlexec start failures.
- Add fixture-driven tests under `test/` and fixture scripts under
  `test/fixtures/exec-runner/` for normal exit, nonzero exit, stdout/stderr
  capture, argv quoting, timeout, TERM-resistant timeout, and output flood.
- Prove the no-zombie guarantee for a timed-out fixture with OS-process-table
  evidence in the test, not by eyeballing terminal output.
- Keep the application and erlexec supervision tree alive after failed starts
  and timed-out runs, and prove a subsequent normal run still succeeds.
- Update CI and developer docs only as needed to keep the new runner tests and
  pin disposition visible.

## 4. Out of Scope

- No pandaPI binary invocation.
- No `wolong:validate/2`, `wolong:plan/3`, or `wolong:verify/4` public API.
- No `wolong-binaries` locator or startup executable checks; slice03 owns
  config-driven binary discovery.
- No full gate pipeline, scratch-dir lifecycle, or `gen_statem` dispatch.
- No planner pooling, distribution, CCDP integration, or hex.pm packaging.
- No broad config-schema redesign unless a runner option truly needs one and
  the ledger is amended first.

## 5. Design Constraints

- Treat shell interpolation as a defect. The owned API passes argv as data.
  Tests must include an argument with spaces and shell metacharacters that
  reaches the fixture unchanged.
- Treat nonzero process exit as a completed run with `exit-status`, not as an
  erlexec failure. Later gate layers decide which exit statuses are semantic
  errors.
- Separate stdout and stderr. Do not use PTY mode for this runner contract.
- Bound captured output. The default may be conservative, but the cap and
  truncation flags must be visible in the returned result.
- A timeout is not "done" until the OS process is gone and the application can
  run another command successfully.
- Preserve typed errors. No public runner return path may expose a raw string
  as the primary error shape.

## 6. Verification Approach

Primary verification is `rebar3 as test eunit`, with fixture tests that would
fail if process lifecycle, output capture, or typed result mapping regressed.
CI must run the same command on both existing matrix platforms. The close
report must include one tamper demonstration showing a meaningful runner test
fails with nonzero exit and then passes again after revert.

CDC should independently re-run:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 xref
rebar3 dialyzer
```

CDC should also inspect `src/wolong-exec.lfe`, the fixture scripts, and the CI
workflow for shell-string bypasses, missing timeout evidence, and scope drift
into pandaPI.

## 7. Exit Criteria

- The Slice01 F-1 OTP-pin disposition is recorded and reflected in CI if it
  changes the workflow pin.
- `wolong-exec:run/3` exists, compiles with warnings as errors, and exposes
  only the typed result contract described above.
- Normal and nonzero fixture exits return `#(ok ...)` with exact stdout,
  stderr, and exit status.
- Timeout fixtures return `#(timeout ...)`, include partial output, and leave
  no fixture process alive.
- Output caps are tested and reported via truncation metadata.
- The suite is falsifiable, green locally, and green in CI on Ubuntu and macOS.
- The implementation stays inside the slice02 scope fence.

