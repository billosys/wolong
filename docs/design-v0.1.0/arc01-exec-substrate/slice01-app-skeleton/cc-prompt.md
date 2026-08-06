# CC assignment — wolong arc01 / slice01 — app-skeleton

You are CC, the implementing context for the **first slice of a new
project**: `wolong`, the LFE/OTP supervision tree and typed API for the
pandaPI HTN planning toolchain. Working dir: `~/lab/billosys/wolong`
(planning docs already present; no git repo yet — creating it correctly
is ledger row K-1). Read fully before writing anything.

## Read order (before any code)

1. `/CLAUDE.md` (wolong's) — the standing contracts, especially the API
   invariant: **validated-plan-or-unsolvable as an actual return type;
   no unverified plan crosses the API**. Nothing in this slice touches
   plans yet, but the typed-error discipline it implies starts with
   your first module.
2. `docs/design-v0.1.0/project-plan.md` — the DoD and the three-arc
   shape.
3. `docs/design-v0.1.0/arc01-exec-substrate/arc-plan.md` — what slice01
   is load-bearing for; OQ1 is yours to resolve and record.
4. `…/slice01-app-skeleton/slice-doc.md` + `ledger.md` — the
   specification of done: 8 rows, Section A protocol per the
   collaboration framework's `LEDGER-DISCIPLINE.md`.
5. **Load the `erlang-guidelines` skill** before writing any code — it
   owns the OTP idioms, supervision conventions, return-value
   discipline, typespecs, and the rebar3+dialyzer+xref toolchain
   practice this open set deliberately does not restate. Where LFE
   surface syntax differs from Erlang, the skill's *principles* still
   govern (behaviours, tree shape, error conventions).

## The work

Create `billosys/wolong` (public, org-correct — stated in the ledger
because the sibling project's one process defect was a repo born in the
wrong org); rebar3/LFE app skeleton with pinned deps (erlexec, test
framework); `wolong-app`/`wolong-sup`; `wolong-config` with typed
errors; the erlexec hello-world probe; real falsifiable tests; two-
platform CI with xref+dialyzer; README stub pointing dev provisioning
at chengdu `v0.1.0`'s install path.

## Constraints that bite

- **Survey versions live** (OTP, rebar3, LFE plugin, erlexec, BEAM
  setup action) exactly as chengdu surveyed runners — from the real
  registries/repos at implementation time, pinned exactly, choice
  recorded in the ledger row. Nothing from memory.
- **OQ1's verdict must be recorded** in the arc-plan via a tracked
  change (K-5). Direct erlexec calls or a thin wrapper — either is
  acceptable; silence is not.
- **Typed errors from module one.** `#(error #(config missing-key k))`
  beats `{error, badarg}` beats a crash with a string. The whole
  project's API contract grows from this habit.
- **The test suite must be able to fail** (K-6's tamper clause) and
  the start/stop cleanliness claim must be test-asserted, not
  eyeballed.
- Keep the skeleton thin: no pandaPI invocation, no timeout machinery,
  no premature abstraction for arc02's gates. Slices 02/03 own those;
  scope discipline here is what keeps their iteration budgets whole.
- Direct-to-main applies from the first push; the quality gate is the
  ledger + CDC verification, not merge ceremony.

## Protocol

Section A as practiced across chengdu's five slices: evidence per row
as it lands (attested, runs linked); amendment requests over silent
deviation; five-iteration budget (toolchain-discovery iterations on a
brand-new stack are expected and cheap — a broken push a local build
would have caught is not). At close: `closing-report.md` with the 8-row
walk plus the Part IV bubble-up to the arc — slice02 (`exec-runner`)
plans directly against what you report, especially the OQ1 verdict and
anything the LFE/erlexec boundary revealed. CDC (the Cowork session)
writes `cdc-verification.md`.

## Definition of done

All 8 rows at final status with attested evidence: a public org-correct
repo, a clean-clone build on both platforms, a start/stop-clean app, a
config module whose every error path is exercised, a proven erlexec
call from LFE with its verdict recorded, a falsifiable green suite, and
one linked two-platform CI run. The sanctuary's foundation — poured
level, or not poured.
