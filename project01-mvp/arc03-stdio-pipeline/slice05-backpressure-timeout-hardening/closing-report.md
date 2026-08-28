# Slice 05 Closing Report: backpressure-timeout-hardening

Proposed done by CC on 2026-08-28. Verifier: CDC.

## Summary

Slice05 hardens the release-critical stdio pipeline for larger artifacts,
noisy diagnostics, final status preservation, stdout truncation, flood
timeouts, process-group cleanup, and post-failure recovery.

Implementation commit:

- `b34f6bc` - `Harden stdio backpressure and timeouts`

## Implemented Policy

`wolong-exec` keeps the existing `output-limit-bytes` option as the
compatibility default for both streams. Callers may now pass optional
`stdout-limit-bytes` and `stderr-limit-bytes` overrides. Observed byte counts
continue to record full stream volume while returned stdout/stderr bytes are
bounded by the configured stream limits.

Stdout is the artifact channel. Parser stdout feeds grounder stdin, grounder
stdout feeds engine stdin, and engine stdout becomes the public plan payload.
If stdout is truncated, the artifact is not usable and Wolong returns a typed
gate error such as `#(error #(engine artifact-truncated Detail))`; no partial
artifact or partial solved plan crosses the API.

Stderr is the diagnostic/status channel. Returned `stderr` is a bounded
diagnostic preview. The runner also keeps a bounded `stderr-tail`; the gate
classifier parses the preview first and then the tail, so a final
`PANDAPI_STATUS` line after noisy diagnostics remains classifiable without
retaining unbounded stderr.

`wolong-config` now validates optional `output-limits` app env shaped as
gate -> stream -> positive byte limit, where streams are `stdout` and
`stderr`. Absence of the key preserves existing config behavior. `wolong-gate`
derives per-gate runner options from that policy.

## New Test Evidence

New focused suite:

```text
test/wolong_backpressure_SUITE.lfe: 7 tests passed
```

Cases covered:

- parser stdout artifact larger than 65536 bytes feeds grounder stdin and the
  public plan succeeds;
- grounder stdout artifact larger than 65536 bytes feeds engine stdin and the
  public plan succeeds;
- engine stdout solved plan larger than 65536 bytes returns public
  `#(ok Plan)` with `payload-bytes` matching the returned payload and artifact
  byte count;
- stdout over configured limit returns typed `engine artifact-truncated` and
  a later minimal dispatch succeeds with worker count back to zero;
- noisy stderr before final `PANDAPI_STATUS` truncates the diagnostic preview
  while preserving the final status line in bounded `stderr-tail`;
- missing final status after noisy stderr returns typed `engine missing-status`
  with `status-error=missing-status-line`;
- flood-then-timeout bounds stdout/stderr, records observed bytes and
  truncation flags, kills the erlexec process group, leaves no survivor, and
  recovers on a later minimal dispatch.

Existing runner CT coverage now asserts asymmetric limits directly:
stdout is capped at 25 bytes and stderr at 40 bytes for both no-stdin and
stdin runners, while `output-limit-bytes` remains the fallback-compatible
option.

Config EUnit now covers optional output policy validation:

```text
unit-wolong-config-tests: 13 tests, 0 failures
```

## Local Verification

Local gates passed after implementation commit `b34f6bc`:

```text
git diff --check: pass
rebar3 compile: pass
rebar3 as test eunit: pass, 13 tests, 0 failures
rebar3 as test ct: pass, all 87 tests passed
rebar3 xref: pass
rebar3 dialyzer: pass, exit 0 with no warnings in output
rebar3 lfe format --check: pass, all 13 files formatted
rebar3 as test lfe format --check: pass, all 23 files formatted
```

Focused Slice05 proof:

```bash
rebar3 as test ct --suite test/wolong_backpressure_SUITE.lfe
```

Observed:

```text
wolong_backpressure_SUITE: pass, all 7 tests passed
```

Focused local real-Chengdu compatibility proof:

```bash
WOLONG_CHENGDU_BIN_DIR=../chengdu/bin \
WOLONG_CHENGDU_FIXTURE_DIR=../chengdu/fixtures \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

Observed:

```text
wolong_real_chengdu_SUITE: pass, all 7 tests passed
```

This remains local compatibility proof against sibling binaries, not
clean-machine release-artifact proof. Arc04 still owns binary acquisition,
checksums, provenance, and release-artifact composition.

## Tamper Cycle

Tamper:

```text
changed wolong-gate:status-stderr/1 to return only the bounded stderr preview,
ignoring stderr-tail
```

Command:

```bash
rebar3 as test ct --suite test/wolong_backpressure_SUITE.lfe \
  --case noisy_stderr_preserves_final_status
