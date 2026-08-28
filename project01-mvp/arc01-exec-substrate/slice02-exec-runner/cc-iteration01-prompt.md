# CC iteration 01 prompt: wolong arc01 / slice02 exec-runner

CDC re-ran the Slice02 evidence and found one blocking ledger mismatch plus
one stale closure item. Do not broaden the slice; this is a narrow correction
pass.

## Finding F-1: R-1 OTP 28 branch-head claim does not reproduce

**Ledger row:** R-1  
**Significance:** correctness-grade  
**Status:** blocking

The implementation pins CI to OTP `28.5.0.4` and records it as the current OTP
28 branch head from the live survey. That claim no longer reproduces against
the official Erlang sources checked by CDC:

- `https://erlang.org/download/` lists `OTP-28.5.0.5.README` dated
  `04-Aug-2026 09:59`, after `OTP-28.5.0.4`.
- `https://erlang.org/download/otp_versions_tree.html` shows `maint-28` at
  `OTP 28.5.0.5`, with `OTP 28.5.0.4` one row below it.

**Required fix:** update `.github/workflows/build.yml` from `28.5.0.4` to the
current OTP 28 branch head, currently `28.5.0.5`, unless the operator chooses
an explicit rationale for staying on `28.5.0.4`. Record the exact live survey
evidence and date in `ledger.md` and `closing-report.md`.

## Finding F-2: R-8 remote CI evidence is now available

**Ledger row:** R-8  
**Significance:** correctness-grade  
**Status:** stale deferred row

CC marked R-8 deferred because the session had not pushed. The repository now
has a pushed green workflow run at HEAD:

- Run: `https://github.com/billosys/wolong/actions/runs/31764886567`
- Commit: `6d6803826c756cfad4822b68e990c5d4259e3062`
- Conclusion: success
- Jobs: `build (ubuntu-22.04)` success; `build (macos-15)` success
- Steps in both jobs: checkout, setup-beam, compile, eunit, xref, dialyzer all
  success

**Required fix:** after correcting R-1 and pushing the new commit, replace the
R-8 deferred status with `done` only when the new run for that corrected commit
is green on both matrix legs. Update the row count in `ledger.md` and
`closing-report.md` accordingly.

## Evidence CDC already reproduced

These do not need rework unless the OTP pin change breaks them:

```bash
rebar3 compile        # exit 0
rebar3 as test eunit  # 19 tests, 0 failures, exit 0
rebar3 xref           # exit 0
rebar3 dialyzer       # exit 0
```

CDC also inspected:

- `src/wolong-exec.lfe`
- `test/unit-wolong-exec-tests.lfe`
- `test/fixtures/exec-runner/*.sh`
- `.github/workflows/build.yml`
- Slice02 `ledger.md` and `closing-report.md`

The runner implementation, fixture coverage, scope fence, and local gates held
up under CDC review. The slice is blocked on the recorded OTP branch-head
claim and then on fresh CI evidence for the corrected commit.

## Close this iteration

1. Apply the R-1 pin/rationale correction.
2. Update `ledger.md` R-1 and R-8 with current evidence.
3. Update `closing-report.md` so the per-row walk and totals match the ledger.
4. Run:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 xref
rebar3 dialyzer
```

5. Push, wait for GitHub Actions, and record the green run URL for both matrix
   jobs.

Do not create `cdc-verification.md`; CDC writes that after the corrected close
is independently reproduced.

