# Slice 01 (wolong arc03): stdio-contract-investigation

> Ledger per `LEDGER-DISCIPLINE.md` v2.0, Section A. All rows open at slice
> start, 2026-08-20. Closer: CC. Verifier: CDC. Evidence names commits and
> command results; CDC upgrades accepted `done` evidence from attested to
> reproduced.

## Ledger

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|----|-----------|--------|--------------|--------|--------|----------|-------|
| SI-1 | Current Chengdu docs are surveyed for stdin/stdout/stderr, `--output -`, `--status=stderr`, `--status=stdout`, and supported parser/grounder/engine invocation forms. | inspect `../chengdu/docs/reference/cli.md` and `../chengdu/docs/managed-process.md`; record exact lines or excerpts in closing report | serious | arc03 OQ1/OQ2 | open | | Do not rely on remembered 0.2.0 behavior. |
| SI-2 | Current local `pandapi-*` binaries are surveyed with `--help`, `--version`, and executable presence checks. | `ls -al ../chengdu/bin`; run all three `--help` and `--version` commands | serious | arc03 dependencies | open | | Use `pandapi-*`, never legacy `pandaPI*` names. |
| SI-3 | Parser stdin feasibility is proven or blocked: exact supported way to provide domain/problem through stdin is identified, including whether one or both inputs may be `-`. | run focused parser probes; compare exit status, stdout, stderr final status, and output artifact/stream | serious | release process contract | open | | If parser cannot accept required stdin form, classify Chengdu-blocked unless docs say Wolong should use files. |
| SI-4 | Grounder stdin feasibility is proven or blocked: parser artifact from stdin reaches grounding and can emit grounder artifact to stdout. | run focused grounder probes with `--output -`; inspect stdout artifact bytes and stderr status | serious | release process contract | open | | Include negative probe for unsupported/malformed stdin if useful. |
| SI-5 | Engine stdin feasibility is proven or blocked: grounded artifact from stdin reaches search and can emit solved plan or no-plan outcome without stdout/status mixing. | run focused engine probes for minimal solved and unsolvable inputs; inspect stdout, stderr, exit code, and status fields | serious | release process contract | open | | Valid no-plan must stay success-shaped for Wolong. |
| SI-6 | A full real-binary stdio chain is proven or blocked for minimal solved input. | shell probe acceptable for investigation: parser stdout -> grounder stdin -> engine stdin, with status on stderr and no diagnostic-prose classification | serious | arc03 A3 | open | | If shell pipe works but erlexec feasibility is unknown, mark as Wolong-design-needed, not fully proceed. |
| SI-7 | A full real-binary stdio chain is proven or blocked for the valid no-plan fixture. | same as SI-6 using unsolvable/circular-precondition fixture; assert engine `domain_no_plan`/exit `2` | serious | project W1 | open | | No-plan must not be treated as generic failure. |
| SI-8 | stdout ownership is verified: artifact stdout never mixes with status, diagnostics, progress, statistics, color, or prompts on supervised paths. | inspect stdout/stderr captures from SI-3 through SI-7; run color/status conflict probes if needed | serious | managed-process safety | open | | Mixed stdout is a release blocker unless Chengdu provides a different supported channel. |
| SI-9 | stderr/status behavior is verified: final `PANDAPI_STATUS` remains machine-parseable for success, no-plan, invalid input, and usage/status conflicts. | run representative success and failure probes; parse final status fields manually or with existing parser if convenient | serious | typed gate mapping | open | | Do not classify from diagnostic prose. |
| SI-10 | erlexec/LFE feasibility is assessed for writing stdin and concurrently reading stdout/stderr without shell command strings. | inspect erlexec docs/API or existing deps; run a minimal LFE probe if feasible; record exact API shape or blocker | serious | arc03 OQ3 | open | | This row gates whether Slice02 can implement a runner directly. |
| SI-11 | Buffering/deadlock/backpressure risk is assessed for large stdout artifacts and stderr diagnostics. | run or design a bounded-output probe; inspect artifact sizes from real fixtures; record whether Slice05 hardening is required | correctness | arc03 OQ4 | open | | Keep memory-vs-stream-to-file recommendation explicit. |
| SI-12 | CI strategy is recommended honestly before Chengdu release artifacts exist. | inspect current CI and fixture strategy; state whether CI uses strict fixtures, optional local real-binary CT, or future release-artifact jobs | correctness | arc03 OQ5 | open | | Remote CI must not pretend it has sibling `../chengdu` binaries. |
| SI-13 | The final decision is explicit: proceed, Wolong-design-needed, or Chengdu-blocked, with re-entry conditions. | closing report contains a named decision section and maps it to later slices or pause condition | serious | arc03 slice01 goal | open | | This is the slice's primary output. |
| SI-14 | Scope fence holds: no production stdio runner, public API shape change, release provisioning, legacy fallback, diagnostic-prose classifier, public verifier, action parser, or decomposition parser lands. | `rg -n` checks in `src`, `test`, `README.md`, and this slice dir; inspect any hits as prose or pre-existing metadata | serious | slice-doc scope | open | | Tiny test-only probes must be explicitly owned if committed. |
| SI-15 | Local gates applicable to the committed change pass, including formatter check per current `AGENTS.md`, or exceptions are recorded with re-entry conditions. | `rebar3 compile`; `rebar3 as test eunit`; `rebar3 as test ct`; `rebar3 xref`; `rebar3 dialyzer`; `rebar3 lfe format --check` | correctness | repo workflow | open | | Do not hide formatter failures behind unrelated formatting sweeps. |
| SI-16 | Closing report walks every ledger row and includes Bubble-up to Arc03/project with any Chengdu pause condition. | inspect `closing-report.md` for SI-1 through SI-16, `Bubble-up to Arc03`, `project`, and decision wording | correctness | project-management | open | | CDC writes `cdc-verification.md` later. |

## What Worked

_(To be filled at slice close. Record investigation practices that prevented
false release-readiness claims.)_

## Closure

Open.
Rows: 16. Done: 0. Deferred: 0. No-op: 0.
