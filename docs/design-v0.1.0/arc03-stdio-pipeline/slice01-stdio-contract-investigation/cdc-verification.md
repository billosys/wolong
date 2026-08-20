# CDC Verification: Slice 01 Stdio Contract Investigation

Verified by CDC on 2026-08-20.

Reviewed commits:

- `b52c6db` - `Record Arc03 stdin contract blocker`
- `91cd47c` - `Close Arc03 stdio contract investigation`

CDC result: accepted as **Chengdu-blocked**.

## Scope Reviewed

Changed files in the two CC commits:

```text
README.md
docs/design-v0.1.0/project-plan.md
docs/design-v0.1.0/arc03-stdio-pipeline/arc-plan.md
docs/design-v0.1.0/arc03-stdio-pipeline/slice01-stdio-contract-investigation/ledger.md
docs/design-v0.1.0/arc03-stdio-pipeline/slice01-stdio-contract-investigation/closing-report.md
```

CDC made one narrow follow-up correction before this verification: the project
status heading for Arc02 now says closed instead of open. The surrounding text
already said all five Arc02 slices were CDC-closed, so this was a consistency
fix, not a change to the slice decision.

No production source or test code changed in the slice.

## Reproduced Chengdu Evidence

CDC reproduced the current Chengdu binary identity:

```text
../chengdu/bin/pandapi-parser --version
../chengdu/bin/pandapi-grounder --version
../chengdu/bin/pandapi-engine --version
```

All three commands exited 0 and reported `chengdu_version=0.3.0` and
`managed_process_contract=0.3.0`.

CDC also reproduced the supported docs shape in:

```text
../chengdu/docs/reference/cli.md
../chengdu/docs/managed-process.md
```

The supported invocation forms are path operands plus optional artifact stdout:

```text
pandapi-parser [COMMON] [--output OUT.htn|-] DOMAIN.hddl PROBLEM.hddl
pandapi-grounder [COMMON] [--output OUT.sas|-] INPUT.htn
pandapi-engine [COMMON] [--output PLAN|-] INPUT.sas
```

The docs require stdout to have one owner. `--output -` may own stdout for the
artifact, while `--status=stderr` keeps final machine status on stderr.

## Reproduced Probe Results

CDC reproduced the positive output-side behavior:

```text
parser file input with --output -: exit 0, stdout 2444 bytes,
  stderr status=ok artifact=stdout
grounder file input with --output -: exit 0, stdout 446 bytes,
  stderr status=ok artifact=stdout
engine solved file input with --output -: exit 0, stdout 2039 bytes,
  stderr status=ok artifact=stdout outcome=solved
engine no-plan file input with --output -: exit 2, stdout 0 bytes,
  stderr status=domain_no_plan outcome=no_plan
```

CDC reproduced the input-stdin blocker:

```text
parser domain input "-": exit 10, stdout 0 bytes, stderr status=cli_usage_error
parser problem input "-": exit 10, stdout 0 bytes, stderr status=cli_usage_error
grounder input "-": exit 10, stdout 0 bytes, stderr status=cli_usage_error
engine input "-": exit 10, stdout 0 bytes, stderr status=cli_usage_error
```

CDC reproduced the direct-pipe blocker:

```text
parser stdout -> grounder stdin: pipeline exit 10,
  downstream status=cli_usage_error
grounder stdout -> engine stdin: pipeline exit 10,
  downstream status=cli_usage_error
```

CDC reproduced stdout/status ownership safety:

```text
parser --status=stdout --output -: exit 10, status=cli_usage_error
```

The observed behavior supports CC's conclusion precisely: Chengdu artifact
stdout and status separation are usable, but input `-` is not supported for the
required parser, grounder, or engine inputs.

## erlexec Feasibility Check

CDC inspected `_build/default/lib/erlexec/README.md`,
`_build/default/lib/erlexec/src/exec.erl`, and `src/wolong-exec.lfe`.

erlexec exposes the needed substrate for stdin/stdout/stderr process control:
`stdin`, `{stdin, ...}`, `exec:send/2`, EOF send, separate stdout/stderr
messages without pty mode, `monitor`, and `kill_group`. Wolong's current runner
does not expose stdin, but erlexec itself is not the blocker found by this
slice.

## Scope Checks

`git diff --check HEAD~2..HEAD` passed before CDC's follow-up doc correction.

CDC reproduced scope greps across `src`, `test`, `README.md`, and the slice
directory. Hits were limited to public deferral text, slice instructions, or
closing-report prose. No production stdio runner, public API change,
provisioning implementation, legacy binary fallback, verifier implementation,
action parser, decomposition parser, or diagnostic-prose classifier landed.

## Reproduced Gates

Local gates reproduced on the CDC verification tree:

```text
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
```

Results:

```text
compile: pass
eunit: pass, 9 tests, 0 failures
ct: pass, all 62 tests passed
xref: pass
dialyzer: pass
formatter: pass, all 13 files formatted
```

## Ledger Disposition

| Row | CDC disposition |
|-----|-----------------|
| SI-1 | accepted |
| SI-2 | accepted |
| SI-3 | accepted |
| SI-4 | accepted |
| SI-5 | accepted |
| SI-6 | accepted |
| SI-7 | accepted |
| SI-8 | accepted |
| SI-9 | accepted |
| SI-10 | accepted |
| SI-11 | accepted |
| SI-12 | accepted |
| SI-13 | accepted |
| SI-14 | accepted |
| SI-15 | accepted |
| SI-16 | accepted |

Rows: 16. Accepted: 16. Rejected: 0. Deferred: 0.

## Bubble-up Check

Arc03 is correctly paused before `slice02-stdio-runner`. Project W1 remains
open and Arc04 provisioning must not start from a claim that stdin pipeline
behavior is proven.

The correct re-entry condition is one of:

- Chengdu documents and implements input stdin for `pandapi-parser`,
  `pandapi-grounder`, and `pandapi-engine`, including parser role semantics for
  the two HDDL inputs.
- Wolong explicitly rescopes Arc03 from a stdin pipeline to a file-input plus
  stdout-artifact temporary-file bridge.

No further Wolong implementation slice should open until that decision changes.
