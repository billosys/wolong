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

Slice01 is investigation-first. If the live Chengdu docs/binaries do not
support the needed stdio contract, or if a bug prevents safe supervised use,
Wolong pauses and the finding is routed to Chengdu instead of building a
Wolong workaround around a broken process boundary.

## 2. Slice breakdown

| Slice | Slug | Scope (one line) | Load-bearing for |
|-------|------|------------------|------------------|
| slice01 | `stdio-contract-investigation` | Survey and probe the current Chengdu docs/binaries plus erlexec/LFE mechanics for stdin/stdout/stderr pipeline feasibility; classify the result as proceed, Wolong-design-needed, or Chengdu-blocked. | all arc03 slices |
| slice02 | `stdio-runner` | Extend or add a Wolong-owned erlexec runner surface for stdin input, stdout artifact capture/streaming, stderr status capture, timeout cleanup, and backpressure-safe process termination. | slice03, slice04 |
| slice03 | `stdio-gate-pipeline` | Rework the internal gate pipeline to pass parser and grounder artifacts through the supported stdio contract while preserving typed status/exit classification and workspace hygiene. | slice04 |
| slice04 | `real-binary-public-plan` | Prove public `wolong:plan/2,3` and parser-only `wolong:validate/2` against real local Chengdu 0.3.0 binaries through the stdio path, with CI-safe fixtures that model the same contract honestly. | project W1-W4; arc04 |
| slice05 | `backpressure-timeout-hardening` | Add focused stress and failure coverage for large stdout artifacts, stderr diagnostics, partial output, TERM-resistant children, and recovery after failed stdio dispatches if Slice01/02 show this needs its own slice. | release confidence |

Sizing judgment: Slice01 may change the later slice count. If it finds a
Chengdu blocker, this arc pauses before implementation. If erlexec/LFE stdio
mechanics are simpler than expected, Slice05 may collapse into Slice02/03. If
streaming/backpressure is subtle, keep Slice05 separate so the runner and
pipeline slices stay reviewable.

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

- **OQ1 - resolved by slice01:** Current Chengdu 0.3.0 local binaries accept
  filesystem input paths only. `--output -` is supported for artifact stdout,
  but input path `-` is rejected as `cli_usage_error` for parser domain input,
  parser problem input, parser both-input attempts, grounder input, and engine
  input.
- **OQ2 - resolved by slice01:** Artifact stdout is clean on supervised
  success paths when `--status=stderr` is selected. Chengdu also rejects
  `--status=stdout` with `--output -` as a usage error instead of mixing status
  with artifact stdout.
- **OQ3 - resolved by slice01:** erlexec exposes the necessary mechanics:
  `stdin`/`{stdin, ...}` command options, `exec:send/2` for binary stdin data,
  `exec:send(PidOrOsPid, eof)` to close stdin, and separate stdout/stderr
  message delivery when pty mode is not used. Wolong's current runner does not
  expose stdin yet, but the substrate is technically available.
- **OQ4 - open for any resumed implementation:** Current real fixture artifacts
  are small enough for investigation, but a resumed stdio runner still needs an
  explicit bounded-memory versus stream-to-file policy and concurrent draining
  of stdout/stderr.
- **OQ5 - resolved by slice01:** CI should continue using strict
  Wolong-owned fixtures. Real Chengdu binary probes remain optional local
  evidence until release artifacts are available to CI; remote CI must not
  depend on a sibling `../chengdu` checkout.
- **OQ6 - resolved by slice01:** Wolong re-entry requires Chengdu to document
  and implement input stdin for the supported parser, grounder, and engine
  surfaces, including unambiguous parser role semantics for two HDDL inputs, or
  the project must explicitly rescope Arc03 to a file-input plus stdout-artifact
  temporary-file bridge. Chengdu-facing handoff:
  `chengdu-stdin-contract-blocker.md`.

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
