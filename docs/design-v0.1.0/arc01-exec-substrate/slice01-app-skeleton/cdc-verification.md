# Slice 01 (wolong arc01): app-skeleton — CDC verification

> Written by CDC (Cowork session, 2026-08-07). Independent reproduction of
> [`closing-report.md`](./closing-report.md) against [`ledger.md`](./ledger.md)
> (8 rows), per `LEDGER-DISCIPLINE.md` Section A and `PROJECT-MANAGEMENT.md`
> Part IV. Verification basis: a fresh **unauthenticated clone of
> `billosys/wolong` at HEAD `4e5f038`** in the cloud sandbox (Linux
> x86_64, Ubuntu 24.04) — the clone is the evidence channel, not the
> device mount (all 10 planning/config docs checksum-identical between
> mount and clone at verification time).

## Verification environment (disclosed substitutions)

The sandbox required two compensating actions, both disclosed here because
they change the *channel*, not the claims:

1. **hex.pm is unreachable from this sandbox** (`repo.hex.pm` /
   `builds.hex.pm` are not on the egress allowlist — a new sandbox fact,
   not previously recorded). Erlang/OTP **28.1.1** was therefore built
   from the official `erlang/otp` GitHub release tarball at the exact CI
   pin, and rebar3 **3.27.0** taken from its GitHub release escript. The
   six deps (lfe 2.2.2, erlexec 2.3.4, ltest 0.13.11, rebar3_lfe 0.5.7,
   plus transitive lfmt 0.4.0, erlang_color 1.0.0) were satisfied via
   rebar3 `_checkouts` from their upstream GitHub release tags, with each
   checkout's `.app.src` version verified equal to the pin.
   `rebar.config`/`rebar.lock` were **not modified**. Consequence: my
   build proves the *source at the pinned versions*; the hex-tarball
   channel itself is proven by K-7's CI run (which fetched from hex).
2. **erlexec will not start as root** (`port_exited_with_status 4`), and
   the sandbox shell is root. Test runs were executed as an unprivileged
   user (`verifier`), matching CI runners and the dev machine. This is an
   environment property, not a wolong defect — but worth remembering for
   any future sandbox reproduction (and it is mildly reassuring that the
   port program refuses root by default).

Also: `api.github.com` and Actions job logs are session-gated here;
K-1/K-7's GitHub-side claims were verified via unauthenticated `git
clone`/`ls-remote` and independent fetches of the public run/workflow
pages, not via `gh api`.

## Per-row walk

| Row | Verdict | Evidence (this pass) |
|-----|---------|----------------------|
| K-1 | **done, reproduced** | Unauthenticated `git clone https://github.com/billosys/wolong.git` succeeds → public. Remote org `billosys`, default branch `main` (`## main...origin/main`). Commit archaeology: 3 pre-existing commits (`d8a6b62` CLAUDE.md + project/arc plans; `3a0e2a4` images; `726a253` slice01 open set) precede any app code (`dcf59b3`), matching the claimed first-push content. `CLAUDE.md ## Workflow` at HEAD records direct-to-main. (`gh api` unavailable in sandbox; clone + page evidence substituted.) |
| K-2 | **done, reproduced** (channel substitution disclosed above) | `rebar3 compile` from the clean clone: clean, exit 0; erlexec's native `exec-port` compiled and linked against the source-built OTP 28.1.1 (`g++ … -lei -o …/exec-port`). `rebar.config` read: all deps exact strings, no `~>`/branch refs; `wolong.app.src` has `{mod,{'wolong-app',[]}}`, `{applications,[kernel,stdlib,erlexec]}`. Pins cross-checked live on hex.pm 2026-08-07: lfe 2.2.2 (2026-08-05), erlexec 2.3.4 (2026-06-12), ltest 0.13.11 (2025-01-11), rebar3_lfe 0.5.7 (2026-07-14) — each was the latest published version at CC's survey time, corroborating the surveyed-live claim. |
| K-3 | **done, reproduced** | `rebar3 as test eunit` as non-root: **12 tests, 0 failures, exit 0** (direct `$?`, no pipe). `start-stop-clean` read and confirmed to assert: `ensure_all_started` tag, `wolong-sup` and `exec` registered, clean `stop`, and an error-level `logger` handler sinking to ets asserted empty — the no-error-reports claim is genuinely test-asserted. `wolong-sup:init/1` declares `one_for_one`, intensity 5 / period 10, no children. |
| K-4 | **done, reproduced** | Beyond the suite: every error path exercised **directly from an erl shell** against the compiled beams — `missing-key` ×3, `wrong-shape` ×3, `non-string-path` ×2 all return their distinct `#(error #(config …))` terms; happy path returns the validated map; the shipped `config/sys.config` was `file:consult`-ed, `set_env`-ed, and validates `#(ok …)`. No invented default for `binaries` (unset → `missing-key`, confirmed). |
| K-5 | **done, reproduced** | Both probe tests green in the reproduced suite run (direct `exec:run/2` from LFE, ok-tag and error-tag paths). The OQ1 verdict is recorded in `arc-plan.md` **v1.1** at HEAD as a tracked Version History entry naming slice01, with the superseded "open" state preserved in the body (`(Was: open. …)`) — expansion, not overwrite, per the plan-change discipline. |
| K-6 | **done, reproduced** | Tamper cycle re-run independently: inverted the `validate-missing-binaries` expected atom → `12 tests, 1 failures`, **exit 1**; reverted (git-clean confirmed) → `12 tests, 0 failures`, **exit 0**. Exit codes read directly from `$?`, not through a pipe. The suite demonstrably can fail. |
| K-7 | **done, reproduced** — with finding F-1 | Run `31119229009` fetched independently: overall **Success**, 2 matrix jobs completed, on commit `146b494` — whose diff to HEAD is docs-only (`closing-report.md` + `ledger.md`, 2 files), so the green run covers HEAD's code exactly; the subsequent run on HEAD (`4e5f038`, "slice01 close…") is also green on the workflow page. Per-job log pages are auth-gated in this sandbox; overall run success entails both matrix legs green. Locally reproduced on Linux: `rebar3 xref` exit 0, `rebar3 dialyzer` exit 0 (zero warnings, zero exclusions — confirming the fixed-not-suppressed claim), `actionlint` v1.7.7 zero findings, exit 0. The 2026-08-06 GitHub Actions outage is externally corroborated (The Register 2026-08-06 "Latest GitHub outage squeezes Actions, Pages to death"; GitHub community incident thread #204152; HN thread) — the failed attempts were re-runs within the same run IDs and are not workflow defects. Version-survey corroboration: OTP 29.0.5 confirmed released 2026-08-03/04 (endoflife.date), exactly as the rationale states. **But see F-1 on the 28-branch pin.** |
| K-8 | **done, reproduced** | README at HEAD: contract paragraph names validated-plan-or-unsolvable with all three return shapes; status pre-alpha/arc01; the chengdu link's anchor target verified real — chengdu's README contains `## Install from the `chengdu` Release:` at line 21 (GitHub slug = `#install-from-the-chengdu-release`); badge URL points at the correct workflow path. CLAUDE.md Workflow section present. |

