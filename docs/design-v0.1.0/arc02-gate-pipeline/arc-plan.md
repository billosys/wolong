# wolong arc02 - gate-pipeline - arc plan

> Plan-of-record for arc02, per `PROJECT-MANAGEMENT.md` v2.1. Parent:
> [`../project-plan.md`](../project-plan.md). Opened 2026-08-14.

## 1. Capability statement

Roadmap line: *The supervised pandaPI gate pipeline exposes the public
planning API without allowing an unverified solved plan or a valid no-plan
outcome to collapse into generic failure.*

Expanded: this arc builds on arc01's process substrate and turns the current
Chengdu 0.3.0 managed-process surface into Wolong's planning boundary. The
supported external process chain for this arc is the current documented
`pandapi-*` sequence:

```text
pandapi-parser -> pandapi-grounder -> pandapi-engine
```

Each process is invoked through `wolong-exec:run/3` with supervised argv,
file-backed artifacts, bounded output, timeout cleanup, and classification
from numeric exit code plus the final `PANDAPI_STATUS` record. A solved engine
run becomes a success-shaped planning result. Engine `domain_no_plan` with
exit `2` becomes `#(unsolvable ...)`, not `#(error ...)`. Parser, grounder,
engine, binary, output, timeout, and unmapped-status failures return typed
errors naming the gate.

This arc also reconciles an inherited project-plan tension. Older Wolong
planning prose described a five-gate parse/ground/solve/convert/verify flow,
but the current Chengdu 0.3.0 CLI reference and managed-process docs expose
three supported normal external commands: parser, grounder, and engine.
Arc02 must therefore make the verification boundary explicit before adding
public API: either a supported verification surface is discovered and planned,
or the project plan is updated to keep `wolong:verify` out of the 0.1.0
implemented surface with a typed/ledgered re-entry condition. The invariant
does not change: Wolong must never return a confident solved plan while
silently skipping a required verification step.

## 2. Slice breakdown

| Slice | Slug | Scope (one line) | Load-bearing for |
|-------|------|------------------|------------------|
| slice01 | `gate-contract-substrate` | Promote arc01's parser-only contract pieces into shared gate machinery: locate parser/grounder/engine, parse `PANDAPI_STATUS` once, map current managed statuses per gate, and prove a one-shot supervised parse-ground-solve fixture without public `plan` yet. | all arc02 slices |
| slice02 | `pipeline-workspace` | Add the internal pipeline workspace: per-dispatch scratch dir, artifact naming, cleanup/keep policy, and sequential parse -> ground -> solve orchestration over the shared gate substrate. | slice03, slice04 |
| slice03 | `plan-api` | Add public `(wolong:plan domain problem opts)` returning solved plan metadata or `#(unsolvable ...)`, with typed gate errors and no diagnostic-prose classification. | project W1, W3 |
| slice04 | `dispatch-supervision` | Run each planning dispatch under OTP supervision with timeout/no-zombie behavior at engine scale and concurrent dispatch isolation. | project W2, W4 |
| slice05 | `verification-boundary` | Resolve the public verification surface: implement `wolong:verify` only if a supported Chengdu verifier contract exists, otherwise update the project plan and README to keep verification explicitly deferred rather than implied. | project DoD honesty, arc close |

Sizing judgment: five slices. slice01 is intentionally a substrate slice,
because duplicating status parsing and binary lookup inside later pipeline
code would make every gate mapping harder to verify. slice02 keeps workspace
lifecycle separate from public API semantics. slice03 and slice04 split API
classification from supervision/concurrency because each has different
failure modes. slice05 is a required reconciliation slice because the current
Chengdu docs do not expose the older five-gate verifier as a supported
managed-process binary.

## 3. Dependencies

**Consumes from arc01:**

- `wolong-exec:run/3` typed runner with argv execution, timeout cleanup,
  output caps, and recovery after failure.
- `wolong-config:validate/0` and app-env-only binary/config lookup.
- `wolong-binaries:resolve/1`, now parser/grounder/engine-proven by slice01.
- `wolong:validate/2`, parser-only public validation.
- Parser fixture corpus and CT pattern for supervised-process integration.

**Consumes from Chengdu:**

- Current sibling checkout binaries until release provisioning exists:
  `../chengdu/bin/pandapi-parser`, `../chengdu/bin/pandapi-grounder`, and
  `../chengdu/bin/pandapi-engine`.
- Current CLI and process contracts:
  `../chengdu/docs/reference/cli.md`,
  `../chengdu/docs/managed-process.md`, and the fixture contract records under
  `../chengdu/fixtures/contract/`.
- Current fixture families:
  `../chengdu/fixtures/minimal`, `../chengdu/fixtures/unsolvable`,
  `../chengdu/fixtures/grounder`, and `../chengdu/fixtures/engine` as sources
  to vendor or model Wolong-owned tests. Remote CI must not depend on the
  sibling checkout.

**Leaves for arc03:**

- No binary download or release provisioning. Arc03 still owns fetching,
  checksums, release artifact layout, and clean-machine installation.
