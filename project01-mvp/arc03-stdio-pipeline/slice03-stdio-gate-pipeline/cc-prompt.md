# CC prompt: wolong arc03 / slice03 stdio-gate-pipeline

You are CC implementing `slice03-stdio-gate-pipeline` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read First

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc03-stdio-pipeline/arc-plan.md`
4. `docs/design-v0.1.0/arc03-stdio-pipeline/slice02-stdio-runner/closing-report.md`
5. `docs/design-v0.1.0/arc03-stdio-pipeline/slice03-stdio-gate-pipeline/slice-doc.md`
6. `docs/design-v0.1.0/arc03-stdio-pipeline/slice03-stdio-gate-pipeline/ledger.md`
7. `/Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md`
8. `/Users/oubiwann/lab/lfe/lfe/test/*SUITE.lfe` for canonical LFE Common Test examples
9. `src/wolong-exec.lfe`
10. `src/wolong-gate.lfe`
11. `src/wolong-pipeline.lfe`
12. `src/wolong-workspace.lfe`
13. `src/wolong.lfe`
14. `test/wolong_exec_SUITE.lfe`
15. `test/wolong_gate_SUITE.lfe`
16. `test/wolong_pipeline_SUITE.lfe`
17. `test/wolong_plan_SUITE.lfe`
18. `test/wolong_dispatch_SUITE.lfe`
19. `test/fixtures/gate-contract-substrate/`
20. `../chengdu/docs/reference/cli.md`
21. `../chengdu/docs/managed-process.md`

Also load the collaboration framework and Erlang/OTP guidance for processes,
external command boundaries, and Common Test. Ledger discipline applies:
update `ledger.md` as you work with attested evidence, and do not leave all
evidence for the final close.

## Mission

Wire Wolong's internal planning pipeline through the supported stdio artifact
path:

```text
domain/problem paths -> parser --output -
parser stdout        -> grounder stdin, grounder --output -
grounder stdout      -> engine stdin, engine --output -
engine stdout        -> plan payload, or empty stdout for domain_no_plan
```

Use the Slice02 runner API:

```lfe
(wolong-exec:run-stdin command args stdin-bytes opts)
```

and preserve the no-stdin runner for parser and compatibility:

```lfe
(wolong-exec:run command args opts)
```

## Required Shape

Parser still receives one complete planning instance. For the common release
case, that means domain and problem paths:

```text
pandapi-parser --supervised --status=stderr --output - DOMAIN.hddl PROBLEM.hddl
```

Do not model `pandapi-parser - -` as supported. Do not split parsing into
domain-parser and problem-parser workers in this slice.

Grounder and engine should consume artifacts over stdin:

```text
pandapi-grounder --supervised --status=stderr --output - -
pandapi-engine   --supervised --status=stderr --output - -
```

The implementation will probably need stdout-artifact-aware gate helpers or a
classifier mode in `wolong-gate`. Choose names that fit the codebase, but keep
the old file-backed helpers available unless you intentionally migrate every
call site and prove compatibility.

The stdio pipeline must preserve:

- final status parsing from stderr;
- exit-code/status consistency checks;
- typed parser, grounder, engine, binary, workspace, timeout, status, and exec
  errors;
- no-plan mapping from engine `status=domain_no_plan`/exit `2` to public
  `#(unsolvable Detail)`;
- durable solved plan payload before cleanup;
- dispatch metadata and `verification-boundary.separate-verifier=not-run`;
- argv-list erlexec execution, with no shell command strings.

## Tests and Fixtures

Use Common Test. Prefer extending existing suites and fixtures instead of
creating parallel surfaces:

- `test/wolong_pipeline_SUITE.lfe`
- `test/wolong_plan_SUITE.lfe`
- `test/wolong_dispatch_SUITE.lfe`
- `test/wolong_gate_SUITE.lfe`
- `test/fixtures/gate-contract-substrate/`

Update the fixture scripts so they can model the current Chengdu contract:

- parser can write artifact bytes to stdout when `--output -` is selected;
- grounder can read artifact bytes from stdin when input path is `-` and write
  artifact bytes to stdout when `--output -` is selected;
- engine can read artifact bytes from stdin when input path is `-` and write
  plan bytes to stdout when `--output -` is selected;
- engine no-plan emits empty stdout, exit `2`, and final
  `PANDAPI_STATUS status=domain_no_plan` on stderr;
- status records include enough fields for tests to prove stdin/stdout roles
  where useful, such as `artifact=stdout`, `path=-`, `operation=read`,
  `path_role=htn`, or `path_role=engine_input`.

Required cases:

- solved pipeline uses parser stdout -> grounder stdin -> engine stdin and
  returns `#(ok Detail)` internally;
- solved public `wolong:plan/2,3` still returns `#(ok Plan)` with durable plan
  payload;
- valid no-plan still returns internal `#(domain-no-plan Detail)` and public
  `#(unsolvable Detail)`;
- parser failure short-circuits before grounder and engine;
- grounder failure includes parser detail and short-circuits before engine;
- engine failure is typed and distinct from no-plan;
- engine timeout over stdin kills the process group and later solved planning
  recovers;
- output caps/truncation remain visible and honest for stdout artifacts and
  stderr diagnostics;
- workspace cleanup works with `keep-artifacts=true` and `keep-artifacts=false`;
- `wolong:validate/2` remains parser-only;
- parser `- -` remains unsupported/deferred rather than assumed.

Remote CI must stay fixture-backed. If sibling Chengdu binaries are available
locally, run solved and no-plan smoke probes with `../chengdu/bin/pandapi-*`
through Wolong's pipeline or public plan and record them separately. Do not
claim Slice04's real-binary public-plan proof from this smoke.

## Scope Guard

Stay inside Slice03.

- No split domain/problem parser workers.
- No framed parser stdin protocol.
- No parser `- -` workaround.
- No public API redesign.
- No provisioning, downloader, checksum verifier, or Hex release work.
- No planner pool, queue, backpressure API, or distributed Erlang.
- No diagnostic-prose classifier.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No public `wolong:verify`, action-sequence parser, or decomposition-tree
  parser.

## Verification Before Close

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
```

Also perform one tamper cycle. Break a meaningful new stdio pipeline invariant:
for example pass the parser artifact to grounder by filename instead of stdin,
skip EOF to grounder or engine, write grounder/engine output to a file, parse
status from stdout, or treat engine no-plan empty stdout as missing artifact.
Show the owning CT gate fails nonzero, revert the tamper, and show it passes.

If CI is available, push and record the linked green run on both Ubuntu and
macOS. State directly that remote CI is fixture-backed unless release artifacts
have been added separately.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all 22 ledger rows.
3. Add `Bubble-up to the arc` answering:
   - did Slice03 deliver the `stdio-gate-pipeline` row in `arc-plan.md`;
   - what exact stdio pipeline shape landed;
   - whether parser `- -` and split parser workers remain deferred;
   - whether Slice04 can now focus on real-binary public-plan proof;
   - whether Slice05 backpressure hardening should remain separate.
4. Update `../arc-plan.md` if implementation findings change later slice
   scope, sequencing, or the arc ledger.
5. Update `../../project-plan.md` only if project roadmap or release-readiness
   wording changes.
6. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
