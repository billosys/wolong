# Slice 01 (wolong arc03): stdio-contract-investigation

> Open-set plan-of-record for `slice01-stdio-contract-investigation`, per
> `PROJECT-MANAGEMENT.md` v2.1. Parent: `../arc-plan.md`. Opened 2026-08-20.
> Implementer: CC. Verifier: CDC.

## 1. Goal

Determine whether Wolong can safely drive the current Chengdu 0.3.0
`pandapi-*` binaries through their supported stdin/stdout/stderr contract under
erlexec.

This is an investigation slice, not the stdio implementation slice. Its output
is a decision with evidence:

- **proceed:** Chengdu exposes the required contract and erlexec/LFE can drive
  it cleanly;
- **Wolong-design-needed:** Chengdu is adequate, but Wolong needs a specific
  runner/backpressure/pipeline design before implementation;
- **Chengdu-blocked:** Chengdu is missing or buggy in a way that prevents a
  safe Wolong stdio pipeline.

If the result is Chengdu-blocked, pause Wolong arc03 implementation and bubble
the exact re-entry condition to the project plan.

## 2. Context

Arc02 intentionally used file-backed artifacts and CI-safe fixture executables.
That proved Wolong's typed gate classification, dispatch supervision, no-plan
semantics, workspace cleanup, timeout/no-zombie behavior, and public API shapes.

It did not prove the release-critical contract: real Chengdu 0.3.0 binaries
interacting as CLI citizens through stdin/stdout/stderr under erlexec. Wolong
cannot release until that contract is proven and implemented.

The investigation must use the current local Chengdu checkout, not remembered
0.2.0 behavior and not old `pandaPI*` binary names.

## 3. In Scope

- Survey current Chengdu docs:
  - `../chengdu/docs/reference/cli.md`
  - `../chengdu/docs/managed-process.md`
- Probe current local binaries:
  - `../chengdu/bin/pandapi-parser`
  - `../chengdu/bin/pandapi-grounder`
  - `../chengdu/bin/pandapi-engine`
- Determine the exact supported stdin forms for each component:
  - whether input paths may be `-`;
  - whether parser can receive one or both HDDL inputs from stdin;
  - whether grounder and engine can receive artifacts from stdin;
  - what stdout contains when `--output -` is used;
  - where the final `PANDAPI_STATUS` record must live.
- Prove or falsify a real pipeline shape using shell probes first, then a
  minimal erlexec/LFE probe if feasible.
- Assess buffering/deadlock/backpressure risk for stdout artifacts and stderr
  diagnostics.
- Record the exact implementation recommendation for later slices.
- Record precise Chengdu blockers and re-entry conditions if any are found.

## 4. Out of Scope

- No production stdio runner implementation.
- No rewrite of `wolong-pipeline`, `wolong-gate`, or `wolong-exec` unless a
  tiny disposable probe is explicitly needed and committed as test-only
  evidence.
- No public API shape change.
- No release provisioning, downloader, checksum verifier, Hex packaging, or
  clean-machine install work.
- No workaround for a broken Chengdu process contract.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No diagnostic-prose classifier.
- No public `wolong:verify`, action parser, or decomposition parser.

## 5. Design Constraints

Do not use shell pipelines as the final Wolong design. Shell probes are allowed
only to characterize the external binaries. Wolong's implementation path must
remain argv-list erlexec process management with typed returns.

Stdout must have one owner at a time. If stdout carries an artifact, status and
diagnostics must be on stderr or another machine-safe channel. Wolong must not
classify outcomes from human diagnostic prose.

The investigation should distinguish three different facts:

- Chengdu's documented contract;
- Chengdu's actual local binary behavior;
- erlexec/LFE feasibility for implementing that behavior safely.

Treat mismatches between those facts as findings, not as assumptions to smooth
over.

## 6. Verification Approach

Primary evidence is command transcripts, grep-verifiable docs/binary probes,
and a small number of focused experiments. Run at least:

```bash
../chengdu/bin/pandapi-parser --help
../chengdu/bin/pandapi-grounder --help
../chengdu/bin/pandapi-engine --help
../chengdu/bin/pandapi-parser --version
../chengdu/bin/pandapi-grounder --version
../chengdu/bin/pandapi-engine --version
```

Run positive and negative probes for stdin/stdout/status ownership. Prefer
commands that make success or failure obvious through exit status, stdout byte
counts, stderr `PANDAPI_STATUS`, and artifact equivalence.

If an erlexec/LFE probe is attempted, keep it narrow and disposable unless it
becomes an intentional test fixture. Do not commit exploratory code that is not
owned by this slice's ledger.

Because this is a planning/investigation slice, the normal local gates should
still pass if committed files change:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
rebar3 lfe format --check
```

If formatter check fails for pre-existing files, record the exact scope and do
not run a broad formatting sweep unless the operator explicitly opens one.

## 7. Exit Criteria

- Current Chengdu docs and binary help/version output are surveyed and recorded.
- The exact stdin/stdout/stderr contract for parser, grounder, and engine is
  stated, including unsupported forms.
- A minimal solved pipeline and a valid no-plan pipeline are either proven
  through the required stdio shape or recorded as blocked with exact failure
  evidence.
- The investigation states whether Arc03 may proceed to implementation.
- Any Chengdu blocker includes the command, observed behavior, expected
  behavior, and Wolong re-entry condition.
- No production Wolong workaround lands for a Chengdu blocker.
- Local gates applicable to the committed change pass, or exceptions are
  recorded with re-entry conditions.
- `closing-report.md` walks every ledger row and includes Bubble-up to Arc03
  and the project roadmap.
