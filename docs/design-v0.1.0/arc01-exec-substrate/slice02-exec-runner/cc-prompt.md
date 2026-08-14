# CC prompt: wolong arc01 / slice02 exec-runner

You are CC implementing `slice02-exec-runner` in
`/Users/oubiwann/lab/billosys/wolong`.

## Read first

1. `CLAUDE.md`
2. `docs/design-v0.1.0/project-plan.md`
3. `docs/design-v0.1.0/arc01-exec-substrate/arc-plan.md`
4. `docs/design-v0.1.0/arc01-exec-substrate/slice01-app-skeleton/closing-report.md`
5. `docs/design-v0.1.0/arc01-exec-substrate/slice01-app-skeleton/cdc-verification.md`
6. `docs/design-v0.1.0/arc01-exec-substrate/slice02-exec-runner/slice-doc.md`
7. `docs/design-v0.1.0/arc01-exec-substrate/slice02-exec-runner/ledger.md`

Also load the collaboration framework and the Erlang/LFE guidance used by this
repo. Ledger discipline applies: update the ledger as you work, with
attested evidence; do not leave evidence until the final close.

## Mission

Build `wolong-exec`, the generic erlexec-backed runner used by later pandaPI
gates. This slice proves process mechanics only: typed completion results,
nonzero exit status capture, separated stdout/stderr, argv safety, timeouts,
kill escalation, output caps, no-zombie evidence, post-failure recovery, and
CI coverage.

Do not implement pandaPI-specific behavior in this slice.

## Required shape

Add `src/wolong-exec.lfe` exposing:

```lfe
(wolong-exec:run command args opts)
```

where `command` is a string/binary executable path or name, `args` is a list of
string/binary argv entries, and `opts` is a map containing at least:

- `timeout-ms`
- `kill-timeout-sec`
- `output-limit-bytes`

Optional `cwd` and `env` are allowed if you can test them cleanly without
stretching the slice. If they make the slice sprawl, defer them explicitly.

Return only typed shapes:

```lfe
#(ok Result)
#(timeout Result)
#(error #(exec Reason Detail))
```

`Result` should carry at least `exit-status`, `stdout`, `stderr`,
`duration-ms`, and output truncation metadata for completed runs. Timeout
results should carry partial output, timeout metadata, kill metadata, and
duration metadata.

Nonzero process exit is still `#(ok Result)`. The gate layer decides whether
exit code 2 means missing file, invalid input, or anything else.

## Fixtures and tests

Add POSIX fixture scripts under `test/fixtures/exec-runner/` and LFE tests
under `test/`, probably `test/unit-wolong-exec-tests.lfe`.

Cover at minimum:

- exit 0 with stdout/stderr;
- nonzero exit with stdout/stderr;
- argv argument containing spaces and shell metacharacters, observed unchanged;
- bad executable returns `#(error #(exec ...))` and leaves the app usable;
- simple timeout;
- TERM-resistant timeout that proves kill escalation and no surviving OS
  process using PID-file or process-table evidence;
- stdout and stderr output flood with independent truncation metadata;
- post-timeout recovery: a normal command succeeds after the timeout case.

Use `rebar3 as test eunit`, not `rebar3 lfe ltest`, as the test gate. Avoid
depending on `ltest` wildcard matching unless you first prove it works in this
environment.

## Slice01 F-1 disposition

Before closing R-1, survey the current OTP 28 branch state live or use an
operator-approved rationale. Then either:

- update `.github/workflows/build.yml` to the selected OTP 28 branch head and
  record the evidence; or
- leave `28.1.1` pinned and record the explicit operator rationale.

Do not treat "matches my machine" as sufficient by itself.

## Scope guard

Stay inside slice02:

- no pandaPI binary invocation;
- no `wolong:validate`, `wolong:plan`, or `wolong:verify`;
- no binary locator;
- no gate pipeline or `gen_statem`;
- no hex.pm publishing;
- no broad config redesign without a ledger amendment.

## Verification before close

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 xref
rebar3 dialyzer
```

Also perform one tamper cycle: break a meaningful runner assertion, show
`rebar3 as test eunit` fails with nonzero exit, revert the tamper, and show
the suite passes again.

If CI is available, record the linked green run on both Ubuntu and macOS. If
CI or network access is blocked, record the exact blocker and re-entry
condition; do not claim CI reproduction from local evidence.

## Close

When implementation is complete:

1. Update every row in `ledger.md` with final status and attested evidence.
2. Write `closing-report.md` with a per-row walk for all 9 rows.
3. Add `Bubble-up to the arc` answering:
   - did slice02 deliver the slice breakdown line in `arc-plan.md`;
   - what did implementation reveal that the arc plan did not anticipate;
   - scope-as-specified vs. scope-as-delivered, with deferrals named.
4. Do not create `cdc-verification.md`; CDC writes that after independent
   reproduction.

