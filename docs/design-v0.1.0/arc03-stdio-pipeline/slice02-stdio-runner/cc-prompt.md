# CC prompt: wolong arc03 / slice02 stdio-runner

You are CC implementing `slice02-stdio-runner` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read First

1. `AGENTS.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc03-stdio-pipeline/arc-plan.md`
4. `docs/design-v0.1.0/arc03-stdio-pipeline/slice01-stdio-contract-investigation/closing-report.md`
5. `docs/design-v0.1.0/arc03-stdio-pipeline/slice02-stdio-runner/slice-doc.md`
6. `docs/design-v0.1.0/arc03-stdio-pipeline/slice02-stdio-runner/ledger.md`
7. `/Users/oubiwann/lab/lfe/lfe-manual/src/part7/ai-resources/style-guide.md`
8. `/Users/oubiwann/lab/lfe/lfe/test/*SUITE.lfe` for canonical LFE Common Test examples
9. `src/wolong-exec.lfe`
10. `src/wolong-status.lfe`
11. `src/wolong-gate.lfe`
12. `test/wolong_exec_SUITE.lfe`
13. `test/fixtures/exec-runner/`
14. `rebar.config`

Also load the collaboration framework and Erlang/OTP guidance for processes,
external command boundaries, and Common Test. Ledger discipline applies:
update `ledger.md` as you work with attested evidence, and do not leave all
evidence for the final close.

## Mission

Add stdin bytes plus EOF support to Wolong's generic erlexec runner.

The active blocker has moved from Chengdu to Wolong. Current Chengdu
`release/0.3.x` at `e55ef5fd` proves the supported artifact stdio contract:
parser accepts exactly one `-` HDDL input, parser `- -` is a documented usage
error, grounder accepts artifact stdin, engine accepts artifact stdin, and the
full Chengdu-side solved/no-plan pipe passes. Wolong now needs a runner that
can drive that shape without shell command strings.

## Required Shape

Preserve the existing no-stdin runner:

```lfe
(wolong-exec:run command args opts)
```

Add an explicit stdin-capable runner surface. Preferred shape:

```lfe
(wolong-exec:run command args stdin-bytes opts)
```

where `stdin-bytes` is a binary payload and EOF is sent after the payload.
Use the exact implementation shape that best fits LFE and erlexec, but keep
the public runner contract explicit, typed, and ledgered.

The new stdin path must preserve:

- argv-list execution;
- command lookup and typed missing/non-executable errors;
- separated stdout and stderr capture;
- independent output caps and truncation metadata;
- nonzero exit status as a completed process result;
- timeout result shape and kill-group cleanup;
- recovery after timeout/failure;
- no shell command strings.

## Scope Guard

Stay inside Slice02.

- Do not rewire `wolong-pipeline` to stdio yet.
- Do not change public `wolong:plan/2`, `wolong:plan/3`, or
  `wolong:validate/2` behavior.
- Do not implement provisioning, downloader, checksum verification, or Hex
  release work.
- Do not model parser `- -` as supported. Chengdu currently supports exactly
  one parser stdin input.
- Do not add a diagnostic-prose classifier.
- Do not add legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine`
  fallback.
- Do not create `cdc-verification.md`; CDC writes that after independent
  reproduction.

## Tests and Fixtures

Use Common Test. Either extend `test/wolong_exec_SUITE.lfe` or add a focused
`test/wolong_exec_stdio_SUITE.lfe`.

Required cases:

- `run/3` no-stdin behavior remains compatible;
- `run/4` sends stdin bytes and EOF to a child that waits for EOF;
- empty stdin binary sends EOF and completes;
- invalid stdin shape returns a typed `exec` error;
- stdout and stderr stay separated for stdin runs;
- output caps apply independently to stdout and stderr for stdin runs;
- args with shell metacharacters are passed literally while stdin is used;
- child nonzero exit after stdin returns a completed process result;
- timeout/TERM-resistant stdin child is killed as a process group and leaves
  no survivor;
- a successful stdin run after timeout/failure proves recovery.

Use Wolong-owned fixtures. Shell scripts are fine as fixture executables, but
Wolong must invoke them as argv-list erlexec commands, not shell pipelines.

Remote CI must not depend on `../chengdu`. If sibling Chengdu binaries are
available locally, run one narrow smoke through the new runner against
`../chengdu/bin/pandapi-grounder` or `../chengdu/bin/pandapi-engine` and record
it separately as local evidence only.

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

Also perform one tamper cycle. Break a meaningful new stdin invariant: for
example skip EOF, merge stderr into stdout, remove output caps, route through
a shell string, or disable timeout cleanup. Show the owning CT gate fails
nonzero, revert the tamper, and show it passes again.

If CI is available, push and record the linked green run on both Ubuntu and
macOS. State directly that remote CI is fixture-backed unless release artifacts
have been added separately.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all 18 ledger rows.
3. Add `Bubble-up to the arc` answering:
   - what stdin-capable runner API landed;
   - whether `run/3` compatibility held;
   - whether EOF, stream separation, caps, timeout cleanup, and recovery are
     proven;
   - how the parser exactly-one-stdin-input caveat affects Slice03;
   - whether Slice05 backpressure hardening should remain separate.
4. Update `../arc-plan.md` if runner findings change later slice scope,
   sequencing, or the arc ledger.
5. Update `../../project-plan.md` only if the project roadmap or release
   readiness wording changes.
6. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.
