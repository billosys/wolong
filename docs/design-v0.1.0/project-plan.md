# wolong — project plan

> **wolong**: an LFE/OTP application that supervises and exposes a typed API
> for the PANDA (pandaPI) HTN planning toolchain, with OS-process management
> via [erlexec](https://github.com/saleyn/erlexec). *(Named for the Wolong
> National Nature Reserve — the sanctuary where pandas live under
> professional care — and for 卧龙, "Crouching Dragon," the sobriquet of Zhuge
> Liang, the archetypal strategist. A supervision tree for a planning organ,
> in one word.)*
>
> Plan-of-record at project scale, per the collaboration framework's
> `PROJECT-MANAGEMENT.md` (v2.1). Design substrate: **"Composite Cognition —
> Supervision-Tree Architecture"** (the planning organ's requirements),
> **"Planner Toolchain Selection — HDDL, pandaPI, and the JSON Bridge"** (the
> toolchain decision record and gate sequence), and the **PANDA Runbook**
> (verified gate mechanics, exit codes, and the `Status:`-line trap). This
> plan carries the OTP architecture at roadmap level; per-arc plans carry the
> process-level design when each arc is near.

## 1. Definition of done, and boundaries

**Done means:** a rebar3/LFE OTP application, published to hex.pm as
`wolong`, that a BEAM system can add as a dependency and use to run the
supported pandaPI managed-process gate sequence, with the verification
boundary explicit, as supervised external OS processes returning
**validated-plan-or-unsolvable as an actual return type**. The release-grade
process contract is the Chengdu 0.3.0 stdio-capable CLI surface: Wolong must
prove the real `pandapi-*` binaries can be driven through their supported
stdin/stdout/stderr behavior under erlexec before provisioning or Hex release
work can claim readiness.

The current implemented public surface is:

- `(wolong:plan domain problem opts)` -> `#(ok plan)` with durable engine plan
  payload bytes, artifact metadata, parser/grounder/engine provenance,
  workspace metadata, dispatch metadata, and explicit
  `verification-boundary` metadata | `#(unsolvable detail)` |
  `#(error #(gate reason detail))`
- `(wolong:plan domain problem)` -> the default wrapper over `plan/3`
- `(wolong:validate domain problem)` -> parser validation only:
  `#(ok properties)` | `#(error ...)`

`wolong:verify` is deferred for 0.1.0 because the current Chengdu 0.3.0
managed-process contract exposes parser, grounder, and engine as supported
normal surfaces, but no separate verifier command. The re-entry condition is a
supported verifier contract from Chengdu or another selected planner backend,
plus Wolong fixtures and tests proving `#(ok verified)`, `#(invalid detail)`,
and typed verifier errors. Action-sequence parsing and decomposition-tree
parsing are also deferred until a stable machine-readable plan/decomposition
format or supported verifier contract exists.

