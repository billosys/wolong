# wolong

[![build](https://github.com/billosys/wolong/actions/workflows/build.yml/badge.svg)](https://github.com/billosys/wolong/actions/workflows/build.yml)

[![][logo]][logo-large]

*卧龙 - Crouching Dragon.*

## Overview

`wolong` is an LFE/OTP application that supervises and exposes a typed API for
the PANDA (pandaPI) HTN planning toolchain, with OS-process management via
[erlexec](https://github.com/saleyn/erlexec).

The current supported 0.1.0 planning chain is the Chengdu 0.3.0 managed-process
surface:

```text
pandapi-parser -> pandapi-grounder -> pandapi-engine
```

`wolong` classifies each gate from the process exit code plus final
`PANDAPI_STATUS` fields. Stdout is the gate artifact channel: parser and
grounder stdout feed the next process, and engine stdout becomes the public
plan payload. Stderr is the diagnostic/status channel: returned diagnostics
are bounded, and Wolong also keeps a bounded stderr tail so final
`PANDAPI_STATUS` classification survives noisy diagnostics before the status
line. A solved engine run returns `#(ok Plan)`, a valid engine no-plan outcome
returns `#(unsolvable Detail)`, and gate, workspace, binary, timeout, and
dispatch failures return typed `#(error #(Boundary Reason Detail))` tuples.
Truncated stdout artifacts are typed gate errors and are never used as partial
downstream artifacts or solved plans.

Solved `Plan` maps include the durable engine plan payload and explicit
`verification-boundary` metadata. Today that boundary says
`separate-verifier=not-run`, with action-sequence and decomposition-tree parsing
deferred. No separate verifier has run.

## Public API

Current public functions:

- `wolong:validate/2` runs parser validation only.
- `wolong:plan/2` runs planning with default options.
- `wolong:plan/3` runs planning with explicit options.

`wolong:verify` is not part of the 0.1.0 public API. It is deferred until a
supported Chengdu verifier contract exists and Wolong has fixtures, tests, and
documentation for that contract.

The older design sketch that continued past search into conversion and
verification gates is historical context rather than the current implemented
surface.

Project planning lives off the implementation branch in the dedicated
`planning` branch/worktree. In a local development checkout, use
`git worktree list` to locate the planning worktree before reading or updating
project, arc, slice, ledger, closing-report, or CDC verification artifacts.
Those planning files are intentionally kept separate from the runtime and
public-facing documentation on `main`.

## Status

**Pre-alpha.** `arc01-exec-substrate` and `arc02-gate-pipeline` are closed.
`arc03-stdio-pipeline` has implemented the artifact stdio chain through the
public planning API, proved it against local Chengdu `release/0.3.x`
binaries when available, and now includes fixture-backed stress coverage for
larger stdout artifacts, noisy stderr before final status, stdout truncation,
flooding timeouts, process-group cleanup, and post-failure recovery.
`arc04-provisioning` is still future work.

Remote CI uses Wolong-owned fixtures and does not depend on a sibling Chengdu
checkout.

## Dev Setup

`wolong` locates pandaPI binaries via configuration (see
[`config/sys.config`](config/sys.config): `binaries`, `gate-timeouts`,
optional `output-limits`, and `workdir`) and does not build them itself.

For local development against a sibling Chengdu checkout, point the `binaries`
config map at:

```text
../chengdu/bin/pandapi-parser
../chengdu/bin/pandapi-grounder
../chengdu/bin/pandapi-engine
```

Release download, checksum verification, and clean-machine binary provisioning
belong to Arc04. Until then, manual binary placement is a development setup
step, not a Wolong runtime dependency.

`output-limits` is optional. If omitted, the runner keeps the compatibility
default `output-limit-bytes=65536` for both streams. When configured, each
gate may set independent positive byte limits for `stdout` and `stderr`.
Use larger stdout limits for expected artifact scale and stderr limits for
diagnostic preview size.

Build and test locally:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 as test ct
rebar3 xref
rebar3 dialyzer
```

## License

TBD.

[//]: ---Named-Links---

[logo]: assets/images/zhuge-liang-y250.png
[logo-large]: assets/images/zhuge-liang.png
