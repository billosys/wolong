# wolong arc03 - stdio-pipeline - arc plan

> Plan-of-record for arc03, per `PROJECT-MANAGEMENT.md` v2.1. Parent:
> [`../project-plan.md`](../project-plan.md). Opened 2026-08-20.

## 1. Capability statement

Roadmap line: *Wolong proves and implements the release-critical
stdin/stdout/stderr Chengdu 0.3.0 pipeline under erlexec, pausing Wolong if
Chengdu lacks a clean supported contract.*

Expanded: Arc02 proved the typed planning API, dispatch supervision, status
mapping, no-plan semantics, and timeout/no-zombie behavior over a
file-backed/fixture-backed process shape. That is useful substrate, but it is
not the release gate. Wolong 0.1.0 cannot release until it drives the real
Chengdu 0.3.0 `pandapi-*` binaries through their supported CLI-citizen
stdio behavior.

The target shape is a supervised process chain where:

```text
pandapi-parser -> pandapi-grounder -> pandapi-engine
```

is executed through erlexec without shell command strings; each component has
a documented stdin/stdout/stderr ownership contract; machine status remains
parseable from the selected status stream; stdout artifacts and stderr
diagnostics cannot deadlock Wolong; timeouts kill the full OS process group;
and public `wolong:plan/2,3` still returns solved, unsolvable, or typed gate
errors with the verification boundary explicit.

Slice01 was investigation-first and originally paused the arc on a Chengdu
input-stdin blocker. Current Chengdu `release/0.3.x` evidence at `e55ef5fd`
moved that blocker, Slice02 added Wolong runner support for stdin bytes plus
EOF, Slice03 wired Wolong's internal parser -> grounder -> engine pipeline
through the supported stdio artifact path, and Slice04 now proves that same
path at Wolong's public API boundary with real local Chengdu binaries. Slice05
is open to harden the remaining stdout/stderr backpressure, truncation, final
status preservation, and timeout-cleanup risks before Arc03 close.

## 2. Slice breakdown

| Slice | Slug | Scope (one line) | Load-bearing for |
|-------|------|------------------|------------------|
| slice01 | `stdio-contract-investigation` | Survey and probe the current Chengdu docs/binaries plus erlexec/LFE mechanics for stdin/stdout/stderr pipeline feasibility; classify the result as proceed, Wolong-design-needed, or Chengdu-blocked. | all arc03 slices |
| slice02 | `stdio-runner` | Extend or add a Wolong-owned erlexec runner surface for stdin bytes plus EOF while preserving separated stdout/stderr capture, typed results, output caps, timeout cleanup, and shell-free argv execution. | slice03, slice04 |
| slice03 | `stdio-gate-pipeline` | Rework the internal gate pipeline so parser artifact stdout feeds grounder stdin and grounder artifact stdout feeds engine stdin, while parser still receives the supported two-input planning instance and typed status/exit classification remains intact. | slice04 |
| slice04 | `real-binary-public-plan` | Prove public `wolong:plan/2,3` and parser-only `wolong:validate/2` against real local Chengdu 0.3.0 binaries through the stdio path, with CI-safe fixtures that model the same contract honestly. | project W1-W4; arc04 |
| slice05 | `backpressure-timeout-hardening` | Add focused stress and failure coverage for large stdout artifacts, noisy stderr diagnostics, final status preservation, partial output, TERM-resistant children, and recovery after failed stdio dispatches. | release confidence; arc03 close |

Sizing judgment: Slice01 already changed the arc once by pausing on Chengdu,
and the 2026-08-26 re-entry evidence now resumes the arc at Slice02. Slice05
is kept separate because the earlier slices proved fixture-scale and
public-boundary behavior, but not larger-output or noisy-stderr stress. If
Slice05 shows the current in-memory artifact model is insufficient, the close
should bubble up a remediation slice or design decision rather than hide a
streaming/spooling redesign inside this slice.

## 3. Dependencies

**Consumes from Arc02:**

- `wolong-exec:run/3` supervised argv runner with timeout cleanup, separated
  stdout/stderr capture, and typed result shapes.
- `wolong-gate` status parsing/classification from exit status plus final
  `PANDAPI_STATUS`.
- `wolong-pipeline` workspace/artifact lifecycle and public plan adaptation.
- `wolong-dispatch` one-shot supervised workers and isolation tests.
- `verification-boundary.separate-verifier=not-run` metadata and explicit
  verifier/action/decomposition deferrals.

**Consumes from Chengdu:**

- Current sibling checkout binaries:
  `../chengdu/bin/pandapi-parser`, `../chengdu/bin/pandapi-grounder`, and
  `../chengdu/bin/pandapi-engine`.
- Current process docs:
  `../chengdu/docs/reference/cli.md` and
  `../chengdu/docs/managed-process.md`.
