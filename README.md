# wolong

[![build](https://github.com/billosys/wolong/actions/workflows/build.yml/badge.svg)](https://github.com/billosys/wolong/actions/workflows/build.yml)

[![][logo]][logo-large]

*卧龙 — Crouching Dragon.*

## Overview

`wolong` is an LFE/OTP application that supervises and exposes a typed API
for the PANDA (pandaPI) HTN planning toolchain, with OS-process management
via [erlexec](https://github.com/saleyn/erlexec). It runs the full pandaPI
gate sequence — parse → ground → solve → convert → **verify** — as
supervised external OS processes and returns
**validated-plan-or-unsolvable as an actual return type**: a plan is never
handed back unverified, and a proven-unsolvable problem is a success-shaped
result (`#(unsolvable ...)`), not an error. The one behavior this project
exists to guarantee: the confident-plan-for-unsolvable-problem failure mode
is structurally impossible at this API.

See [`docs/design-v0.1.0/project-plan.md`](docs/design-v0.1.0/project-plan.md)
for the full definition of done, non-goals, and arc roadmap.

## Status

**Pre-alpha. `arc01-exec-substrate` in progress.** `arc01` proves the
substrate every later gate stands on — the OTP application skeleton in LFE,
erlexec integrated and supervised, and a single "run this external tool,
bounded in time, and give me a typed answer" capability, proven against the
real `pandaPIparser`. No `plan`/`verify`/`validate` API yet; that lands in
`arc02`.

## Dev setup

`wolong` locates pandaPI binaries via configuration (see
[`config/sys.config`](config/sys.config) — `binaries`, `gate-timeouts`,
`workdir`) and does not build them itself. The recommended way to get
binaries on a dev machine is
[chengdu `v0.1.0`'s 4-command install](https://github.com/billosys/chengdu#install-from-the-chengdu-release):
download → checksum-verify → extract → smoke-verify, no build tools
required. Point `wolong`'s `binaries` config map at the resulting
`pandaPIparser` / `pandaPIgrounder` / `pandaPIengine` paths. (This is a
convenience, not a coupling: `wolong`'s config takes any paths, and
`chengdu` is not a dependency of this repo.)

Build and test locally:

```bash
rebar3 compile
rebar3 as test eunit
rebar3 xref
rebar3 dialyzer
```

## License

TBD.

[//]: ---Named-Links---

[logo]: assets/images/zhuge-liang-y250.png
[logo-large]: assets/images/zhuge-liang.png
