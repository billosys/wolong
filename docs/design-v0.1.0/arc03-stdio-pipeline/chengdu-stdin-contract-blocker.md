# Chengdu stdin contract blocker report

Date: 2026-08-20.

Source: Wolong Arc03 Slice01, `stdio-contract-investigation`.

Status: Superseded 2026-08-26 by Chengdu `release/0.3.x` re-entry evidence.
Wolong Arc03 has resumed at `slice02-stdio-runner`.

## Superseded status

This report remains the historical record of the 2026-08-20 blocker. It is no
longer the live Wolong gate.

Current Chengdu `release/0.3.x` at `e55ef5fd` now proves the supported artifact
stdio contract: `make test-contract-stdio-managed` passes 187/0; parser accepts
exactly one stdin HDDL input (`domain -` or `problem -`); parser `- -` remains
a documented `cli_usage_error`; grounder accepts artifact stdin; engine accepts
artifact stdin and preserves solved/no-plan status behavior.

The active Arc03 blocker is now Wolong-owned: extend `wolong-exec` with stdin
bytes plus EOF support while preserving argv-list erlexec execution, separated
stdout/stderr capture, output bounds, typed classification, timeout cleanup,
and no shell command strings.

## Summary

Wolong Arc03 was opened to prove the release-critical process contract for the
Chengdu 0.3.0 `pandapi-*` binaries:

```text
pandapi-parser -> pandapi-grounder -> pandapi-engine
```

The target was a supervised erlexec-managed pipeline where Wolong can write
inputs to stdin, read artifacts from stdout, read final machine status from
stderr, and classify every result from exit code plus final `PANDAPI_STATUS`.

The investigation found that Chengdu's output side is in good shape:

- `--output -` can write parser, grounder, and engine artifacts to stdout.
- `--status=stderr` keeps final `PANDAPI_STATUS` separate from artifact stdout.
- Chengdu rejects unsafe stdout ownership conflicts such as
  `--status=stdout --output -`.
- Engine valid no-plan remains machine typed as `status=domain_no_plan`,
  exit `2`, not a generic failure.

The blocker is input stdin. Current Chengdu local 0.3.0 binaries reject input
path `-` for all three supported components:

- parser domain input `-`;
- parser problem input `-`;
- parser both-input attempt `- -`;
- grounder input `-`;
- engine input `-`.

Each rejected stdin-input probe exits `10` with final
`status=cli_usage_error`. That prevents Wolong from implementing the direct
stdin/stdout/stderr pipeline Arc03 was created to prove.

## What Wolong tried to do

Wolong was not trying to invent a new Chengdu surface. The investigation was
to determine whether the current documented Chengdu 0.3.0 managed-process
surface could be driven as a well-behaved supervised CLI pipeline.

The desired supervised shape was:

1. `pandapi-parser`
   - receive HDDL domain/problem input through a documented stdin contract;
   - emit parser artifact to stdout with `--output -`;
   - emit final `PANDAPI_STATUS` to stderr with `--status=stderr`.
2. `pandapi-grounder`
   - receive parser artifact from stdin;
   - emit grounded planner artifact to stdout;
   - emit final `PANDAPI_STATUS` to stderr.
3. `pandapi-engine`
   - receive grounded planner artifact from stdin;
   - emit solved plan artifact to stdout, or no artifact for valid no-plan;
   - emit final `PANDAPI_STATUS` to stderr.

Wolong's final implementation would still use argv-list erlexec process
management, not shell command strings. Shell probes were used only to
characterize the Chengdu binary behavior.

## What worked

The file-input plus artifact-stdout controls worked:

```text
parser file input with --output -:
  exit 0, stdout artifact 2444 bytes, stderr status=ok artifact=stdout

grounder file input with --output -:
  exit 0, stdout artifact 446 bytes, stderr status=ok artifact=stdout

engine solved file input with --output -:
  exit 0, stdout plan 2039 bytes, stderr status=ok outcome=solved

engine unsolvable file input with --output -:
  exit 2, stdout 0 bytes, stderr status=domain_no_plan outcome=no_plan
```

This is important: Chengdu can produce artifacts on stdout, consume the same
artifact formats from files, and preserve machine-readable status. The failure
is not in artifact content or status classification.

## What blocked

The stdin-input probes failed:

```text
parser domain input "-":
  exit 10, stdout 0 bytes, stderr status=cli_usage_error

parser problem input "-":
  exit 10, stdout 0 bytes, stderr status=cli_usage_error

grounder input "-":
  exit 10, stdout 0 bytes, stderr status=cli_usage_error

engine input "-":
  exit 10, stdout 0 bytes, stderr status=cli_usage_error
```

