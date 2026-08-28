# Slice 05 (wolong arc03): backpressure-timeout-hardening

> Ledger per `LEDGER-DISCIPLINE.md` v2.2, Section A. Opened 2026-08-28.
> Closer: CC. Verifier: CDC. Evidence names commits and command results; CDC
> upgrades accepted `done` evidence from attested to reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| BH-1 | Slice05 starts from the active planning worktree, reads Slice04 close/CDC evidence, and preserves the current public API contract: `#(ok Plan)`, `#(unsolvable Detail)`, or typed `#(error #(Gate Reason Detail))`. | inspect `closing-report.md`; inspect `cdc-verification.md`; run existing public plan CT after implementation | serious | arc03 sequence | open | | Do not rely on old `docs/design-v0.1.0` paths unless they are intentionally mirrored. |
| BH-2 | The output-capture policy is explicit in code and operator docs. | inspect `src`, `README.md`, `config/sys.config`, and close report for stdout artifact vs stderr diagnostic/status policy | serious | arc03 OQ4/A6 | open | | The policy must distinguish artifact correctness from diagnostic preview bounds. |
| BH-3 | Existing `wolong-exec:run/3` and `wolong-exec:run-stdin/4` callers that pass `output-limit-bytes` remain compatible. | CT existing exec suite; grep call sites; add compatibility CT if runner opts change | serious | backward compatibility | open | | Do not force all callers to supply new per-stream keys. |
| BH-4 | Stdout and stderr can be bounded independently, or an equally explicit implemented policy justifies one shared bound. | CT with different stdout/stderr limits; inspect runner/gate option derivation | serious | release-scale policy | open | | Preferred shape: optional `stdout-limit-bytes` and `stderr-limit-bytes` with `output-limit-bytes` fallback. |
| BH-5 | App-env output policy is optional and validated when present. | EUnit or CT config tests for absent policy, valid policy, wrong shape, non-positive limits, and non-string/path-independent values as applicable | correctness | config surface | open | | Preserve existing configs; do not add a new required key. |
| BH-6 | Gate-level runner options are derived per gate from the output policy. | CT or inspection shows parser, grounder, and engine receive the intended stdout/stderr limits | correctness | gate hardening | open | | Avoid another hard-coded 65536-only gate path. |
| BH-7 | A parser stdout artifact larger than the old 65536-byte cap but within the configured parser stdout limit can feed grounder stdin successfully. | CT fixture case through `wolong-pipeline` or public `wolong:plan/2,3` | serious | parser stdout artifact scale | open | | Artifact bytes must remain complete for downstream handoff. |
| BH-8 | A grounder stdout artifact larger than the old 65536-byte cap but within the configured grounder stdout limit can feed engine stdin successfully. | CT fixture case through `wolong-pipeline` or public `wolong:plan/2,3` | serious | grounder stdout artifact scale | open | | Prove the middle pipe, not only runner capture. |
| BH-9 | An engine solved plan larger than the old 65536-byte cap but within the configured engine stdout limit returns public `#(ok Plan)` with durable payload bytes. | CT public plan case asserts `payload-bytes` exceeds 65536 and matches returned payload size | serious | project W1 | open | | `keep-artifacts=false` is a useful variant if feasible. |
| BH-10 | Stdout artifact over the configured stdout limit is a typed gate error and never a partial solved plan. | CT over-limit stdout fixture; assert gate/reason and absence of public solved shape | serious | artifact integrity | open | | Existing `artifact-truncated` behavior may be preserved or refined, but must remain typed. |
| BH-11 | Noisy stderr before final `PANDAPI_STATUS` can exceed the diagnostic preview limit while Wolong still classifies from final status fields. | CT noisy-stderr fixture; assert `stderr-truncated=true` or equivalent and status fields parsed as `ok`/expected status | serious | stderr/status ownership | open | | This is the key final-status-preservation row. |
| BH-12 | If final status is genuinely unrecoverable under the policy, Wolong returns a typed status error rather than guessing from diagnostics or stdout. | CT fixture with missing/unrecoverable status after truncation; assert typed `missing-status`/policy-specific reason | serious | managed-process safety | open | | Do not scrape diagnostic prose. |
| BH-13 | Flood-then-timeout over active stdout/stderr returns a typed timeout with bounded stream data and truncation metadata. | CT fixture that writes both streams then hangs; assert timeout detail fields | serious | project W2/A6 | open | | Use bounded event/poll synchronization, not unbounded sleeps. |
| BH-14 | TERM-resistant flood-then-timeout children are killed as an OS process group and leave no surviving process. | CT captures `os-pid`, waits boundedly for process absence, and asserts no survivor | serious | project W2/A6 | open | | Preserve erlexec `kill_group` semantics. |
| BH-15 | A successful dispatch after truncation/error/timeout still succeeds and worker cleanup returns to zero. | CT recovery sequence after over-limit and timeout cases | serious | project W4/A6 | open | | Proves failures do not poison later dispatches. |
| BH-16 | Public solved, unsolvable, timeout, and typed gate-error shapes remain compatible with Arc02/Slice03/Slice04 expectations. | run full CT; inspect representative public API cases | serious | API compatibility | open | | No public API redesign. |
| BH-17 | Fixture-backed CI remains deterministic and does not require sibling Chengdu binaries. | CI run or documented local no-env run; real-binary suite may skip when binaries are absent | correctness | CI honesty | open | | Remote real-binary proof stays Arc04/provisioning-dependent. |
| BH-18 | Local real-Chengdu public proof still passes when sibling binaries are available, or records a clear availability skip without claiming proof. | `WOLONG_CHENGDU_BIN_DIR=../chengdu/bin WOLONG_CHENGDU_FIXTURE_DIR=../chengdu/fixtures rebar3 as test ct --suite test/wolong_real_chengdu_SUITE.lfe` | correctness | Slice04 regression guard | open | | This is compatibility evidence, not release-scale stress unless Chengdu supplies large fixtures. |
| BH-19 | Scope guard holds: no streaming/spooling architecture, parser `- -`, split parser workers, provisioning, public verifier, action/decomposition parser, diagnostic-prose classifier, or legacy binary fallback lands. | inspect diff and `rg` scoped terms in `src`, `test`, `README.md`, `config`, and planning docs | serious | slice scope | open | | If streaming/spooling is required, stop and bubble up a new slice/design decision. |
| BH-20 | Local gates and formatter checks pass. | `rebar3 compile`; `rebar3 as test eunit`; `rebar3 as test ct`; `rebar3 xref`; `rebar3 dialyzer`; `rebar3 lfe format --check`; `rebar3 as test lfe format --check` | correctness | repo workflow | open | | No exceptions unless a tool is explicitly deferred with reason/re-entry. |
| BH-21 | A meaningful tamper cycle proves a new hardening invariant. | break final-status preservation, artifact truncation rejection, independent stream limits, or process-group timeout; show owning CT fails; revert and show pass | serious | ledger discipline | open | | Record exact failing/passing commands. |
| BH-22 | Closing report walks every ledger row and bubbles up Arc03 close readiness or the need for a remediation slice. | inspect `closing-report.md` for BH-1 through BH-22 and Bubble-up sections | correctness | project management | open | | CDC writes `cdc-verification.md` later. |

## What Worked

To be filled during close.

## Closure

Open as of 2026-08-28.
Rows: 22. Open: 22. Done: 0. Deferred: 0. No-op: 0.
