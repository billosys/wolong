# Slice 02 (wolong arc03): stdio-runner

> Open-set plan-of-record for `slice02-stdio-runner`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened 2026-08-26.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Extend Wolong's generic erlexec runner so a caller can send stdin bytes and
close stdin with EOF while Wolong continues to capture stdout and stderr
separately, enforce output bounds, classify exits and timeouts, and avoid
shell command strings.

At slice close, `wolong-exec:run/3` must remain compatible with Arc01/Arc02
callers, and a new explicit stdin-capable runner surface must exist for later
Arc03 pipeline slices.

## 2. Context

Arc03 Slice01 paused on 2026-08-20 because Chengdu then rejected input path
`-` for parser, grounder, and engine. That is now historical context, not the
active blocker.

Current Chengdu `release/0.3.x` local evidence at `e55ef5fd` shows:

- `make test-contract-stdio-managed` passes 187/0 in `../chengdu`;
- parser accepts exactly one stdin HDDL input: `domain -` or `problem -`;
- parser rejects `- -` as documented `cli_usage_error`;
- grounder reads artifact stdin and emits artifact stdout;
- engine reads artifact stdin and emits solved plan stdout;
- engine no-plan via stdin exits `2`, emits empty plan stdout, and reports
  `status=domain_no_plan`;
- full parser stdout -> grounder stdin -> engine stdin solved and no-plan
  contract tests pass on the Chengdu side.

The blocker has therefore moved to Wolong. `wolong-exec:run/3` currently owns
argv-list execution, timeout cleanup, separated stdout/stderr capture, output
caps, and typed result shapes, but it does not expose stdin bytes or EOF.

## 3. In Scope

- Add an explicit stdin-capable runner API. Preferred shape:

  ```lfe
  (wolong-exec:run command args opts)
  (wolong-exec:run command args stdin-bytes opts)
  ```

  where the three-argument form remains the no-stdin compatibility wrapper.
- Validate stdin input. Accept binaries as the release-critical payload form;
  reject unsupported stdin shapes with typed `exec` errors.
- Use erlexec stdin support to send bytes to the child and then send EOF.
- Continue to start external processes from argv lists, not shell command
  strings.
- Preserve independent stdout/stderr capture and output-limit truncation.
- Preserve timeout and kill-group cleanup when a stdin-using child hangs or
  ignores termination.
- Preserve command-not-found, invalid-command, invalid-args, and invalid-opts
  behavior from the existing runner.
- Add Common Test coverage for stdin behavior using Wolong-owned fixtures.
- Record a local real-Chengdu smoke probe if the sibling binaries are present,
  while keeping remote CI independent of `../chengdu`.

## 4. Out of Scope

- No rewrite of `wolong-pipeline` to use stdio artifacts.
- No public `wolong:plan/2,3` or `wolong:validate/2` behavior change.
- No release downloader, checksum verifier, provisioning, or Hex packaging.
- No workaround for parser `- -`; later pipeline slices must respect the
  documented "exactly one parser stdin input" contract.
- No diagnostic-prose classifier.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No public `wolong:verify`, action-sequence parser, or decomposition-tree
  parser.
- No broad runner redesign beyond the stdin surface and its tests.

## 5. Design Constraints

Keep stdin explicit. Existing `run/3` callers must not change behavior or have
to know about stdin.

Keep stdout and stderr as separate bounded captures. If a child writes a large
artifact to stdout and diagnostics/status to stderr, both streams must continue
to drain concurrently so one stream cannot block the other.

EOF is load-bearing. A child that reads until EOF must complete when Wolong
has sent all stdin bytes, including the empty-binary case.

Error results must stay matchable. Do not crash callers on invalid stdin,
stdin send failure, child exit, or timeout unless an existing Arc01 contract
already defines that as caller-crashing behavior.

Do not use a shell pipeline as evidence for the Wolong implementation. Fixture
commands may be shell scripts, but Wolong must invoke them through argv-list
erlexec calls.

## 6. Verification Approach

Use Common Test. Either extend `test/wolong_exec_SUITE.lfe` or add a focused
`test/wolong_exec_stdio_SUITE.lfe`; choose the shape that keeps the suite
readable.

Recommended CI-safe fixtures under `test/fixtures/exec-runner/` or a sibling
fixture directory:

- a child that reads all stdin, waits for EOF, writes a deterministic stdout
  payload, and writes a deterministic stderr marker;
- a child that exits nonzero after consuming stdin;
- a child that emits enough stdout/stderr to prove caps still apply;
- a child that hangs after stdin so timeout/kill cleanup is observable;
- a TERM-resistant child if the existing timeout fixture cannot cover stdin.

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
```

Also perform one tamper cycle. Good tamper choices include skipping EOF after
stdin, routing stdin through a shell string, merging stderr into stdout,
removing output caps for stdin runs, or disabling timeout kill-group cleanup.
Show the owning CT gate fails nonzero, revert the tamper, and show it passes.

If sibling Chengdu binaries are available locally, run one narrow smoke probe
through the new runner against `../chengdu/bin/pandapi-grounder` or
`../chengdu/bin/pandapi-engine` using stdin. Record it as local evidence only;
remote CI must not depend on `../chengdu`.

## 7. Exit Criteria

- `wolong-exec:run/3` remains compatible with prior callers and tests.
- A stdin-capable runner API exists, is exported, and is documented in this
  slice's ledger/closing report.
- Stdin binaries are delivered to child processes and EOF is sent reliably.
- Empty stdin binaries do not hang EOF-sensitive children.
- Stdout and stderr remain separately captured and independently bounded.
- Nonzero child exits after stdin are returned as completed process results,
  not generic failures.
- Invalid stdin shape and stdin send failures are typed and matchable.
- Timeout cleanup kills the process group for stdin-using children and later
  runner calls still succeed.
- No pipeline or public planning API behavior changes land in this slice.
- Local gates and formatter check pass, or exceptions are recorded with re-entry
  conditions.
- `closing-report.md` walks every ledger row and includes Bubble-up to Arc03
  and the project roadmap.