Direct pipe probes also failed at the downstream stdin reader:

```text
parser stdout -> grounder stdin:
  pipeline exit 10, downstream status=cli_usage_error

grounder stdout -> engine stdin:
  pipeline exit 10, downstream status=cli_usage_error
```

The shell pipeline also caused the upstream process to see a broken pipe once
the downstream process rejected stdin. That is expected fallout from the
downstream `cli_usage_error`, not the root cause.

## Historical pause point

Wolong was paused in:

```text
docs/design-v0.1.0/arc03-stdio-pipeline/
```

The paused slice was:

```text
slice01-stdio-contract-investigation
```

Accepted decision:

```text
Chengdu-blocked
```

The next planned Wolong slice, `slice02-stdio-runner`, was not allowed to start
while the Chengdu input contract was missing. The 2026-08-26 re-entry evidence
supersedes that stop condition.

Project W1 remains open. Arc04 provisioning still must not start from a claim
that Wolong's public release-grade stdin pipeline behavior is proven; Chengdu
side readiness is only one dependency.

## What Wolong needs from Chengdu

Wolong needs Chengdu to document and implement a supported input-stdin
contract for all three managed components:

- `pandapi-parser`;
- `pandapi-grounder`;
- `pandapi-engine`.

The contract should define:

1. The exact parser stdin semantics for two HDDL inputs.
   - If one input is stdin and the other is a path, both roles must be
     unambiguous.
   - If both domain and problem may be provided through stdin, Chengdu should
     define the framing or reject that form explicitly.
2. The exact grounder stdin form for parser artifacts.
3. The exact engine stdin form for grounded planner artifacts.
4. The stdout owner when `--output -` is selected.
5. The status owner when `--status=stderr` is selected.
6. The expected exit code and final `PANDAPI_STATUS` for unsupported stdin
   forms, invalid input, solved, no-plan, and usage conflicts.
7. Whether any stdin form is intentionally unsupported. If so, Wolong needs an
   explicit project-level rescope away from a stdin pipeline.

## Candidate acceptance probes

The exact command syntax is Chengdu's design choice, but Wolong needs probes
equivalent to these to pass.

Parser:

```bash
../chengdu/bin/pandapi-parser \
  --supervised \
  --status=stderr \
  --output - \
  - \
  ../chengdu/fixtures/minimal/problem.hddl \
  < ../chengdu/fixtures/minimal/domain.hddl
```

Grounder:

```bash
../chengdu/bin/pandapi-parser \
  --supervised \
  --status=stderr \
  --output - \
  ../chengdu/fixtures/minimal/domain.hddl \
  ../chengdu/fixtures/minimal/problem.hddl \
| ../chengdu/bin/pandapi-grounder \
  --supervised \
  --status=stderr \
  --output - \
  -
```

Engine:

```bash
../chengdu/bin/pandapi-grounder \
  --supervised \
  --status=stderr \
  --output - \
  ../chengdu/fixtures/grounder/minimal.htn \
| ../chengdu/bin/pandapi-engine \
  --supervised \
  --status=stderr \
  --output - \
  -
```

Full solved chain:

```bash
../chengdu/bin/pandapi-parser ... --output - ... \
| ../chengdu/bin/pandapi-grounder ... --output - - \
| ../chengdu/bin/pandapi-engine ... --output - -
```

Full no-plan chain:

```bash
../chengdu/bin/pandapi-parser ... --output - <unsolvable inputs> \
| ../chengdu/bin/pandapi-grounder ... --output - - \
| ../chengdu/bin/pandapi-engine ... --output - -
```

For the full no-plan chain, Wolong needs the final engine outcome to remain:

```text
exit 2
PANDAPI_STATUS	status=domain_no_plan	...	outcome=no_plan
```

## Original Wolong re-entry condition

Wolong could resume Arc03 when one of these became true:

- Chengdu documents and implements input stdin for `pandapi-parser`,
  `pandapi-grounder`, and `pandapi-engine`, including parser role semantics for
  the two HDDL inputs.
- Wolong explicitly rescopes Arc03 from a stdin pipeline to a file-input plus
  stdout-artifact temporary-file bridge.

The first condition is now satisfied by current Chengdu `release/0.3.x`
evidence, with the parser caveat that exactly one HDDL input may be stdin and
`- -` remains unsupported.

## Supporting Wolong evidence

Detailed evidence lives in:

- `slice01-stdio-contract-investigation/closing-report.md`
- `slice01-stdio-contract-investigation/cdc-verification.md`
- `slice01-stdio-contract-investigation/ledger.md`

CDC accepted all 16 ledger rows and reproduced the blocker on 2026-08-20.
