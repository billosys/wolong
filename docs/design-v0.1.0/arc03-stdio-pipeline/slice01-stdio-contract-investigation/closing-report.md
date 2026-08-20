# Slice 01 Closing Report: stdio-contract-investigation

Closed by CC on 2026-08-20. Verifier: CDC.

## Decision

**Chengdu-blocked.**

Current Chengdu 0.3.0 local binaries support artifact output on stdout with
`--output -` and final `PANDAPI_STATUS` on stderr with `--status=stderr`, but
they do not support input path `-` for parser, grounder, or engine. That blocks
the release-critical stdin/stdout/stderr pipeline Arc03 was inserted to prove.

Wolong must pause Arc03 implementation until one of these re-entry conditions
is met:

- Chengdu documents and implements input stdin for `pandapi-parser`,
  `pandapi-grounder`, and `pandapi-engine`, including unambiguous parser role
  semantics for the two HDDL inputs.
- Wolong's project plan explicitly rescopes Arc03 from a stdin pipeline to a
  file-input plus stdout-artifact temporary-file bridge.

No production stdio runner or workaround landed in this slice.

## Evidence Summary

Surveyed Chengdu docs:

- `../chengdu/docs/reference/cli.md`
- `../chengdu/docs/managed-process.md`

The documented supported forms are path-based inputs with optional artifact
stdout:

```text
pandapi-parser [COMMON] [--output OUT.htn|-] DOMAIN.hddl PROBLEM.hddl
pandapi-grounder [COMMON] [--output OUT.sas|-] INPUT.htn
pandapi-engine [COMMON] [--output PLAN|-] INPUT.sas
```

The docs state that `--output -` writes the artifact to stdout. When stdout is
an artifact stream, status must be on stderr; `--status=stdout` is only legal
when stdout is otherwise empty. Supervisors classify from exit code plus the
final `PANDAPI_STATUS`, not diagnostic prose.

Surveyed binaries:

```bash
ls -al ../chengdu/bin
../chengdu/bin/pandapi-parser --help
../chengdu/bin/pandapi-grounder --help
../chengdu/bin/pandapi-engine --help
../chengdu/bin/pandapi-parser --version
../chengdu/bin/pandapi-grounder --version
../chengdu/bin/pandapi-engine --version
```

All three local binaries exist under `../chengdu/bin`, are executable, and
report `chengdu_version=0.3.0` and `managed_process_contract=0.3.0`.

Probe workspace: `/tmp/wolong-stdio.eMyUZV`.

## Probe Results

### Parser

File-input artifact stdout works:

```bash
../chengdu/bin/pandapi-parser --supervised --status=stderr --output - \
  ../chengdu/fixtures/minimal/domain.hddl \
  ../chengdu/fixtures/minimal/problem.hddl
```

Result: exit `0`; stdout artifact 2444 bytes; final stderr status
`status=ok`, `component=parser`, `artifact=stdout`.

Input stdin is unsupported:

- Domain as `-`: exit `10`, stdout 0 bytes, final status
  `status=cli_usage_error`.
- Problem as `-`: exit `10`, stdout 0 bytes, final status
  `status=cli_usage_error`.
- Both inputs as `- -`: exit `10`, stdout 0 bytes, final status
  `status=cli_usage_error`.

### Grounder

File-input artifact stdout works:

```bash
../chengdu/bin/pandapi-grounder --supervised --status=stderr --output - \
  /tmp/wolong-stdio.eMyUZV/parser-minimal.htn
```

Result: exit `0`; stdout artifact 446 bytes; final stderr status
`status=ok`, `component=grounder`, `artifact=stdout`.

Input stdin is unsupported:

```bash
../chengdu/bin/pandapi-grounder --supervised --status=stderr --output - -
```

Result with parser artifact on stdin: exit `10`, stdout 0 bytes, final status
`status=cli_usage_error`.

### Engine

File-input artifact stdout works for solved input:

```bash
../chengdu/bin/pandapi-engine --supervised --status=stderr --output - \
  ../chengdu/fixtures/engine/minimal.sas
```