- No dependency on unreleased Chengdu artifacts in CI. Arc02 may use checked-in
  fixture executables when CI cannot run real Chengdu binaries, but must keep
  real-binary evidence separate and honest.

## 4. Open questions

- **OQ1 (slice01/slice05): verification boundary.** Current Chengdu 0.3.0
  managed docs expose parser, grounder, and engine, but no separate supported
  verifier binary. Decide before public verification API lands: implement a
  supported verifier if one exists, or update project docs to defer
  `wolong:verify` with a concrete re-entry condition. Do not add a public
  function that pretends verification happened.
- **OQ2 (slice01): RESOLVED — shared parser plus gate mapper.** Arc01's
  `PANDAPI_STATUS` parser was extracted from `src/wolong.lfe` into
  `src/wolong-status.lfe`, and shared gate invocation/classification landed in
  `src/wolong-gate.lfe`. The result avoids three parser copies and keeps
  `wolong:validate/2` as a compatibility adapter over the shared substrate.
  *(Was: open. Resolved 2026-08-14 by slice01 — see Version History.)*
- **OQ3 (slice01): RESOLVED — strict fixtures plus local real-binary survey.**
  Remote CI uses checked-in parser/grounder/engine fixture executables that
  prove Wolong's supervised argv shape, artifact handling, stdout ownership,
  status parsing, and engine no-plan mapping. Real Chengdu binary behavior is
  surveyed locally and recorded separately; CI does not claim to run sibling
  Chengdu binaries. *(Was: open. Resolved 2026-08-14 by slice01 — see Version
  History.)*
- **OQ4 (slice02): stream-to-file capture.** Arc01 bounded stdout/stderr in
  memory. Engine output can be larger. Decide whether the runner needs a
  stream-to-file option now, or whether file-backed artifacts plus capped
  diagnostics are sufficient for 0.1.0.
- **OQ5 (slice03): solved-plan representation.** Decide the first public plan
  term shape: action sequence, artifact metadata, decomposition/provenance
  fields, and what remains a deferred converter/bridge concern.

## 5. Arc ledger

| Row | Criterion | Target strength |
|-----|-----------|-----------------|
| A1 | All planned slice open/close sets exist and slice01-slice05 close without silent drops; every slice bubble-up is dispositioned in this arc plan before the next slice plans against it. | attested by child ledgers |
| A2 | The current supported supervised parse -> ground -> solve chain runs end to end through Wolong code with configured `pandapi-*` binaries or honest CI fixtures, producing parser, grounder, and engine artifacts for the minimal fixture. | reproduced |
| A3 | A valid no-plan fixture reaches engine search and returns `#(unsolvable Detail)` from `domain_no_plan`/exit `2`, never `#(error ...)`, never a missing artifact failure, and never a diagnostic-prose scrape. | reproduced |
| A4 | Parser, grounder, and engine failures map to typed gate errors from exit/status fields: missing input, output unavailable, invalid input, timeout, missing/non-executable binary, missing status, and unmapped status. | reproduced via test suite |
| A5 | Engine-scale timeout cleanup leaves no surviving OS process and the application can recover for a subsequent dispatch. | reproduced |
| A6 | Concurrent dispatches are isolated under OTP supervision: one failing or timing-out dispatch does not take down the app or corrupt another dispatch's artifacts/results. | reproduced |
| A7 | The public API surface at arc close is honest: `wolong:validate` remains parser validation, `wolong:plan` returns solved/unsolvable/typed gate errors, and `wolong:verify` is either implemented against a supported contract or explicitly deferred with project-plan/README wording that prevents false confidence. | attested by review; reproduced for callable APIs |
| A8 | Local gates and remote CI are green: `rebar3 compile`, `rebar3 as test eunit`, `rebar3 as test ct`, `rebar3 xref`, and `rebar3 dialyzer`; any unavailable real Chengdu binary evidence is recorded as a deferral owned by arc03. | reproduced |

## 6. Version history

- **v1.1 - 2026-08-14 (surfaced by slice01).** OQ2 and OQ3 resolved.
  `wolong-status` now owns final `PANDAPI_STATUS` parsing, and `wolong-gate`
  owns shared supervised argv construction, gate execution, artifact metadata,
  and managed-status mapping. `wolong-binaries` now exposes parser, grounder,
  and engine lookup over the existing app-env-only policy. CI uses strict
  checked-in fixture executables for Wolong-side process-contract behavior,
  while local CDC evidence records real `../chengdu/bin/pandapi-*` behavior:
  minimal parser/grounder/engine exits `0/0/0`, and unsolvable exits `0/0/2`
  with engine `status=domain_no_plan`, `outcome=no_plan`, and no plan
  artifact. A residual hardening note remains for later slices: the mapper
  classifies from OS exit status plus `status` and preserves status-line
  `exit_code`; it does not yet reject a contradictory status-line
  `exit_code`.
- **v1.0 - 2026-08-14.** Initial arc02 plan, opened after arc01 close. Sources:
  arc01 closing report, project plan v1.1, Chengdu `docs/reference/cli.md`,
  Chengdu `docs/managed-process.md`, and Chengdu fixture contract records for
  parser/grounder/engine/pipeline managed-process behavior.
