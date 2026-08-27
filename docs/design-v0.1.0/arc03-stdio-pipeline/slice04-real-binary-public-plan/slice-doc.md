# Slice 04 (wolong arc03): real-binary-public-plan

> Open-set plan-of-record for `slice04-real-binary-public-plan`, per
> `PROJECT-MANAGEMENT.md` v2.1 and the Wolong-local `slice-doc.md` convention.
> Parent: `../arc-plan.md`. Opened 2026-08-27. Implementer: CC.
> Verifier: CDC.

## 1. Goal

Prove that Wolong's public API can drive the current real Chengdu 0.3.0
`pandapi-*` binaries through the release-critical stdio artifact path:

```text
wolong:plan/2,3
  -> pandapi-parser --supervised --status=stderr --output - DOMAIN PROBLEM
  -> pandapi-grounder --supervised --status=stderr --output - -
  -> pandapi-engine --supervised --status=stderr --output - -

wolong:validate/2
  -> pandapi-parser only
```

This slice turns the local real-Chengdu smoke from Slice03 into a repeatable
public-boundary proof. It must preserve fixture-backed CI and must not imply
that released artifacts or clean-machine provisioning are solved before Arc04.

## 2. Context

Slice02 added `wolong-exec:run-stdin/4`, proving stdin bytes plus EOF under
erlexec. Slice03 rewired the internal gate pipeline so parser artifact stdout
feeds grounder stdin, grounder artifact stdout feeds engine stdin, and engine
stdout becomes the durable public plan payload.

The remaining Arc03 proof is now at the consumer boundary. We need repeatable
evidence that `wolong:plan/2`, `wolong:plan/3`, and `wolong:validate/2` work
against real local Chengdu binaries, not only Wolong-owned fixtures.

Current Chengdu contract sources:

- `../chengdu/docs/reference/cli.md`
- `../chengdu/docs/managed-process.md`
- `../chengdu/fixtures/contract/stdio-contract-records.md`
- `../chengdu/fixtures/contract/pipeline-contract-records.md`

Current local binary shape:

```text
../chengdu/bin/pandapi-parser
../chengdu/bin/pandapi-grounder
../chengdu/bin/pandapi-engine
```

The parser caveat remains load-bearing. Chengdu supports exactly one parser
HDDL input from stdin (`domain -` or `problem -`) and rejects parser `- -`.
Wolong's release path for this slice is the common two-file public API:
domain path plus problem path into one parser invocation, then stdio artifacts
between parser, grounder, and engine.

## 3. In Scope

- Add a repeatable real-Chengdu public-boundary proof harness, preferably a
  focused Common Test suite that can be run locally when real binaries and
  fixtures are available.
- Configure the real-binary proof from environment or explicit test config;
  do not hard-code a requirement that remote CI has `../chengdu`.
- Exercise public `wolong:plan/3` against real Chengdu minimal HDDL and assert
  `#(ok Plan)` with non-empty durable payload bytes.
- Exercise public `wolong:plan/2` as the default wrapper against real Chengdu
  minimal HDDL.
- Exercise public `wolong:plan/3` against real Chengdu unsolvable HDDL and
  assert `#(unsolvable Detail)` from engine `status=domain_no_plan`, exit `2`,
  and outcome `no_plan`.
- Exercise `keep-artifacts=false` with real binaries and assert the public
  solved payload survives cleanup.
- Exercise `wolong:validate/2` with real parser only and assert it remains
  parser validation, not a full plan dispatch.
- Exercise at least one real parser negative outcome through `wolong:validate/2`
  or `wolong:plan/3`, using stable status/exit fields rather than diagnostic
  prose.
- Assert provenance/status fields that prove the public plan path used the
  stdio pipeline: parser artifact stdout, grounder `path=-`/`path_role=htn`,
  and engine `path=-`/`path_role=engine_input`.
- Preserve and run the existing fixture-backed CI suites.
- Document exactly how an operator runs the real-binary proof locally.

## 4. Out of Scope

- No release downloader, checksum verifier, provenance manifest consumer, or
  Hex publication.