Every external process runs under erlexec with a per-gate timeout and kill
escalation — a hung `pandapi-engine` search dies cleanly and reports as a
typed timeout, never a zombie. Every gate failure crashes that dispatch
loudly with a typed error naming the gate — never a silent partial artifact
(the toolchain note's §8 gate contract, promoted to API semantics). Arc02
proved this for the file-backed managed-process shape; Arc03 owns the
release-critical stdio process contract.

**The one behavior this project exists to guarantee:** the confident-plan-
for-unsolvable-problem failure mode is structurally impossible at this API.
The historical runbook trap was an engine no-plan outcome that looked
success-shaped at the process level; the current Chengdu managed-process
contract exposes that as `status=domain_no_plan`, exit `2`. In either
contract shape, Wolong maps valid no-plan to `#(unsolvable ...)`, and no plan
is returned unverified.

**Explicit non-goals (0.1.0):**

- **No HDDL generation.** wolong consumes `.hddl` files (or binaries/strings
  of HDDL); the JSON bridge, schema, structural linter, and Lykn serializer
  are the bridge project's scope. wolong is the organ's process shell, not
  its translator.
- **No CCDP bus integration.** The API is shaped so a CCDP capability wrapper
  can sit on top (typed results carry provenance for exactly that reason),
  but registry, JSON-RPC, and content types are out of scope here.
- **No Aries, no SHOP3** — pandaPI only, per the toolchain decision record.
  (The API deliberately avoids pandaPI-isms where cheap, so a second planner
  slots in behind the same functions later.)
- **No planner pooling / distribution** beyond one supervised dispatch per
  request.
- **No building of pandaPI from source.** wolong locates binaries via
  configuration; provisioning them from chengdu releases is arc04's scope.

**Position in the composite-cognition architecture:** wolong is the planning
organ's process boundary — the Erlang-port-program shape the supervision-tree
note specifies, made concrete. Upstream of it sits the (future) JSON bridge;
downstream sit the pandaPI executables that chengdu builds and releases.

## 2. Arc roadmap

| Arc | Slug | Capability (one line) | Depends on |
|-----|------|----------------------|------------|
| arc01 | `exec-substrate` | wolong can run one supervised pandaPI process via erlexec and return a typed result — timeouts, kill escalation, exit-code mapping proven. | — |
| arc02 | `gate-pipeline` | The supervised file-backed `pandapi-*` gate pipeline; `plan`/`validate` API plus an explicit verification-boundary disposition; solved/unsolvable/typed-gate-error results end to end. | arc01 |
| arc03 | `stdio-pipeline` | Wolong proves and implements the release-critical stdin/stdout/stderr Chengdu 0.3.0 pipeline under erlexec, pausing Wolong if Chengdu lacks a clean supported contract. | arc02; chengdu 0.3.0 pre-release binaries/docs |
| arc04 | `provisioning` | Binaries fetched and checksum-verified from chengdu releases; config surface; hex.pm release readiness. | arc03; chengdu release artifacts |

Load-bearing note: arc01 deliberately proves the risky substrate (erlexec
lifecycle, LFE↔erlexec ergonomics, exit-code fidelity) on the *simplest*
component (parser validation) before arc02 builds the pipeline on it. arc03
is where wolong and chengdu first compose as process-contract peers. arc04 is
where release provenance composes — its checksum-verification row is the
consumer side of chengdu's provenance manifest.

## 3. Current status

- **arc01 — closed 2026-08-14.** `arc01-exec-substrate/closing-report.md`
  closes the substrate arc with local gates, real `pandapi-parser` evidence,
  and CI fixture coverage.
- **arc02 — open 2026-08-14.** Detailed plan:
  `arc02-gate-pipeline/arc-plan.md`. The arc opens from arc01's bubble-ups:
  current managed `PANDAPI_STATUS` classification, parser invalidity as
  `invalid-kind=undistinguished`, app-env-only binary lookup, and stream-to-
  file capture deferred until engine scale demands it. The old five-gate
  sketch (`parse -> ground -> solve -> convert -> verify`) is now treated as
  inherited context to reconcile, not an implementation promise: current
  Chengdu 0.3.0 managed docs expose parser, grounder, and engine as the
  supported external normal surfaces, and arc02 slice05 must either implement
  a supported verification surface or explicitly defer `wolong:verify` with a
  project-plan/README re-entry condition. All five Arc02 slices are CDC-closed,
  but arc-level release composition surfaced a gap: Arc02 proves a
  fixture-backed/file-artifact pipeline, not the stdio pipeline required for
  Wolong release readiness.
- **arc03 — open 2026-08-20.** Detailed plan:
  `arc03-stdio-pipeline/arc-plan.md`. This arc is inserted before provisioning
  to prove and implement the Chengdu 0.3.0 stdin/stdout/stderr contract under
  erlexec. Slice01 is investigation-first with an explicit stop condition: if
  Chengdu is missing or buggy for the required piped process contract, pause
  Wolong and route the finding to Chengdu.
- **arc04 — named only.** Depends on arc03 and Chengdu release artifacts.
  Sequencing risk recorded: if Chengdu releases lag after stdio behavior is
  proven, arc04 falls back to documented-manual binary placement, and the fetch
  step becomes a fast follow.

## 4. Project ledger

Composition rows verifying the DoD; open here, close (per-row walk) in the
project's `closing-report.md`. Strength vocabulary per `LEDGER-DISCIPLINE.md`.

| Row | Criterion | Target strength |
|-----|-----------|-----------------|
| W1 | On a clean machine with chengdu-released binaries, `(wolong:plan ...)` drives the release-grade stdio pipeline on the runbook's minimal pair and returns `#(ok plan)` with durable payload/provenance and explicit `verification-boundary.separate-verifier=not-run`; the same call on the runbook's circular-precondition variant returns `#(unsolvable ...)` — the two return types demonstrated side by side. | reproduced |
| W2 | A dispatch whose engine gate exceeds its timeout is killed (no surviving OS process) and returns a typed timeout error naming the gate. | reproduced |
| W3 | Every gate failure mode from the current managed-process contracts maps to a typed result from exit code plus final machine status (`PANDAPI_STATUS` where available, including the engine no-plan status) — no failure collapses into a generic error or diagnostic-prose scrape. | reproduced via test suite |
| W4 | The application's supervision tree isolates a crashed one-shot dispatch worker without taking down the app, later dispatch workers can start normally, and concurrent dispatches are isolated (one crash or timeout does not corrupt another dispatch). | reproduced |
| W5 | Published on hex.pm as `wolong`; a fresh rebar3 project adds it as a dep and reaches W1 following only the README. | reproduced |

## 5. Version history

- **v1.5 - 2026-08-20 (surfaced by arc02 close readiness review).** Arc02's
  five slices are CDC-closed, but its evidence is not release-sufficient for
  Wolong: it proves a supervised, typed, fixture-backed/file-artifact pipeline,
  while Wolong's release gate requires driving Chengdu 0.3.0 binaries through
  their supported stdin/stdout/stderr CLI contract under erlexec. Inserted new
  `arc03-stdio-pipeline` before provisioning and renumbered the former
  provisioning arc to `arc04-provisioning`. W1 now explicitly requires the
  release-grade stdio pipeline. If Arc03 Slice01 finds missing or buggy Chengdu
  behavior, Wolong pauses until Chengdu supplies the needed contract.
- **v1.4 - 2026-08-15 (surfaced by arc02 slice05).** The 0.1.0 implemented
  API boundary is now explicit: `wolong:validate/2` is parser validation,
  `wolong:plan/2` and `wolong:plan/3` run the supported parser -> grounder ->
  engine chain, solved plans carry `verification-boundary` metadata with
  `separate-verifier=not-run`, and public `wolong:verify` is deferred until a
  supported verifier contract exists. W1 no longer implies action-sequence or
  decomposition-tree parsing for 0.1.0.
- **v1.3 — 2026-08-15 (surfaced by arc02 slice04).** W4 is clarified to match
  the implemented OTP policy: dispatch workers are temporary one-shot children.
  A crashed dispatch is isolated and typed rather than replayed; the supervision
  tree remains alive and later dispatch workers start normally. Concurrent
  dispatch isolation still covers one crash or timeout not corrupting another
  dispatch.
- **v1.2 — 2026-08-14 (surfaced by arc02 opening).** Arc02 is now open at
  `arc02-gate-pipeline/arc-plan.md`, with slice01
  `gate-contract-substrate` opened for CC. The roadmap line for arc02 is
  refined from the older "full five-gate dispatch" wording to the current
  supported Chengdu managed-process surface: parser, grounder, and engine.
  The validation/verification invariant is preserved by making the
  verification boundary explicit. The top-level no-plan wording is also
  updated from the historical `Status: Proven unsolvable`/exit `0` trap to
  current `status=domain_no_plan`/exit `2`, while preserving the invariant
  that no-plan is `#(unsolvable ...)`, not a generic error. `wolong:verify`
  must not be implemented or documented as successful unless a supported
  verification contract exists; if no such contract exists in the current
  Chengdu line, arc02 must update the project docs to defer it with a concrete
  re-entry condition.
- **v1.1 — 2026-08-14 (surfaced by arc01 close).** Arc01 closes the
  supervised-process substrate and moves project status to arc02 next. The
  project plan now follows the current Chengdu 0.3.0 pre-release
  `pandapi-*` managed-process contract rather than the older parser
  `0/2/255` wording. Parser invalid-HDDL cases are typed but currently
  `invalid-kind=undistinguished`, because `pandapi-parser` emits
  `status=input_invalid`, `exit_code=22` for both broken syntax and broken
  reference/undeclared predicate without a stable machine subtype. CI uses a
  fixture executable until a later provisioning arc supplies real Chengdu
  release binaries; as of v1.5, that arc is arc04.
- **v1.0 — 2026-08-05.** Initial roadmap. Sources: the PANDA toolchain
  working session (verified gate mechanics), the toolchain-selection note's
  §8 gate contract, and the operator's erlexec decision (chosen over raw OTP
  ports for kill/timeout semantics, over erlport which is a Python/Ruby
  bridge). No child bubble-ups yet.
