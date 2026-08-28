# Slice 05 (wolong arc03): backpressure-timeout-hardening

> Open-set plan-of-record for `slice05-backpressure-timeout-hardening`, per
> `PROJECT-MANAGEMENT.md` v2.4 and the Wolong-local `slice-doc.md`
> convention. Parent: `../arc-plan.md`. Opened 2026-08-28.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Harden the release-critical stdio pipeline against the failure modes that only
show up once stdout and stderr stop being tiny:

```text
parser stdout artifact -> grounder stdin
grounder stdout artifact -> engine stdin
engine stdout artifact -> public plan payload
stderr diagnostics + final PANDAPI_STATUS -> typed classification
```

Slice02 proved stdin bytes plus EOF at the runner boundary. Slice03 wired the
internal gate pipeline through stdout/stdin artifacts. Slice04 proved the
public API with real local Chengdu binaries at fixture scale. Slice05 is the
stress and policy slice: Wolong must drain both streams, keep bounded
diagnostic/artifact data, preserve the final machine status needed for typed
classification, kill timed-out process groups even while pipes are active, and
recover afterward.

## 2. Context

The current implementation uses `wolong-exec:run/3` and
`wolong-exec:run-stdin/4` with an `output-limit-bytes` option. The gate layer
currently applies a fixed 65536-byte limit to both stdout and stderr. That is
good enough to prove bounded capture and truncation behavior, but it is not a
complete release policy:

- stdout is a data-artifact channel for the stdio pipeline;
- stderr is a diagnostic/status channel, and Chengdu writes the final
  `PANDAPI_STATUS` line after artifact disposition;
- a long stderr diagnostic stream before the final status must not erase the
  only machine-readable status Wolong needs to classify the result;
- a valid stdout artifact larger than the configured artifact limit must fail
  honestly as a typed truncation/resource outcome, never as a partial plan;
- a child that floods streams and then hangs must still be killed as a process
  group and must not poison later dispatches.

This slice may extend the runner/gate configuration surface if needed. Keep it
small and compatibility-preserving: existing callers and existing
`config/sys.config` should continue to work without adding a new required key.

## 3. In Scope

- Add a documented output-capture policy for stdio gates.
- Preserve compatibility for existing `wolong-exec:run/3` and
  `wolong-exec:run-stdin/4` callers that pass `output-limit-bytes`.
- Add independent stdout/stderr capture limits, or an equivalent documented
  policy, so artifact and diagnostic streams do not have to share one hard
  constant.
- Make the gate layer consume a configurable, app-env-backed output policy
  while preserving existing configs when the new key is absent.
- Preserve final `PANDAPI_STATUS` classification even when stderr diagnostics
  exceed the diagnostic preview limit.
- Keep stdout artifact truncation typed and honest: if parser, grounder, or
  solved-engine artifact stdout is truncated, no partial artifact or plan may
  cross the API.
- Add fixture-backed Common Test coverage for large parser, grounder, and
  engine stdout artifacts within the configured limit.
- Add fixture-backed Common Test coverage for stdout artifacts over the
  configured limit, proving typed `artifact-truncated` behavior and no partial
  solved plan.
- Add fixture-backed Common Test coverage for noisy stderr before the final
  status line, proving status classification remains machine-field based.
- Add fixture-backed Common Test coverage for flood-then-timeout behavior:
  partial output remains bounded, the OS process group is killed, no survivor
  remains, worker cleanup completes, and later dispatches recover.
- Keep local real-Chengdu proof optional. If sibling Chengdu has a useful
  larger fixture or command, record it; otherwise state that release-scale
  stress remains fixture-backed until Chengdu publishes larger contract
  fixtures or release artifacts.
- Refresh operator-facing docs if the output policy, README status, or
  `config/sys.config` comments are stale.

## 4. Out of Scope

- No streaming architecture, disk-spooling runner, bounded queue API, planner
  pool, or distributed Erlang.
- No public API redesign and no public `plan/3` output-limit option unless a
  very small compatibility-preserving option falls out naturally.
- No parser `- -` workaround, split domain/problem parser workers, or framed
  parser stdin protocol.
- No release downloader, checksum verifier, provenance manifest consumer, or
  Hex publication.
- No clean-machine release-artifact claim.
- No diagnostic-prose classifier.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No public `wolong:verify`, action-sequence parser, or decomposition-tree
  parser.

If hardening shows the current in-memory artifact model is not adequate for
release-scale outputs, stop and report the finding. Do not quietly introduce a
larger streaming/spooling architecture inside this slice.

## 5. Design Constraints

The status channel is not just "stderr as text." The classification contract
is final `PANDAPI_STATUS` fields plus exit code. Wolong may keep only a bounded
diagnostic preview for stderr, but it must still retain enough machine-status
information to classify a completed process when Chengdu emits diagnostics
before the final status line.