- Current fixture families and any contract records under `../chengdu/fixtures/`.

**Leaves for Arc04:**

- No release download/checksum/provenance implementation.
- No Hex/package publication.
- No clean-machine binary acquisition. Arc04 may consume local release artifacts
  only after Arc03 proves the stdio behavior those artifacts must expose.

## 4. Open questions

- **OQ1 - re-resolved by Chengdu re-entry evidence:** Current Chengdu
  `release/0.3.x` at `e55ef5fd` supports the required artifact stdio path.
  Local `make test-contract-stdio-managed` passed 187/0 on 2026-08-26:
  parser one-input stdin works for `domain -` and `problem -`; parser `- -`
  remains a documented `cli_usage_error`; grounder reads artifact stdin and
  emits artifact stdout; engine reads artifact stdin and emits solved plan
  stdout or no-plan `status=domain_no_plan`/exit `2`.
- **OQ2 - resolved by slice01:** Artifact stdout is clean on supervised
  success paths when `--status=stderr` is selected. Chengdu also rejects
  `--status=stdout` with `--output -` as a usage error instead of mixing status
  with artifact stdout.
- **OQ3 - resolved by slice02:** erlexec exposes the necessary mechanics, and
  Wolong now has `wolong-exec:run-stdin/4` for argv-list execution with stdin
  bytes, EOF delivery, separated stdout/stderr capture, output caps, nonzero
  completed exits, timeout cleanup, and recovery. `wolong-exec:run/3` remains
  the no-stdin compatibility API.
- **OQ4 - active in Slice05:** Slice02 proves bounded capture and concurrent
  stdout/stderr draining for fixture-scale stdin runs. Slice03 additionally
  rejects truncated stdout artifacts as typed `artifact-truncated` gate
  errors. Slice05 now owns larger artifact/backpressure stress, noisy stderr
  before final status, and timeout cleanup while pipes are active.
- **OQ5 - resolved by slice01:** CI should continue using strict
  Wolong-owned fixtures. Real Chengdu binary probes remain optional local
  evidence until release artifacts are available to CI; remote CI must not
  depend on a sibling `../chengdu` checkout.
- **OQ6 - resolved by 2026-08-26 re-entry:** Chengdu now documents and proves
  the supported artifact stdio contract. The parser role semantics are
  intentionally narrower than the original hope: exactly one parser HDDL input
  may be `-`; both inputs as `- -` are unsupported. Arc03 can resume without a
  Wolong rescope, but Slice03 must encode that caveat explicitly.

## 5. Arc ledger

| Row | Criterion | Target strength |
|-----|-----------|-----------------|
| A1 | Slice01 classifies the stdio contract as proceed, Wolong-design-needed, or Chengdu-blocked from real docs/binary probes and erlexec/LFE evidence. | reproduced |
| A2 | Wolong has a supervised erlexec stdio runner that writes stdin, captures stdout artifacts and stderr status/diagnostics separately, enforces output bounds/backpressure policy, and kills timed-out process groups. | reproduced |
| A3 | Parser -> grounder -> engine runs end to end through the stdio path with real local Chengdu binaries where available and CI-safe fixtures otherwise, producing solved plan payload and provenance. | reproduced |
| A4 | Valid no-plan through the stdio path returns public `#(unsolvable Detail)` from engine `domain_no_plan`/exit `2`, never generic error and never diagnostic-prose classification. | reproduced |
| A5 | Parser, grounder, engine, binary, stdin/stdout/stderr, timeout, status, and unmapped failures remain typed and gate-named. | reproduced via test suite |
| A6 | Timeout and backpressure stress leave no surviving OS process and later dispatches recover normally. | reproduced |
| A7 | Public API and docs no longer imply file-backed artifacts are the release-grade process contract; file-backed behavior is documented as Arc02 substrate or fallback only where explicitly supported. | attested by review; reproduced for callable APIs |
| A8 | Local gates and remote CI are green: `rebar3 compile`, `rebar3 as test eunit`, `rebar3 as test ct`, `rebar3 xref`, `rebar3 dialyzer`, and formatter checks required by current `AGENTS.md`. | reproduced |

## 6. Version history

- **v1.8 - 2026-08-28 (surfaced by slice05 opening).** Slice05 is opened as
  the remaining Arc03 hardening slice. It targets larger stdout artifacts,
  noisy stderr before final `PANDAPI_STATUS`, independently bounded
  artifact/diagnostic streams, typed stdout truncation, flood-then-timeout
  cleanup, and recovery after failed stdio dispatches. The scope explicitly
  excludes a streaming/spooling architecture, parser `- -`, split parser
  workers, release provisioning, and public API redesign; if stress evidence
  shows those are required, Slice05 must bubble up a remediation decision
  rather than smuggle it into the implementation.
