# Slice 03 (wolong arc01): parser-validate

> Open-set plan-of-record for `slice03-parser-validate`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened
> 2026-08-14. Implementer: CC. Verifier: CDC.

## 1. Goal

Bind the generic runner from slice02 to the first real pandaPI gate:
parser validation. At slice close, `(wolong:validate domain-path
problem-path)` locates the configured raw `pandaPIparser` executable, runs it
through `wolong-exec:run/3` with bounded output and timeout policy, and maps
parser outcomes into typed public results.

This is still not the planning pipeline. The slice proves the composition of
configuration, binary location, one external parser run, and typed API
mapping.

## 2. Context From Earlier Slices

- Slice01 established the OTP application skeleton, app-env config validation,
  and direct erlexec use from LFE.
- Slice02 established `wolong-exec:run/3`: argv-list execution, typed
  completion/timeout/exec-error returns, stdout/stderr separation, output
  caps, process-group timeout cleanup, no-zombie evidence, and post-failure
  recovery.
- Arc-plan OQ3 defaults to app env only for 0.1.0: explicit configured binary
  paths beat PATH/env-var convenience unless the operator changes that
  decision.
- Real OS process coverage belongs in Common Test. EUnit/ltest remains for
  unit-only config and pure mapping tests.
- Preserve the current ltest/EUnit autoexport workaround in `rebar.config`.
  Any ltest cleanup belongs to a separate tooling pass, not this slice.

## 3. In Scope

- Add a config-driven binary locator, probably `src/wolong-binaries.lfe`, that
  uses `wolong-config:validate/0` and resolves at least the `parser` binary.
- Check the configured parser path for existence and executable permissions
  before attempting a parser run. Missing or non-executable binaries must
  produce typed errors, not crashes or raw strings.
- Add the first public API module/function for this project:
  `(wolong:validate domain-path problem-path)`.
- Limit the public API to parser validation. It may return parser provenance
  and generated-artifact metadata if the raw parser produces such artifacts,
  but it must not imply grounder/engine planning has occurred.
- Run the parser only through `wolong-exec:run/3` using argv data. No shell
  command concatenation.
- Use the configured `parse` timeout and existing output cap policy when
  calling the runner.
- Vendor the needed HDDL fixtures into this repository under
  `test/fixtures/parser-validate/`. The Chengdu fixture corpus may be used as
  the source, but wolong tests must not depend on a sibling checkout at
  runtime.
- Add Common Test coverage for parser integration. Unit-only mapping helpers
  may be covered by EUnit/ltest if useful.
- Prove the four arc-ledger parser outcomes with distinct typed results:
  valid pair, missing file, syntax error, and undeclared predicate or broken
  reference.

## 4. Out of Scope

- No grounder, engine, verifier, or full dispatch pipeline.
- No `wolong:plan`, `wolong:verify`, `gen_statem`, scratch-dir lifecycle, or
  worker-pool design.
- No automatic Chengdu release download, build, or provisioning workflow.
- No switch from raw `pandaPIparser` to Chengdu's managed `pandapi-parser`
  wrapper unless the operator explicitly changes the arc contract.
- No broad config redesign beyond the minimum needed to locate and run the
  configured parser.
- No ltest or rebar3_lfe remediation beyond preserving the existing CI
  workaround.

## 5. Contract Notes

The arc plan currently names raw `pandaPIparser` and the runbook section 5
mapping of exit codes `0`, `2`, and `255` into:

- `#(ok ...)`
- `#(error #(missing-file ...))`
- `#(error #(invalid-hddl ...))`

Before implementing the mapper, CC must inspect the actual raw parser argv and
exit behavior available in the working environment and record the discovered
contract in the ledger. If the discovered contract contradicts the arc plan,
pause and report before switching tools or papering over the mismatch.

Chengdu's managed wrapper fixtures and contract records are useful context,
but they are not automatically wolong's runtime contract for this arc. The
wrapper has its own managed-process exit-code vocabulary and belongs to a
separate decision if we choose to consume it later.

## 6. Verification Approach

Primary integration coverage is Common Test:

```bash
rebar3 as test ct
```

The suite should exercise the actual wolong API and binary locator. If a real
`pandaPIparser` binary is not available in remote CI, the distinction must be
explicit:

- CI may use a checked-in parser fixture executable to prove wolong's locator,
  runner invocation, timeout/output policy, and result mapping.
- The ledger must separately record any real-parser evidence and must not
  claim that CI proved a real pandaPI parser run unless it truly did.

CDC should independently re-run:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

CDC should also inspect `src/wolong.lfe`, the binary locator, parser mapping
code, fixtures, and CI evidence for wrapper drift, shell-string bypasses,
untyped errors, and scope expansion beyond parser validation.

## 7. Exit Criteria

- OQ3 is dispositioned in docs and implementation: app env only remains the
  0.1.0 default unless the operator changes it.
- A parser binary locator exists, compiles cleanly, and returns typed
  missing/non-executable binary errors.
- `(wolong:validate domain-path problem-path)` exists and is limited to parser
  validation.
- Valid, missing-file, syntax-error, and broken-reference fixture scenarios
  each return the expected distinct typed result.
- Parser invocation goes through `wolong-exec:run/3` with argv data, configured
  timeout, and bounded stdout/stderr.
- Common Test covers integration behavior and remains green locally and in CI,
  with real-parser evidence honestly separated from fixture-executable
  evidence if CI cannot run the real binary.
- The slice closes without adding planner pipeline behavior.
