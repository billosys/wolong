# Slice 03 (wolong arc03): stdio-gate-pipeline

> Open-set plan-of-record for `slice03-stdio-gate-pipeline`, per
> `PROJECT-MANAGEMENT.md` v2.1 and the Wolong-local `slice-doc.md` convention.
> Parent: `../arc-plan.md`. Opened 2026-08-26. Implementer: CC. Verifier: CDC.

## 1. Goal

Wire Wolong's internal planning pipeline through the supported Chengdu stdio
artifact path:

```text
domain/problem paths -> pandapi-parser --output -
parser stdout bytes  -> pandapi-grounder - --output -
grounder stdout bytes -> pandapi-engine - --output -
engine stdout bytes   -> durable plan payload, or empty stdout for no-plan
```

Public behavior must remain:

```lfe
(wolong:plan domain problem opts)
(wolong:plan domain problem)
(wolong:validate domain problem)
```

with solved plans, valid no-plan, and typed gate errors preserving the public
result shapes established in Arc02.

## 2. Context

Slice02 delivered `wolong-exec:run-stdin/4`, proving binary stdin payloads plus
EOF, argv-list execution, separated stdout/stderr capture, independent output
caps, nonzero completed exits, timeout cleanup, and recovery.

The current gate layer is still file-backed: parser writes `parser.htn`,
grounder reads that file and writes `grounder.sas`, and engine reads that file
and writes `engine.plan`. Its classifier also treats a successful gate as
artifact-present only when an output path exists.

Slice03 replaces that internal handoff with stdout/stdin artifact bytes. It
may still materialize artifacts into the workspace for debugging/provenance
when useful, but downstream gates must consume the captured stdout bytes from
the previous gate, not an intermediate file path.

Parser stdin has a specific caveat. Current Chengdu supports exactly one
parser HDDL input from stdin (`domain -` or `problem -`) and rejects parser
`- -`. The common near-term Wolong release case is two HDDL paths. This slice
should therefore keep parser as one complete domain/problem planning-instance
parse, not split it into domain and problem parser workers.

## 3. In Scope

- Add stdout-artifact-aware gate execution/classification for parser, grounder,
  and engine.
- Invoke parser with the supported two-input planning instance and `--output -`.
- Feed parser stdout bytes to grounder with `wolong-exec:run-stdin/4`,
  grounder input path `-`, and `--output -`.
- Feed grounder stdout bytes to engine with `wolong-exec:run-stdin/4`,
  engine input path `-`, and `--output -`.
- Preserve final status parsing from stderr and exit-code/status consistency
  checks.
- Preserve public solved result shape, including durable plan payload captured
  before workspace cleanup.
- Preserve valid no-plan as `#(unsolvable Detail)` at the public API and
  `#(domain-no-plan Detail)` at the internal pipeline boundary.
- Preserve typed parser, grounder, engine, binary, workspace, timeout, status,
  and exec errors.
- Update Wolong-owned fixtures so CI models Chengdu's stdio artifact contract
  honestly.
- Record local real-Chengdu solved and no-plan smoke evidence when sibling
  binaries are available, without making remote CI depend on `../chengdu`.

## 4. Out of Scope

- No split domain parser workers, problem parser workers, domain artifact
  cache, parser artifact merge step, or framed parser stdin protocol.
- No parser `- -` support or workaround.
- No public API redesign.
- No release provisioning, downloader, checksum verifier, or Hex packaging.
- No planner pool, queue, backpressure API, or distributed Erlang.
- No diagnostic-prose classifier.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No public `wolong:verify`, action-sequence parser, or decomposition-tree
  parser.
- No broad streaming/backpressure rewrite beyond preserving existing bounded
  capture; keep Slice05 available if release-scale artifact stress needs it.

## 5. Design Constraints

The release-grade handoff is byte ownership, not shell composition. Wolong must
invoke every command through erlexec argv lists. Shell pipelines are useful
only as external Chengdu characterization evidence, not as Wolong's
implementation.

Stdout artifact bytes are load-bearing. The classifier must be able to
distinguish:

- successful stdout artifact present;
- successful stdout artifact missing or empty where an artifact is required;
- engine no-plan, where empty stdout is expected with
  `status=domain_no_plan` and exit `2`;
- truncated stdout/stderr, where output caps may make the artifact unusable
  and must be surfaced honestly.

Stderr remains the machine-status stream. Do not classify results from human
diagnostic prose.

Workspace semantics must stay honest. It is acceptable to write captured
stdout artifacts into workspace files for provenance or `keep-artifacts`
debugging, but later gates must receive the captured bytes via stdin. Do not
quietly retain the old file path handoff and call it stdio.

## 6. Verification Approach

Use Common Test for integration behavior. Prefer extending
`test/wolong_pipeline_SUITE.lfe`, `test/wolong_plan_SUITE.lfe`, and the
fixture scripts under `test/fixtures/gate-contract-substrate/` rather than
creating a parallel fixture family, unless readability clearly calls for a new
focused suite.

Fixture behavior should model Chengdu's managed-process contract:

- parser accepts two file/path inputs and `--output -`, writes parser artifact
  bytes to stdout, and writes final `PANDAPI_STATUS` to stderr;
- grounder accepts input path `-`, reads stdin to EOF, writes grounder artifact
  bytes to stdout, and writes final `PANDAPI_STATUS` to stderr;
- engine accepts input path `-`, reads stdin to EOF, writes plan bytes to
  stdout for solved, writes empty stdout for no-plan, and writes final
  `PANDAPI_STATUS` to stderr;
- unsupported parser `- -` remains unsupported in docs/tests.

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
```

Also perform one tamper cycle. Good choices include replacing the grounder
stdin handoff with a file path, skipping EOF, using `--output` to a file for
grounder or engine, reading status from stdout, or treating engine no-plan
empty stdout as a missing artifact. Show the owning CT gate fails nonzero,
revert the tamper, and show it passes.

If sibling Chengdu binaries are present, run local-only solved and no-plan
smoke probes through Wolong's pipeline with `../chengdu/bin/pandapi-*`.
Record this separately from CI. Do not claim remote CI uses real Chengdu
binaries until Arc04 or an explicit artifact-backed CI path exists.

## 7. Exit Criteria

- Parser is invoked with `--output -` and the supported domain/problem planning
  instance; parser `- -` is not assumed.
- Parser stdout artifact bytes are classified as the parser artifact and passed
  to grounder via stdin.
- Grounder reads stdin, receives EOF, emits artifact stdout, and its stdout
  bytes are passed to engine via stdin.
- Engine reads stdin, receives EOF, and emits plan stdout for solved cases.
- Engine no-plan remains a valid domain result with empty stdout and
  `domain_no_plan` status.
- Final `PANDAPI_STATUS` parsing remains from stderr.
- Public `wolong:plan/2,3` result shapes are unchanged for solved, no-plan,
  and typed errors.
- `wolong:validate/2` remains parser-only and does not run grounder or engine.
- Workspace metadata and cleanup remain honest for stdout-sourced artifacts.
- CI fixtures model the stdio artifact contract and fail if a gate silently
  falls back to file-path handoff.
- Local real-Chengdu smoke evidence is recorded if available, and CI scope is
  stated honestly.
- Local gates, formatter check, tamper cycle, and remote CI evidence are
  recorded.
- `closing-report.md` walks every ledger row and includes Bubble-up to Arc03
  and the project roadmap.