- No claim that clean-machine release provisioning is done.
- No requirement that remote CI check out or build sibling `../chengdu`.
- No parser `- -` workaround.
- No split domain/problem parser workers.
- No framed parser stdin protocol.
- No planner pool, queue, backpressure API, or distributed Erlang.
- No diagnostic-prose classifier.
- No legacy `pandaPIparser`, `pandaPIgrounder`, or `pandaPIengine` fallback.
- No public `wolong:verify`, action-sequence parser, or decomposition-tree
  parser.
- No broad pipeline redesign unless a real-binary proof exposes a concrete
  mismatch with the documented Chengdu contract.

## 5. Design Constraints

The real-binary proof must use Wolong's public API as the primary boundary.
Raw shell pipelines, direct Chengdu commands, and lower-level
`wolong-exec:run-stdin/4` probes are useful diagnostics, but they do not prove
the consumer contract for this slice.

The harness should be honest about availability. If real binaries or fixtures
are absent, the focused real-binary suite may skip with a clear reason, but the
closing report must not claim real-binary proof from skipped tests. If the
binaries are present locally, the proof must run and the evidence must record
the Chengdu branch/head or release identifier used.

Remote CI remains fixture-backed unless release artifacts are explicitly added
to the workflow. That is acceptable for Slice04, but it must be stated
directly. Arc04 owns release acquisition and checksum/provenance composition.

Classification remains machine-first. Assert exit code, final `PANDAPI_STATUS`
fields, public tags, artifact metadata, and provenance. Do not scrape Chengdu
diagnostic prose to decide success or failure.

## 6. Verification Approach

Use Common Test for the repeatable public-boundary proof. A good shape is a
focused suite such as `test/wolong_real_chengdu_SUITE.lfe` with a small helper
that resolves:

```text
WOLONG_CHENGDU_BIN_DIR
WOLONG_CHENGDU_FIXTURE_DIR
```

or uses an explicit documented local default only when it exists:

```text
../chengdu/bin
../chengdu/fixtures
```

The suite should either run real-binary cases or skip them with one clear
reason. The normal `rebar3 as test ct` gate may include the suite only if the
skip is clean and visible, or the slice may add a documented focused command
for the real-binary suite. Choose the form that keeps CI reliable and the
local proof easy to reproduce.

Minimum real-binary cases:

- `wolong:plan/3` minimal solved;
- `wolong:plan/2` minimal solved wrapper;
- `wolong:plan/3` minimal solved with `keep-artifacts=false`;
- `wolong:plan/3` unsolvable;
- `wolong:validate/2` valid parser-only validation;
- one parser invalid or missing-input negative case with typed status mapping;
- provenance/status check proving parser stdout, grounder stdin/stdout, and
  engine stdin/stdout.

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

Also run and record the real-binary proof command, including the selected
binary directory, fixture directory, Chengdu branch/head or release identifier,
and observed solved/no-plan public result summaries.

Perform one tamper cycle. Good choices include pointing the real-binary proof
at a missing engine, weakening the provenance assertion so file handoff would
pass, treating no-plan as generic error, or changing the proof to accept a
zero-byte solved payload. Show the owning test fails, revert the tamper, and
show it passes.

## 7. Exit Criteria

- A repeatable local real-Chengdu public-boundary proof exists and is
  documented.
- The proof uses real `pandapi-parser`, `pandapi-grounder`, and
  `pandapi-engine` binaries, not Wolong fixtures.
- Public `wolong:plan/3` returns `#(ok Plan)` with durable non-empty payload
  for the real minimal pair.
- Public `wolong:plan/2` remains a working default wrapper with real binaries.
- Public `wolong:plan/3` returns `#(unsolvable Detail)` for the real
  unsolvable pair from engine `domain_no_plan` / exit `2`.
- `keep-artifacts=false` preserves the public solved payload after cleanup.
- `wolong:validate/2` remains parser-only with real parser binary evidence.
- At least one real parser negative path maps to a typed public result without
  diagnostic-prose scraping.
- Provenance/status assertions show the public plan path uses parser stdout,
  grounder stdin/stdout, and engine stdin/stdout.
- Existing fixture-backed CT, EUnit, xref, Dialyzer, and formatter gates stay
  green.
- Remote CI evidence is recorded honestly as fixture-backed unless release
  artifacts have been explicitly added.
- Scope guard holds: no provisioning, parser `- -`, split parser workers,
  public verifier, or release packaging lands.
- `closing-report.md` walks every ledger row and includes Bubble-up to Arc03
  and the project roadmap.
