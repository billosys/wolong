# Slice 02 Closing Report: stdio-runner

Proposed done by CC on 2026-08-26. Verifier: CDC.

## Summary

Slice02 adds an explicit stdin-capable Wolong runner API:

```lfe
(wolong-exec:run-stdin command args stdin-bytes opts)
```

The existing no-stdin API remains:

```lfe
(wolong-exec:run command args opts)
```

`run-stdin/4` accepts a binary stdin payload, starts the child with erlexec
argv-list execution plus the `stdin` option, sends the bytes with
`exec:send/2`, sends EOF with `exec:send(Pid, eof)`, and then reuses the
existing stdout/stderr collection, output caps, nonzero-exit handling, timeout
cleanup, and result builders.

The preferred `run/4` shape from the prompt did not fit LFE cleanly in this
codebase: separate same-name `defun` forms collided, and match-style `defun`
clauses require a common arity. The landed API is therefore explicit as
`run-stdin/4`, preserving `run/3` compatibility without relying on an awkward
same-name arity split.

Implementation commit:

- `a6b7847` - `Add stdin-capable exec runner`

## Delivered

- `src/wolong-exec.lfe`
  - exports `run-stdin/4`;
  - validates stdin payloads as binaries;
  - rejects unsupported stdin shapes as `#(error #(exec invalid-stdin ...))`;
  - adds erlexec `stdin` only for stdin runs;
  - sends stdin bytes and EOF before entering the existing collection loop;
  - converts `exec:send/2` exceptions to
    `#(error #(exec stdin-send-failed ...))`;
  - preserves `run/3` no-stdin behavior.
- `test/wolong_exec_SUITE.lfe`
  - expands the runner suite from 10 to 18 CT cases;
  - covers stdin EOF, empty stdin EOF, invalid stdin, shell-free argv,
    nonzero exit, validation errors, timeout kill, recovery, stream separation,
    and independent caps.
- `test/fixtures/exec-runner/`
  - adds Wolong-owned stdin fixtures for EOF-sensitive echo, nonzero exit,
    output flood, and TERM-resistant timeout.

## Local Chengdu Smoke

Sibling Chengdu binaries were available. A local-only smoke probe ran
`wolong-exec:run-stdin/4` against current
`../chengdu/bin/pandapi-grounder`:

```text
command: ../chengdu/bin/pandapi-grounder
args: ["--supervised","--status=stderr","--output","-","-"]
stdin: ../chengdu/fixtures/grounder/minimal.htn
result: #(ok Result)
exit-status: 0
stdout-bytes: 446
stderr-bytes: 208
stderr status: PANDAPI_STATUS status=ok component=grounder artifact=stdout path_role=htn path=- operation=read
```

This is not a CI dependency. Remote CI remains fixture-backed until Chengdu
release artifacts are available through an explicit provisioning path.

## Tamper Cycle

Tamper: temporarily changed `send-stdin/2` so it sent stdin bytes but skipped
`exec:send(Pid, eof)`.

Expected failure command:

```bash
rebar3 compile && rebar3 as test ct --suite test/wolong_exec_SUITE.lfe
```

Observed failure: nonzero exit; 7 stdin tests failed and 11 passed. EOF
fixtures timed out, including `stdin_bytes_and_eof_are_sent`,
`empty_stdin_sends_eof`, `stdin_argv_metacharacters_arrive_unchanged`,
`nonzero_exit_after_stdin_is_completed_result`, and cap/recovery cases that
wait on stdin completion.

Reverted tamper and reran the same command. Observed pass: all 18
`wolong_exec_SUITE` tests passed.

## Verification

Local gates passed on 2026-08-26:

```text
rebar3 compile: pass
rebar3 as test eunit: pass, 9 tests, 0 failures
rebar3 as test ct: pass, all 70 tests passed
rebar3 xref: pass
rebar3 dialyzer: pass
rebar3 lfe format --check: pass, all 13 files formatted
```

Focused runner suite:

