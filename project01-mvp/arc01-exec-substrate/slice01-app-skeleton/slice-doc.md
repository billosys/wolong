# wolong arc01 / slice01 — app-skeleton — slice doc

> Plan-of-record for this slice, per `PROJECT-MANAGEMENT.md` (v2.1).
> Parent: [`../arc-plan.md`](../arc-plan.md) (v1.0). Ledger:
> [`./ledger.md`](./ledger.md). Assignment: [`./cc-prompt.md`](./cc-prompt.md).
> First slice of the wolong project — the repo itself gets created here.

## 1. Goal

A rebar3/LFE OTP application named `wolong` that exists, compiles,
starts, stops, and proves its riskiest dependency at hello-world level.
At slice close: the `billosys/wolong` repo is real (public, org-correct
— the chengdu lesson is a standing instruction now); `rebar3` builds the
app with erlexec and the test framework resolved at pinned versions; the
supervision skeleton (`wolong_app`, `wolong_sup`) starts and stops
clean; a config module reads and validates the app's configuration
surface (binary paths, per-gate timeouts, workdir policy) with typed
errors; a real test suite runs green in CI on both platforms; and —
the arc's OQ1, owned by this slice — **erlexec has been called from LFE
successfully**, with the ergonomics verdict (thin macro layer or direct
calls) recorded.

Deliberately thin: no pandaPI processes run in this slice (that is
slice02/03's ground). The risk this slice burns down is *toolchain and
substrate* — LFE + rebar3 + erlexec (which compiles native code at
build time) + OTP on two platforms + CI — so that slice02's iteration
budget is spent on process semantics, not build plumbing.

## 2. Scope

**In:**

- **Repo creation**: `billosys/wolong`, public, `main`, direct-to-main
  convention (same operator override as chengdu; record it in wolong's
  CLAUDE.md workflow section at creation). The existing planning docs
  and CLAUDE.md (already on disk) are the first commit's content.
- **App skeleton**: `rebar.config` (LFE plugin, erlexec, test dep —
  every dep pinned to an exact version, pins-not-floats), `src/wolong.app.src`,
  `src/wolong-app.lfe`, `src/wolong-sup.lfe` (empty-but-real
  supervision tree: strategy declared, no children yet beyond what
  config requires), OTP application metadata correct (`mod`,
  `applications` including `exec`).
- **Config surface**: `src/wolong-config.lfe` — reads app env for:
  `binaries` (map of component → path), `gate-timeouts` (map, ms),
  `workdir` (base dir + keep-artifacts policy). Presence/shape
  validation with **typed errors** (`#(error #(config missing-key ...))`
  style — the API contract's error discipline starts here, not in
  arc02). A commented `config/sys.config` example. Defaults documented;
  no defaults invented for binary paths (explicit beats convenient —
  arc-plan OQ3's recorded default).
- **The erlexec probe (arc OQ1)**: a minimal supervised use of erlexec
  from LFE — run a trivial OS command synchronously, get
  `#(ok ...)`/`#(error ...)` back, and observe exec's own supervision
  starting under the app. The slice records the ergonomics verdict:
  direct `(exec:run ...)` calls, or a thin wrapper module if the option
  lists prove hostile from LFE. Either verdict is fine; an *unrecorded*
  verdict is not.
- **Test scaffold**: real tests (start/stop cleanliness incl. no error
  reports; config validation happy + each typed-error path; the erlexec
  probe), runnable via rebar3, green locally and in CI. Per house rule,
  the suite must demonstrably be able to fail (one tamper check in the
  ledger row's Verify).
- **CI stub**: `.github/workflows/build.yml` — `ubuntu-22.04` +
  `macos-15` (the platform floors chengdu already validated as runner
  choices), using the standard BEAM setup action at a pinned major,
  OTP/rebar3/LFE versions pinned explicitly (CC surveys current
  versions the way chengdu surveyed runners — live, not from memory);
  compile → tests → xref → dialyzer. actionlint clean. macOS leg
  matters *because* erlexec compiles native code.
- **Quality floor**: compile with warnings-as-errors; `xref` clean;
  `dialyzer` clean (a fresh app should have no baseline debt — if LFE
  emissions produce unavoidable warnings, each exclusion is documented
  inline, the partial-adoption rule applied to suppressions).
- **README stub**: what wolong is (the one-paragraph contract,
  including validated-plan-or-unsolvable), status (pre-alpha,
  arc01-in-progress), dev setup — including that dev machines get
  pandaPI binaries via **chengdu `v0.1.0`'s 4-command install** (link),
  which did not exist when the arc-plan was written and is now the
  recommended dev provisioning path. (This does NOT make chengdu an
  arc01 dependency — config still takes any paths; it's a convenience
  documented, not a coupling introduced.)

**Out (disclosed, not dropped):**

- Running any pandaPI binary — slice03 (`parser-validate`).
- The generic exec-runner with timeout/kill semantics — slice02
  (`exec-runner`); the probe here is deliberately trivial.
- hex.pm publication — project W5's concern, later arc; but note the
  operator's standing option to publish an early name-holding stub
  once this slice lands (decision record 2026-08-06). Operator's call,
  not slice scope.
- Dialyzer specs beyond what the skeleton's own modules need.
- Any CI beyond compile/test/xref/dialyzer (no release, no coverage
  threshold yet — coverage discipline arrives when there is surface
  worth covering, arc02).

## 3. Constraints

- **LFE targeting rebar3**; code follows the erlang-guidelines skill's
  OTP conventions (CC loads that skill before writing code — it is the
  domain layer; this open set is deliberately silent on idioms the
  skill owns).
- Typed errors from the first module; no stringly errors anywhere.
- Pins-not-floats: dep versions, OTP versions in CI, action majors.
- The chengdu workflow lessons apply where relevant (fail-loud, gates
  that can fail, actionlint, no logic in YAML beyond calling standard
  build tools).
- Repo home is **billosys, public** — stated twice because the one
  process defect of the sibling project was exactly this.

## 4. Verification approach

CC implements and attests on macOS (its machine) with the Linux half
via CI. CDC verifies from the sandbox: authenticated clone; rebar3
build + test run on Linux locally (OTP available via apt/asdf in the
sandbox); CI runs independently fetched; config typed-error paths
exercised directly; the tamper check on the test suite re-run; per-row
re-walk per `LEDGER-DISCIPLINE.md` Section A.

## 5. Exit criteria

The ledger's 8 rows — see [`./ledger.md`](./ledger.md). Shape: repo
real and org-correct (K-1); app compiles/starts/stops clean (K-2, K-3);
config surface validated with typed errors (K-4); erlexec proven from
LFE with verdict recorded (K-5); tests real and falsifiable (K-6); CI
green both platforms with quality floor (K-7); README/docs current
(K-8).