Result: exit `0`; stdout plan 2039 bytes; final stderr status `status=ok`,
`component=engine`, `artifact=stdout`, `outcome=solved`.

File-input valid no-plan remains typed:

```bash
../chengdu/bin/pandapi-engine --supervised --status=stderr --output - \
  ../chengdu/fixtures/engine/unsolvable.sas
```

Result: exit `2`; stdout plan 0 bytes; final stderr status
`status=domain_no_plan`, `class=expected_domain_outcome`,
`partial_output_policy=absent`, `outcome=no_plan`.

Input stdin is unsupported:

```bash
../chengdu/bin/pandapi-engine --supervised --status=stderr --output - -
```

Result with SAS artifact on stdin: exit `10`, stdout 0 bytes, final status
`status=cli_usage_error`.

### Full Chain

The required direct stdin chain is blocked. A parser stdout to grounder stdin
pipe exited `10`; grounder emitted final `status=cli_usage_error`. A grounder
stdout to engine stdin pipe also exited `10`; engine emitted final
`status=cli_usage_error`.

File-mediated controls prove the artifacts themselves are usable:

- Minimal solved: parser stdout artifact -> temp `.htn`; grounder stdout
  artifact -> temp `.sas`; engine file input -> exit `0`, plan about 2.0 KiB,
  `outcome=solved`.
- Valid no-plan: same file-mediated path over unsolvable fixtures -> engine
  exit `2`, empty plan, `status=domain_no_plan`, `outcome=no_plan`.

That control prevents over-reading the failure: Chengdu can produce and consume
the artifacts through files, and can emit artifacts to stdout. It cannot accept
those artifacts from stdin under the probed supported command surfaces.

## Stdout and Status Ownership

Supported artifact stdout paths are clean when `--status=stderr` is selected:
artifact bytes are on stdout, and final `PANDAPI_STATUS` is on stderr.

Conflict probes with `--status=stdout --output -` for parser and engine exit
`10` and emit `status=cli_usage_error`; Chengdu rejects the unsafe combination
instead of mixing artifact stdout with status output.

Invalid-input probe:

```bash
../chengdu/bin/pandapi-parser --supervised --status=stderr --output - \
  ../chengdu/fixtures/broken-syntax/domain.hddl \
  ../chengdu/fixtures/broken-syntax/problem.hddl
```

Result: exit `22`; stdout 0 bytes; final status `status=input_invalid`,
`component=parser`, `partial_output_policy=discarded`.

## erlexec/LFE Feasibility

erlexec is not the blocker. Inspected:

- `_build/default/lib/erlexec/README.md`
- `_build/default/lib/erlexec/src/exec.erl`
- `src/wolong-exec.lfe`

erlexec supports:

- `stdin` and `{stdin, null | close | Filename}` command options;
- sending binary stdin with `exec:send(PidOrOsPid, Data)`;
- closing stdin with `exec:send(PidOrOsPid, eof)`;
- separate stdout and stderr messages when pty mode is not used.

The current `wolong-exec:run/3` uses argv-list erlexec execution with
`monitor`, `stdout`, `stderr`, `kill_group`, process-group isolation, timeout
cleanup, and capped concurrent capture. It does not expose a stdin-writing
surface yet. Such a runner extension is feasible only after Chengdu supports
input stdin, or after Wolong explicitly chooses a different process contract.

## Backpressure

Current local fixture artifacts are small:

- parser minimal `.htn`: about 2.4 KiB;
- grounder minimal `.sas`: 446 bytes;
- grounder unsolvable `.sas`: 262 bytes;
- engine solved plan: about 2.0 KiB;
- engine no-plan artifact: 0 bytes.

This is enough for the investigation but not a release-scale backpressure
proof. If Arc03 resumes, the runner design must explicitly choose bounded
in-memory capture or stream-to-file handoff and must keep draining stdout and
stderr concurrently. A file-input plus stdout-artifact bridge would still need
the same bounded-output policy.