- **v1.7 - 2026-08-27 (surfaced by slice04 close).** Slice04 adds
  `test/wolong_real_chengdu_SUITE.lfe`, a focused Common Test proof that
  public `wolong:plan/3`, `wolong:plan/2`, and parser-only
  `wolong:validate/2` drive the real sibling Chengdu `pandapi-*` binaries on
  `release/0.3.x` / `e55ef5fd`. Minimal solved returns a durable non-empty
  public payload, unsolvable returns `#(unsolvable Detail)` from engine
  `domain_no_plan`/exit `2`, parser broken syntax maps to typed
  `invalid-hddl`, and returned provenance proves parser artifact stdout plus
  grounder/engine stdin. Remote CI remains fixture-backed and the real-binary
  suite skips when Chengdu binaries are absent. Slice05 remains reserved for
  release-scale stdout/stderr and backpressure stress before Arc03 close.
- **v1.6 - 2026-08-27 (surfaced by slice04 opening).** Slice04 is opened as
  the real-binary public-plan proof. The scope is repeatable local evidence
  that public `wolong:plan/2`, `wolong:plan/3`, and parser-only
  `wolong:validate/2` drive real current Chengdu 0.3.0 binaries through the
  stdio artifact path. Remote CI remains fixture-backed unless release
  artifacts are explicitly provisioned later. Arc04 still owns clean-machine
  binary acquisition, checksums, and release provenance.
- **v1.5 - 2026-08-26 (surfaced by slice03 close).** Slice03 lands the
  Wolong-owned stdio gate pipeline: parser runs with domain/problem paths and
  `--output -`; parser stdout feeds grounder stdin; grounder stdout feeds
  engine stdin; engine stdout becomes the durable public plan payload before
  workspace cleanup. Engine `domain_no_plan`/exit `2` with empty stdout remains
  public `#(unsolvable Detail)`. Parser `- -`, split parser workers, framed
  stdin, and artifact merge protocols remain deferred. Slice04 can now focus
  on real-binary public-plan proof; Slice05 remains reserved for release-scale
  backpressure hardening.
- **v1.4 - 2026-08-26 (surfaced by slice03 opening).** Slice03 is opened with
  the agreed parser boundary clarified: the common release case is domain and
  problem paths into one parser invocation, parser artifact stdout into
  grounder stdin, and grounder artifact stdout into engine stdin. Parser
  exactly-one-stdin support remains acknowledged but not required for the first
  pipeline implementation; parser `- -`, split domain/problem parser workers,
  framed stdin, and domain/problem artifact merging are deferred until a real
  upstream producer use case or Chengdu contract exists.
- **v1.3 - 2026-08-26 (surfaced by slice02).** Slice02 lands
  `wolong-exec:run-stdin/4` as the explicit stdin-capable runner API while
  preserving `run/3` compatibility. Common Test covers EOF-sensitive stdin,
  empty stdin, invalid stdin shape, literal argv with shell metacharacters,
  stream separation, independent caps, nonzero completed exit, TERM-resistant
  timeout cleanup, and recovery. Slice03 may now wire gate artifacts through
  the supported Chengdu stdio shape, while preserving the parser caveat that
  `pandapi-parser - -` is unsupported.
- **v1.2 - 2026-08-26 (surfaced by Chengdu re-entry evidence).** Arc03 resumes
  after current Chengdu `release/0.3.x` at `e55ef5fd` proves the supported
  artifact stdio contract. Local `make test-contract-stdio-managed` passes
  187/0, including parser one-input stdin, grounder stdin, engine stdin,
  solved pipeline, and no-plan pipeline. Parser `- -` remains unsupported and
  must not be assumed by Wolong. The active Slice02 blocker is now Wolong's
  runner: add stdin bytes plus EOF under erlexec while preserving separated
  captures, typed results, output caps, timeout cleanup, and argv-list
  execution.
- **v1.1 - 2026-08-20 (surfaced by slice01).** Slice01 classifies Arc03 as
  **Chengdu-blocked** for the release-critical stdin pipeline: current Chengdu
  docs and binaries support artifact stdout with status on stderr, but do not
  support `-` as an input path for parser, grounder, or engine. Arc03 pauses
  before stdio-runner implementation. Re-entry requires a supported Chengdu
  input-stdin contract for all three components, or an explicit Wolong project
  rescope to file inputs plus stdout-artifact temporary-file bridging.
- **v1.0 - 2026-08-20.** Initial Arc03 plan. Surfaced by Arc02 close readiness
  review: Arc02's file-backed/fixture-backed pipeline is valuable substrate but
  is not sufficient for Wolong release readiness. Arc03 is inserted before
  provisioning to prove and implement the Chengdu 0.3.0 stdio process contract
  or pause Wolong with a precise Chengdu blocker.
