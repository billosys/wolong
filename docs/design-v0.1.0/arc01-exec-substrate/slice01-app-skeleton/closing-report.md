# Slice 01 (wolong arc01): app-skeleton — closing report

> Written by CC. Per-row walk against [`ledger.md`](./ledger.md) (opened
> with 8 rows, 2026-08-06), plus the bubble-up to
> [`../arc-plan.md`](../arc-plan.md) per `PROJECT-MANAGEMENT.md` Part IV.
> CDC verification (independent reproduction) is tracked separately in
> `cdc-verification.md`, not yet written as of this report.

## Per-row walk

All 8 rows: **done**. Zero deferred, zero no-op, zero silent drops (8
opened, 8 addressed).

- **K-1 — `billosys/wolong` exists, public, org-correct.** Done.
  `gh repo create billosys/wolong --public --source=. --remote=origin
  --push` (operator-confirmed before running — repo creation is a
  visible, shared-state action). `gh api repos/billosys/wolong` confirms
  `private: false`, `default_branch: main`, `owner: billosys`. First push
  carried the 3 pre-existing commits (planning docs, CLAUDE.md); this
  slice's commits added the app skeleton and the `CLAUDE.md` `## Workflow`
  section recording direct-to-main. Org-correct at birth — no transfer
  step needed, unlike chengdu's history (see Bubble-up §2).
- **K-2 — clean-clone pinned build.** Done. `rebar3 compile` clean on
  macOS with `warnings_as_errors`; erlexec's native `exec-port` builds via
  c++/ei. Every `rebar.config` dependency is an exact-string pin (no `~>`,
  no branch refs): `lfe` 2.2.2, `erlexec` 2.3.4 (hex package name differs
  from its OTP app registration — both are `erlexec`; the process it
  registers is `exec`), `rebar3_lfe` 0.5.7 as a `project_plugins` entry,
  `ltest` 0.13.11 in the test profile. `wolong.app.src` declares
  `{mod, {'wolong-app', []}}` and `{applications, [kernel, stdlib,
  erlexec]}`. The Linux leg of this same claim is independently
  demonstrated by K-7's CI run.
- **K-3 — start/stop clean, test-asserted.** Done.
  `test/unit-wolong-app-tests.lfe`'s `start-stop-clean` asserts
  `ensure_all_started` tags `ok`, both `wolong-sup` and `exec` register,
  `stop` returns `ok`, and — via a `logger` handler installed at `level
  => error` writing to a public ets table — that zero error/crash events
  occurred across the whole cycle. Not eyeballed.
- **K-4 — `wolong-config` typed errors.** Done.
  `test/unit-wolong-config-tests.lfe`: 9 tests, one happy path and one
  per failure mode across all three required keys — `missing-key` × 3,
  `wrong-shape` × 3, `non-string-path` × 2. No invented default for
  `binaries`. `config/sys.config` verified directly (`file:consult` +
  `application:set_env` + `wolong-config:validate`) to parse and pass.
