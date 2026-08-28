# CC prompt: wolong arc03 / slice01 stdio-contract-investigation

You are CC implementing `slice01-stdio-contract-investigation` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read First

1. `AGENTS.md`
2. `/Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md`
3. `docs/design-v0.1.0/project-plan.md`
4. `docs/design-v0.1.0/arc02-gate-pipeline/arc-plan.md`
5. `docs/design-v0.1.0/arc02-gate-pipeline/slice05-verification-boundary/cdc-verification.md`
6. `docs/design-v0.1.0/arc03-stdio-pipeline/arc-plan.md`
7. `docs/design-v0.1.0/arc03-stdio-pipeline/slice01-stdio-contract-investigation/slice-doc.md`
8. `docs/design-v0.1.0/arc03-stdio-pipeline/slice01-stdio-contract-investigation/ledger.md`
9. `src/wolong-exec.lfe`
10. `src/wolong-gate.lfe`
11. `src/wolong-pipeline.lfe`
12. `test/wolong_exec_SUITE.lfe`
13. `test/wolong_gate_SUITE.lfe`
14. `test/wolong_pipeline_SUITE.lfe`
15. `test/wolong_dispatch_SUITE.lfe`
16. `../chengdu/docs/reference/cli.md`
17. `../chengdu/docs/managed-process.md`
18. `../chengdu/bin/`

Also load the collaboration framework. Load Erlang/OTP guidance if you touch
LFE code or tests. Ledger discipline applies: update `ledger.md` as you work
with attested evidence, and do not leave all evidence for the final close.

## Mission

Investigate whether Wolong can safely drive the real Chengdu 0.3.0
`pandapi-*` binaries through stdin/stdout/stderr under erlexec.

This slice is not an implementation slice. Its output is an evidence-backed
decision:

- `proceed` - Chengdu exposes the needed stdio contract and erlexec/LFE can
  drive it safely.
- `Wolong-design-needed` - Chengdu is adequate, but Wolong needs a specific
  runner/backpressure/pipeline design before implementation.
- `Chengdu-blocked` - Chengdu is missing or buggy; pause Wolong arc03
  implementation until Chengdu fixes/adds the required behavior.

Do not paper over a Chengdu blocker with a Wolong workaround.

## Required Survey

Start with docs and binary identity:

```bash
ls -al ../chengdu/bin
sed -n '1,260p' ../chengdu/docs/reference/cli.md
sed -n '1,340p' ../chengdu/docs/managed-process.md
../chengdu/bin/pandapi-parser --help
../chengdu/bin/pandapi-grounder --help
../chengdu/bin/pandapi-engine --help
../chengdu/bin/pandapi-parser --version
../chengdu/bin/pandapi-grounder --version
../chengdu/bin/pandapi-engine --version
```

Use current `pandapi-*` names only.

## Investigation Probes

Design probes that answer these questions with command output:

1. Can parser accept domain/problem through stdin? If so, what exact argument
   form is supported?
2. Can parser write its artifact to stdout with `--output -` while status stays
   on stderr?
3. Can grounder read parser artifact from stdin and write grounded artifact to
   stdout?
4. Can engine read grounded artifact from stdin and write solved plan to stdout?
5. Can the same stdio shape represent valid no-plan as engine
   `status=domain_no_plan`, exit `2`, without a plan artifact?
6. Does stdout ever contain status, diagnostics, progress, statistics, ANSI, or
   prompts when stdout is the artifact stream?
7. Does stderr always contain a final machine-parseable `PANDAPI_STATUS` record
   for success and representative failures?
8. Can erlexec from LFE write stdin and read stdout/stderr concurrently without
   shell pipelines?
9. Are there buffering/deadlock risks for realistic parser/grounder/engine
   artifact sizes?

Shell pipelines are acceptable for characterizing Chengdu. They are not the
final Wolong implementation design.

## Stop Conditions

Pause and report instead of continuing to implementation if any of these are
true:

- a needed stdin form is undocumented or unsupported;
- stdout artifact output mixes with status or diagnostic prose;
- no final machine status is available on a separate stream;
- a real binary hangs or buffers in a way Wolong cannot supervise safely;
- erlexec cannot support the required stdin/stdout/stderr interaction from LFE
  without unmanaged shell glue;
- Chengdu docs and binary behavior disagree in a release-blocking way.

For each blocker, record:

- exact command;
- expected behavior;
- observed behavior;
- exit code;
- stdout/stderr summary;
- why this blocks Wolong;
- re-entry condition.

## Scope Guard

Do not land:

- production stdio runner implementation;
- public API shape changes;
- release provisioning/downloader/checksum/Hex work;
- legacy `pandaPI*` fallback;
- diagnostic-prose classifier;
- public `wolong:verify`;
- action-sequence parser;
- decomposition-tree parser;
- broad repo formatting sweep.

If you need a small committed probe, make it test-only, narrow, and ledgered.
Prefer recording command evidence in `ledger.md` and `closing-report.md`.

## Verification Before Close

Run and record the normal local gates for any committed change:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
```

If `rebar3 lfe format --check` fails due to pre-existing formatting state,
record the exact failure and do not fix unrelated files unless the operator
opens a formatting slice.

Run scope greps for the forbidden implementation work and inspect any hits:

```bash
rg -n 'defun verify|\(verify [0-9]|wolong:verify' src test
rg -n 'pandaPIparser|pandaPIgrounder|pandaPIengine' src test README.md
rg -n 'diagnostic prose|grep.*stderr|stderr.*grep|re:run.*stderr|stderr.*re:run' src test
rg -n 'download|provision|checksum|SHA256|hex\.pm' src test README.md
```

## Close

When investigation is complete:

1. Update all SI-1 through SI-16 ledger rows with final status and evidence.
2. Write `closing-report.md` with:
   - the decision: proceed, Wolong-design-needed, or Chengdu-blocked;
   - the per-row walk;
   - the exact command evidence;
   - any Chengdu blocker with re-entry condition;
   - implementation recommendations for later Arc03 slices;
   - Bubble-up to Arc03/project.
3. Update `../arc-plan.md` and `../../project-plan.md` Version History if the
   investigation changes later slices, pauses Wolong, or changes the roadmap.
4. Do not create `cdc-verification.md`; CDC writes it after independent
   reproduction.
