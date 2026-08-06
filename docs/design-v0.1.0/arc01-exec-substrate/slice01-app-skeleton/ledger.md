# Slice 01 (wolong arc01): app-skeleton

> Ledger per `LEDGER-DISCIPLINE.md` (v2.0), Section A. All rows open at
> slice start, 2026-08-06. Closer: CC. Verifier: CDC (authenticated
> clone, Linux build+test reproduction in the sandbox, CI runs fetched
> independently, per-row re-walk). Run evidence must link the specific
> run.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| K-1 | `billosys/wolong` exists, public, default branch `main`, first commits carrying the pre-existing planning docs + CLAUDE.md (with the direct-to-main convention recorded); org and visibility correct on first creation. | repo page fetched; `gh api repos/billosys/wolong` or page inspection; CLAUDE.md diff | correctness | slice-doc §2; the chengdu repo-home lesson | open | | org-correct at birth — no transfer step this time |
| K-2 | `rebar3 compile` (with the LFE plugin) succeeds from a clean clone with warnings-as-errors; every dep in `rebar.config` pinned to an exact version (no floats, no branch refs); the OTP app metadata is correct (`mod`, `applications` incl. `exec`). | clean-clone build in sandbox (Linux) + CC attest (macOS); read rebar.config + .app.src | serious | slice-doc §2 | open | | erlexec compiles native code — both platforms matter |
| K-3 | `application:ensure_all_started(wolong)` returns ok with `wolong_sup` alive under the declared strategy and exec's own tree running; `application:stop(wolong)` is clean — zero error/crash reports in the log for the start/stop cycle (asserted by a test, not by eyeball). | run the start/stop test; read the supervisor init | serious | arc-plan §1 | open | | |
| K-4 | `wolong-config` reads the three config keys (`binaries`, `gate-timeouts`, `workdir`) and validates shape/presence with a **distinct typed error per failure mode** (missing key, wrong shape, non-string path); happy path returns a validated config term; `config/sys.config` example parses and passes. No invented defaults for binary paths. | tests exercise happy + every error path; CDC calls the error paths directly from a shell | serious | arc-plan OQ3 (resolved default); project API contract | open | | the typed-error discipline starts here |
| K-5 | The erlexec probe: a supervised, synchronous run of a trivial OS command from LFE returns a matched `#(ok ...)`; a nonexistent-command run returns a matched `#(error ...)` (typed, not crashed); **the OQ1 ergonomics verdict (direct calls vs thin wrapper) is recorded in the arc-plan via a tracked change**, whatever it is. | run both probe tests; read the arc-plan Version History entry | serious | arc-plan OQ1 (owned by this slice) | open | | an unrecorded verdict fails this row even if the code works |
| K-6 | The test suite is real and falsifiable: covers K-3/K-4/K-5's claims; runs green via rebar3 locally and in CI; and a tamper test (invert one assertion) demonstrably fails the suite with nonzero exit before being reverted. | run suite; perform tamper; revert; re-run | correctness | house vacuous-test rule | open | | |
| K-7 | CI green on one linked run: `ubuntu-22.04` + `macos-15`, pinned BEAM-setup action major, pinned OTP/rebar3/LFE versions (surveyed live, choice + rationale in Evidence), steps compile → test → xref → dialyzer, all clean; actionlint zero findings. | run page fetched independently; actionlint locally; read pins | serious | slice-doc §2 | open | | dialyzer exclusions, if any, individually justified inline |
| K-8 | README stub current: the contract paragraph (incl. validated-plan-or-unsolvable), status, dev setup pointing at chengdu `v0.1.0`'s 4-command install for binaries (link), CI badge. CLAUDE.md updated with the recorded workflow convention. | read README/CLAUDE.md at HEAD; badge renders | polish | slice-doc §2 | open | | |

## What Worked

_(At slice close.)_

## Closure

_Open. Rows: 8. Done: 0. Deferred: 0. No-op: 0._