**Row count: 8 opened, 8 addressed, 8 verified. Done: 8 · deferred: 0 ·
no-op: 0 · silent drops: 0.**

## Findings

- **F-1 (K-7, significance: correctness-grade, disposition needed).**
  The OTP pin rationale is *incomplete as written*. It frames the choice
  as 28.1.1 vs. the two-day-old 29.0.5 — but the 28 branch's own head at
  survey time was **28.5.0.5 (2026-08-03)**, and OTP 28 has been on
  **security-only support since 2026-05** (endoflife.date, corroborated
  by the erlang/otp releases page showing 28.5.0.x maintenance releases
  through July 2026). 28.1.1 is ~4 minor releases behind its own branch,
  chosen because it matches the dev machine's Homebrew install. Nothing
  reproduced red because of it, and "stay on 28" is well-reasoned — but
  "which 28" was not surveyed, and the pin as it stands forgoes a year of
  28-branch fixes. *Proposed routing:* an explicit disposition, either
  (a) bump the CI pin (and ideally the dev machine) to the 28-branch head
  in slice02's open set, or (b) an operator-recorded rationale for
  staying at 28.1.1. Not an arc-plan change; a pins-not-floats hygiene
  disposition.
- **F-2 (K-4, polish, no action required this slice).** Two small
  asymmetries in the error taxonomy, noted for slice02's error-design
  consistency: a missing `base-dir` inside `workdir` reports
  `missing-key workdir-base-dir` while a missing `keep-artifacts` falls
  through to `wrong-shape workdir`; and `wrong-shape gate-timeouts`
  does not name the offending gate the way `non-string-path binaries
  parser` names its component. Both are within K-4's letter (every
  failure mode has a distinct typed error); flagged only because arc02's
  API error discipline will want one consistent granularity rule.
- **F-3 (environment, for the session-bootstrap doc).** New sandbox
  facts from this pass, none previously recorded: hex.pm/builds.hex.pm
  unreachable (use GitHub release tarballs + `_checkouts`); erlexec's
  port exits status 4 under root (run tests as an unprivileged user);
  `api.github.com` and Actions job logs session-gated (public clone +
  run-page fetches substitute). LFE from a git tag needs `make` in the
  checkout before rebar3's LFE hook can run (`bin/lfescript` resolves
  against the repo's own `ebin/`) — the hex tarball doesn't have this
  wrinkle.

## Bubble-up check (per `PROJECT-MANAGEMENT.md` Part IV)

- **Assigned piece delivered:** confirmed against `arc-plan.md`'s slice
  breakdown line — every clause (deps, app/sup, config schema stub,
  compiles/starts/stops clean, CI running the suite) is demonstrated by
  a reproduced row, not asserted.
- **Silent-drop diff:** honest. Scope-as-delivered matches slice-doc §2
  "In" item for item; each "Out" item verifiably stayed out (src/ contains
  only app/sup/config; no pandaPI invocation, no timeout machinery, no
  gen_statem code).
- **Arc-plan change needed?** CC's answer — no structural change — is
  correct as far as it goes: OQ1's resolution is already tracked (v1.1),
  and the `ltest`/`is-match` and eunit-runner findings are correctly
  routed as slice02 open-set inputs rather than plan changes. (The
  `is-match` behavior claim itself is *attested only* — I did not
  independently reproduce the macro's degradation, and slice02 should
  budget the five minutes to confirm it before designing its assertions
  around it.) F-1 above is the one item CC's bubble-up did not surface;
  it needs a disposition before slice02's open set pins its own CI
  assumptions, but it is a pins-hygiene disposition, not a slice
  breakdown/sequencing change.

## Closure

All 8 rows independently **reproduced** at slice scale; CC's closing
report is accurate, with no spec-softening detected and one genuine gap
(F-1) raised for disposition. The `rebar3 as test eunit` runner decision,
the tamper-provable suite, and the fixed-not-suppressed dialyzer finding
all held up under re-execution.

**CDC verdict: slice01 close verified.** Gate status: **PENDING
operator** — Duncan gates the slice (and F-1's disposition) per protocol.

Verified by: CDC (Claude, Cowork cloud session), 2026-08-07. Basis
commit: `4e5f038`. Suite: 12 tests / 0 failures / exit 0 (non-root);
tamper exit 1; xref exit 0; dialyzer exit 0; actionlint exit 0.