Stdout artifacts have a different policy. Parser and grounder stdout artifacts
are handoff bytes for the next process. Engine stdout is the public plan
payload. If any required stdout artifact is truncated, the result is not a
valid artifact; the public API must return a typed error naming the gate and
reason.

Timeout behavior must remain process-group behavior through erlexec. A child
that resists TERM while stdout/stderr are active must still be escalated and
must leave no surviving OS process.

Common Test is the right tool for this slice. Keep system/process tests in
`test/`; keep ltest/EUnit for unit-level config parsing only where appropriate.
Do not rely on fixed sleeps for synchronization when a process signal, monitor,
file marker, or bounded poll can prove the condition.

## 6. Recommended Implementation Shape

Prefer a small extension to the existing runner options:

```text
output-limit-bytes      compatibility default for both streams
stdout-limit-bytes      optional stdout override
stderr-limit-bytes      optional stderr override
```

Then let the gate layer derive those options from an optional app env setting
such as:

```erlang
{output_limits, #{
    parser => #{stdout => 1048576, stderr => 65536},
    grounder => #{stdout => 1048576, stderr => 65536},
    engine => #{stdout => 1048576, stderr => 65536}
}}
```

The exact LFE atom spelling should follow local style and existing config
conventions; do not break existing configs by making this key required.

For stderr status preservation, prefer a bounded design such as:

- keep a bounded diagnostic preview for returned `stderr`;
- track enough stderr tail or extracted `PANDAPI_STATUS` line to classify the
  final status after noisy diagnostics;
- expose truncation metadata so callers can see that diagnostics were capped.

Do not keep unbounded stderr in memory just to find the final status line.

## 7. Verification Approach

Use Common Test fixtures under the existing `test` tree. It is fine to extend
`test/fixtures/gate-contract-substrate/pandapi-*-fixture.sh` or add nearby
fixture cases when that keeps the proof aligned with the existing suite.

Minimum fixture scenarios:

- parser emits a large stdout artifact within the configured stdout limit;
- grounder emits a large stdout artifact within the configured stdout limit;
- engine emits a large solved plan within the configured stdout limit;
- engine or a gate emits stdout over the configured limit and returns a typed
  truncation/error rather than a partial solved result;
- a gate emits noisy stderr before the final `PANDAPI_STATUS`, exceeding the
  diagnostic preview limit, while Wolong still parses the final status fields;
- a gate floods stdout/stderr and then hangs or resists TERM; Wolong times out,
  kills the process group, bounds returned output, and a later minimal plan
  succeeds;
- if a completed process has no recoverable final status because status itself
  is unavailable/truncated beyond the policy, Wolong returns a typed
  status/error result rather than guessing from diagnostics.

Run and record:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
rebar3 as test lfe format --check
```

Also run a focused CT command for the new hardening suite or cases, and run
the existing real-Chengdu public proof when sibling binaries are available:

```bash
WOLONG_CHENGDU_BIN_DIR=../chengdu/bin \
WOLONG_CHENGDU_FIXTURE_DIR=../chengdu/fixtures \
rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe
```

The real-Chengdu run is compatibility proof, not release-scale stress proof,
unless Chengdu supplies explicit large-output fixtures.

Perform one tamper cycle. Good choices include:

- stop preserving the final status line when stderr diagnostics are truncated;
- treat truncated stdout artifacts as usable;
- share one small output cap for artifact stdout and stderr diagnostics;
- bypass process-group kill on a flood-then-timeout fixture.

Show the owning CT case fails, revert the tamper, and show it passes.

## 8. Exit Criteria

- Output-capture policy is explicit in code and docs.
- Existing `wolong-exec` callers using `output-limit-bytes` continue to work.
- Stdout and stderr can be bounded independently, or the implemented policy
  gives an equally explicit reason why one shared bound remains correct.
- Optional app-env output policy is validated when present and absent configs
  preserve existing behavior.
- Large parser, grounder, and engine stdout artifacts within the configured
  limit flow through the stdio pipeline successfully.
- Stdout artifact truncation is a typed gate error; no partial artifact or
  partial solved plan crosses `wolong:plan/2,3`.
- Noisy stderr that exceeds the diagnostic preview limit still allows final
  status classification from machine fields.
- Missing/unrecoverable final status remains a typed error, not a diagnostic
  prose guess.
- Flood-then-timeout children are killed as process groups, leave no survivor,
  and later dispatches recover.
- Public solved, unsolvable, timeout, and typed gate-error shapes remain
  compatible with previous slices.
- Fixture-backed CI remains deterministic and does not require sibling
  Chengdu binaries.
- Local real-Chengdu public proof still passes when sibling binaries are
  available, or records an availability skip without claiming proof.
- Scope guard holds.
- `closing-report.md` walks every ledger row and bubbles up whether Arc03 can
  close or needs another remediation slice.