```

Observed result:

```text
failed 1 test, passed 0 tests
noisy_stderr_preserves_final_status failed with engine missing-status
while stderr-tail contained the final PANDAPI_STATUS line
```

After restoring preview-or-tail classification, the same focused case passed
1/0.

## Remote CI

`main` was pushed after `b34f6bc`, triggering GitHub Actions build
`33187076539`:

```text
head: b34f6bc4bac596ccc1c08d71b34c47a52d53be37
url: https://github.com/billosys/wolong/actions/runs/33187076539
status: completed
conclusion: success
ubuntu-22.04: success
macos-15: success
```

Both CI jobs passed compile, EUnit, Common Test, xref, and Dialyzer. The run
remains fixture-backed for executable behavior unless Chengdu binaries are
provisioned in the CI environment; no sibling checkout dependency was added.

## Ledger Walk

- **BH-1 - done.** Work started from the active planning worktree; Slice04
  close and CDC verification were read. Full CT passed 87/0 and public API
  shapes remain `#(ok Plan)`, `#(unsolvable Detail)`, and typed
  `#(error #(Gate Reason Detail))`.
- **BH-2 - done.** Code and operator docs now distinguish stdout artifact
  integrity from bounded stderr diagnostics and final status preservation.
- **BH-3 - done.** Existing `output-limit-bytes` callers remain compatible;
  per-stream limits are optional.
- **BH-4 - done.** Runner CT proves independent stdout/stderr bounds for both
  `run/3` and `run-stdin/4`.
- **BH-5 - done.** Optional `output-limits` config is validated by EUnit for
  absent, valid, wrong-shape, non-positive, and unknown-stream cases.
- **BH-6 - done.** Gate runner options derive parser, grounder, and engine
  stream caps from validated app env.
- **BH-7 - done.** Large parser stdout over 65536 bytes feeds grounder stdin
  and public planning succeeds.
- **BH-8 - done.** Large grounder stdout over 65536 bytes feeds engine stdin
  and public planning succeeds.
- **BH-9 - done.** Large engine stdout over 65536 bytes returns public
  `#(ok Plan)` with matching payload and artifact byte counts.
- **BH-10 - done.** Over-limit stdout is typed `artifact-truncated` and no
  solved plan is returned.
- **BH-11 - done.** Noisy stderr can exceed the preview limit while final
  `PANDAPI_STATUS` is parsed from bounded tail.
- **BH-12 - done.** Missing final status returns typed `missing-status`;
  Wolong does not infer status from diagnostics or stdout.
- **BH-13 - done.** Flood-then-timeout returns typed timeout with bounded
  stdout/stderr and truncation metadata.
- **BH-14 - done.** Flood-then-timeout captures `os-pid`, waits boundedly for
  absence, and confirms the process group does not survive.
- **BH-15 - done.** Later minimal planning succeeds after over-limit and
  timeout failures; worker count returns to zero.
- **BH-16 - done.** Full CT passed all existing public solved, unsolvable,
  timeout, and typed error cases.
- **BH-17 - done.** Fixture-backed local CT is deterministic and no sibling
  Chengdu dependency was added to CI fixtures. Remote CI run `33187076539`
  for `b34f6bc` completed success on Ubuntu and macOS.
- **BH-18 - done.** Local real-Chengdu proof with explicit env paths passed
  7/0.
- **BH-19 - done.** Scope guard holds: no streaming/spooling architecture,
  parser `- -`, split parser workers, provisioning, public verifier,
  action/decomposition parser, diagnostic-prose classifier, or legacy fallback
  landed.
- **BH-20 - done.** Required local gates and formatter checks passed.
- **BH-21 - done.** Tamper cycle broke final-status preservation and the
  owning CT case failed, then passed after restore.
- **BH-22 - done.** This report walks all 22 rows and bubbles up below.

## Bubble-up to the Arc

Slice05 resolves Arc03 OQ4 for the in-memory artifact model at the tested
stress envelope. The stdio path now has explicit stdout/stderr capture policy,
larger artifact success cases, typed stdout truncation, noisy-stderr final
status preservation, bounded flood timeout behavior, process-group cleanup,
and post-failure recovery.

No evidence in Slice05 requires an additional streaming/spooling remediation
slice before Arc03 close. Arc03 is ready for CDC verification and, if accepted,
arc-level closure. Arc04 remains the next release-readiness arc for
clean-machine Chengdu binary provisioning, checksum/provenance validation, and
Hex publication readiness.

## Bubble-up to the Project

Slice05 strengthens:

- **W1:** public `wolong:plan/2,3` now carries large engine stdout payloads
  over the old 65536-byte cap when configured.
- **W2:** flood-then-timeout with active stdout/stderr proves bounded output,
  typed timeout, process-group cleanup, and no survivor.
- **W3:** final status classification remains machine-field based even when
  diagnostics exceed the returned stderr preview.
- **W4:** failure recovery is proven after truncation and timeout; one-shot
  dispatch workers return to zero.

Remaining project release work is unchanged: Arc04 must provide released
Chengdu binary acquisition, checksum/provenance verification, and clean-machine
consumer proof before W5/Hex release readiness can close.