## CI Strategy

Remote CI should continue using Wolong-owned fixtures. Current
`.github/workflows/build.yml` runs compile, EUnit, Common Test, xref, and
dialyzer against checked-in test fixtures; it does not require sibling
`../chengdu` binaries.

Real Chengdu binary probes should remain optional local evidence or move to a
future artifact-backed CI job once Chengdu publishes suitable release artifacts.
Remote CI must not pretend a sibling checkout exists.

## Ledger Walk

- **SI-1:** Done. Chengdu CLI and managed-process docs surveyed; supported
  forms are path inputs plus optional artifact stdout, not documented stdin
  inputs.
- **SI-2:** Done. All three `pandapi-*` binaries exist, are executable, and
  report the 0.3.0 managed-process contract.
- **SI-3:** Done. Parser input stdin is blocked for domain, problem, and both
  HDDL roles; each `-` input probe exits `10` with `cli_usage_error`.
- **SI-4:** Done. Grounder can emit stdout artifact from file input but rejects
  input `-` with `cli_usage_error`.
- **SI-5:** Done. Engine can emit solved/no-plan stdout artifacts from file
  input but rejects input `-` with `cli_usage_error`.
- **SI-6:** Done. Minimal solved stdin chain is blocked at grounder/engine
  input `-`; file-mediated control succeeds.
- **SI-7:** Done. Valid no-plan file-mediated control returns
  `domain_no_plan`/exit `2`; required stdin chain is still blocked.
- **SI-8:** Done. Artifact stdout ownership is clean on supported paths;
  stdout/status conflicts are rejected as usage errors.
- **SI-9:** Done. Success, no-plan, invalid input, and usage conflicts all
  produce machine-parseable final `PANDAPI_STATUS`.
- **SI-10:** Done. erlexec supports stdin writing and separate stdout/stderr
  capture; Wolong's current runner simply has no stdin surface yet.
- **SI-11:** Done. Fixture sizes are small, but resumed implementation needs an
  explicit bounded capture or stream-to-file policy.
- **SI-12:** Done. CI should remain fixture-backed until release artifacts
  exist.
- **SI-13:** Done. Final decision is Chengdu-blocked with re-entry conditions.
- **SI-14:** Done. Scope grep found only pre-existing public deferrals or slice
  prose; no production runner, public API change, provisioning, verifier, action
  parser, decomposition parser, or diagnostic-prose classifier landed.
- **SI-15:** Done. Local gates passed on 2026-08-20:
  `rebar3 compile`; `rebar3 as test eunit` (9 tests); `rebar3 as test ct`
  (62 tests); `rebar3 xref`; `rebar3 dialyzer`;
  `rebar3 lfe format --check` (13 files formatted).
- **SI-16:** Done. This report walks every row and records bubble-up to Arc03
  and the project roadmap.

## Bubble-up to Arc03

Arc03 is paused before `slice02-stdio-runner`. The current Chengdu contract is
not sufficient for the release-critical stdin pipeline. Do not implement a
production Wolong stdio runner against these binaries unless the project is
explicitly rescoped.

Arc03 re-entry condition: Chengdu must provide a supported input-stdin contract
for `pandapi-parser`, `pandapi-grounder`, and `pandapi-engine`, including the
parser's two-input role semantics, or Wolong must explicitly choose a
file-input plus stdout-artifact temporary-file bridge as the release-grade
contract.

Bubble-up committed in `b52c6db` (`Record Arc03 stdin contract blocker`).

## Bubble-up to Project

Project W1 remains open. The Arc02 file-backed pipeline and current public API
are useful substrate, but they are not the release-grade stdio behavior W1 now
requires. Arc04 provisioning must not start from a claim that stdio behavior is
proven.

Project re-entry condition is the same as Arc03: Chengdu input stdin support,
or an explicit project-level rescope away from a stdin pipeline.

## Commits

- `b52c6db` - `Record Arc03 stdin contract blocker`

The close packet itself updates this ledger and report.
