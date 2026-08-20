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
`PANDAPI_STATUS` fields. A solved engine run returns `#(ok Plan)`, a valid
engine no-plan outcome returns `#(unsolvable Detail)`, and gate, workspace,
binary, timeout, and dispatch failures return typed `#(error #(Boundary Reason
Detail))` tuples.

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

See [`docs/design-v0.1.0/project-plan.md`](docs/design-v0.1.0/project-plan.md)
for the full definition of done, non-goals, and arc roadmap.

## Status

**Pre-alpha.** `arc01-exec-substrate` is closed. `arc02-gate-pipeline` has
implemented parser/grounder/engine gate classification, workspaces, public
planning, dispatch supervision, and the explicit verification-boundary
disposition. `arc03-stdio-pipeline` is paused because current Chengdu 0.3.0
local binaries do not support input path `-` for parser, grounder, or engine.
`arc04-provisioning` is still future work.

Remote CI uses Wolong-owned fixtures and does not depend on a sibling Chengdu
checkout.

## Dev Setup

`wolong` locates pandaPI binaries via configuration (see
[`config/sys.config`](config/sys.config): `binaries`, `gate-timeouts`, and
`workdir`) and does not build them itself.

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