- **K-5 — erlexec probe + OQ1 verdict recorded.** Done.
  `test/unit-wolong-exec-probe-tests.lfe` proves both the success and
  typed-error path of a direct, synchronous `exec:run/2` call from LFE.
  OQ1 verdict — **direct calls, no wrapper macro** — recorded as a
  tracked change in `arc-plan.md` v1.1 (2026-08-06), including the
  incidental finding that `ltest`'s `is-match` macro does not do genuine
  wildcard pattern matching (unrelated to erlexec; noted so the next
  slice doesn't rediscover it the hard way).
- **K-6 — falsifiable suite.** Done. Canonical runner is `rebar3 as test
  eunit` (not `rebar3 lfe ltest`, which prints a report but does not set
  a nonzero process exit code on failure — discovered this slice).
  Tamper: inverted one assertion in `unit-wolong-config-tests.lfe` →
  `12 tests, 1 failures`, exit 1 (checked directly, not through a pipe,
  per the house rule that pipes swallow exit codes) → reverted →
  `12 tests, 0 failures`, exit 0.
- **K-7 — CI green, two platforms.** Done, with a documented detour: a
  GitHub Actions platform-wide outage (status.github.com, active
  ~16:33–17:0x UTC 2026-08-06) hit both legs mid-verification —
  `macos-15` failed 4 consecutive times on pure GitHub-side infra errors
  before going green in 55s once GitHub's mitigation landed; `ubuntu-22.04`
  failed once similarly. None of the failures were workflow defects (all
  occurred in `Set up job`, before any of our steps ran). Final green run:
  https://github.com/billosys/wolong/actions/runs/31119229009 — both
  `build (ubuntu-22.04)` and `build (macos-15)` complete
  compile→test→xref→dialyzer clean. `erlef/setup-beam@v1` (major pin),
  OTP `28.1.1`, rebar3 `3.27.0`, all surveyed live 2026-08-06 (not from
  memory); rationale in `ledger.md`'s K-7 row. `actionlint` zero findings.
  No dialyzer exclusions needed — the one real warning dialyzer surfaced
  (`wolong-config.lfe`'s `cond`-generated dead case-arm) was fixed by
  rewriting to nested `if`, not suppressed. Also fixed in-flight:
  `actions/checkout` `v4`→`v7` (v4 was being forced onto a deprecated
  Node 20 runtime — unrelated to the outage, caught from the first run's
  annotations).
- **K-8 — README/CLAUDE.md current.** Done. `README.md`'s contract
  paragraph names validated-plan-or-unsolvable explicitly; status section
  states pre-alpha/`arc01-exec-substrate`-in-progress; dev setup links
  chengdu `v0.1.0`'s actual 4-command install path (read from the sibling
  repo's own README, not invented) and states explicitly that this is a
  convenience, not a dependency; CI badge points at the `build.yml`
  workflow. `CLAUDE.md`'s new `## Workflow` section records direct-to-main,
  org/visibility, and pins-not-floats.

## Bubble-up to the arc

**1. Did this slice deliver the piece of the arc's capability the
arc-plan assigned it?** Yes, as specified in `arc-plan.md`'s slice
breakdown: "rebar3 LFE OTP app `wolong`: deps (erlexec, ltest),
`wolong_app`/`wolong_sup`, config schema stub (binary paths, timeouts),
compiles, starts, stops clean; CI stub running the test suite." Every
clause of that line is now true and evidenced (K-2, K-3, K-4, K-7). The
slice stayed inside its declared scope — no pandaPI invocation, no
timeout/kill machinery, no `gen_statem` sketch implementation — leaving
slice02's and arc02's iteration budgets untouched.

**2. What did implementing this slice reveal that the arc-plan did not
anticipate?**

- **OQ1 is resolved** (arc-plan v1.1, tracked): direct `exec:run/2`
  calls, no wrapper macro. This directly shapes slice02's `wolong_exec`
  design — it can be a domain-contract wrapper (timeouts, kill
  escalation, typed results) built on plain `exec:run`/`exec:run_link`
  calls, not an ergonomics-driven abstraction layer.
- **A genuinely new fact for slice02 to know:** `ltest`'s `is-match`
  macro (built on eunit's `assertMatch` via `include-lib` HRL
  translation) does not perform real wildcard pattern matching in this
  environment — a guard like `#(ok _)` compares the literal atom `_`,
  not a wildcard, and fails against any real value. Slice01's tests work
  around this with `element/1` tag checks and fully-concrete
  `is-equal`. Slice02, which will assert on erlexec results far more
  extensively (partial output, exit statuses, kill outcomes), should
  either confirm this limitation still holds or use the same
  workaround pattern from the start rather than losing an iteration to
  rediscovering it.
- **The canonical test-running command is `rebar3 as test eunit`, not
  `rebar3 lfe ltest`** — the latter does not propagate a nonzero exit
  code on failure, which would have silently defeated K-6's tamper
  requirement and CI's ability to fail on red tests. This is worth a
  standing note for every later slice's CI step, not just this one's.
  (No arc-plan change needed — this is slice-local tooling knowledge,
  not a capability or sequencing fact.)
- **GitHub Actions had a platform-wide outage during this slice's CI
  verification**, unrelated to wolong or chengdu. No process change
  needed; noted here only so a future reader of the ledger's K-7
  evidence doesn't mistake a documented external outage for a red flag
  in the work.

None of the above changes slice02/slice03's scope or sequencing as
`arc-plan.md` currently states them — no arc-plan structural change is
needed. The OQ1 resolution and the `ltest`/eunit findings are already
recorded (arc-plan v1.1 for OQ1; this report for the test-tooling facts,
which slice02's own open set should read before it plans).

**3. The silent-drop diff at slice scale.** Scope-as-specified (slice-doc
§2 "In") vs. scope-as-delivered: full match. Every "In" item landed:
repo creation, app skeleton, config surface, erlexec probe with recorded
verdict, test scaffold (tamper-provable), CI stub (compile→test→xref→
dialyzer, both platforms), quality floor (warnings-as-errors, xref clean,
dialyzer clean with zero exclusions), README stub. Every "Out" item
stayed out: no pandaPI binary invocation, no generic exec-runner
timeout/kill semantics, no hex.pm publication, no dialyzer specs beyond
the skeleton's own modules (none were added; dialyzer is clean without
them), no CI beyond compile/test/xref/dialyzer. Nothing disclosed as
deferred; nothing dropped silently.

## Next

`slice02-exec-runner`'s open set should be written next, per *plan late,
plan deep* — after this bubble-up, not before — reading this report's
OQ1 verdict and the `ltest`/`is-match` finding above.