```text
rebar3 as test ct --suite test/wolong_exec_SUITE.lfe: pass, all 18 tests passed
```

Remote CI:

```text
GitHub Actions build 33027645336 for a6b7847: success
ubuntu-22.04: success
macos-15: success
https://github.com/billosys/wolong/actions/runs/33027645336
```

## Ledger Walk

- **SR-1 - done.** `run/3` remains exported and compatible. Existing no-stdin
  exec CT cases still pass, and full CT passed 70/0.
- **SR-2 - done.** The stdin-capable API is `run-stdin/4`, exported by
  `wolong-exec` and called directly from CT. This is an intentional explicit
  API because LFE same-name arity grouping was not a clean fit here.
- **SR-3 - done.** Binary stdin payloads are accepted; unsupported stdin shapes
  return `#(error #(exec invalid-stdin ...))`.
- **SR-4 - done.** EOF-sensitive fixtures complete after stdin bytes and EOF.
  Empty stdin also sends EOF and completes.
- **SR-5 - done.** Stdin runs still use argv-list `exec:run argv options`.
  The metacharacter CT case proves args are not shell-expanded.
- **SR-6 - done.** Stdin fixtures write deterministic stdout and stderr, and
  CT asserts the streams separately.
- **SR-7 - done.** Stdin flood fixture proves stdout/stderr caps and truncation
  metadata remain independent.
- **SR-8 - done.** Nonzero exit after stdin returns a completed result with
  exit status `7` and captured streams.
- **SR-9 - done.** Missing executable, invalid command, invalid args, and
  invalid options remain typed errors in stdin-adjacent tests.
- **SR-10 - done.** TERM-resistant stdin child times out, is killed, leaves no
  surviving PID, and reports a typed timeout result.
- **SR-11 - done.** Invalid-stdin and timeout tests each perform a successful
  stdin runner call afterward, proving recovery.
- **SR-12 - done.** Diff scope is limited to `wolong-exec`, its CT suite, and
  exec-runner fixtures. No pipeline or public planning API behavior changed.
- **SR-13 - done.** This slice does not model parser `- -` as supported.
  Slice03 must preserve the Chengdu caveat: parser accepts exactly one HDDL
  stdin input, while grounder and engine consume artifact stdin.
- **SR-14 - done.** Local real-Chengdu smoke passed through `run-stdin/4`
  against `pandapi-grounder`.
- **SR-15 - done.** Required local gates and formatter check passed.
- **SR-16 - done.** EOF tamper failed the owning CT gate, then passed after
  revert.
- **SR-17 - done.** GitHub Actions build `33027645336` for implementation
  commit `a6b7847` passed on `ubuntu-22.04` and `macos-15`. CI is
  fixture-backed and does not depend on sibling Chengdu.
- **SR-18 - done.** This report walks all 18 rows and includes bubble-up.

## Bubble-up to the Arc

Slice02 lands `wolong-exec:run-stdin/4` as the explicit stdin-capable runner
API. It sends binary stdin bytes and EOF, preserves `run/3`, keeps argv-list
execution, keeps stdout and stderr separately captured, preserves independent
caps, treats nonzero child exits as completed process results, and preserves
timeout kill-group cleanup and recovery.

Slice03 can now rewire gate artifacts through the supported Chengdu stdio
shape. It must not assume parser `- -`; Chengdu supports exactly one parser
HDDL input from stdin, while grounder and engine support artifact stdin.

Slice05 backpressure hardening should remain separate unless Slice03 proves
the current bounded capture policy is sufficient for release-scale artifacts.
Slice02 proves cap semantics and concurrent stream draining for fixture-scale
stdin runs, not large real artifact stress.

## Bubble-up to the Project

Project roadmap shape does not change. Arc03 is no longer blocked at the
runner substrate: the next project-critical work is Slice03, wiring the
parser -> grounder -> engine gate pipeline through the stdio path while
preserving validated-plan-or-unsolvable semantics and the explicit
verification boundary.
