---
title: Fluxget
summary: An aria2 download manager built on a V-language desktop framework, kept stable by a machine-checked seam.
problem: >-
  Every desktop app that needs a UI ends up shipping a browser engine and a
  bundler. vails inverts that by rendering into the OS webview, but it was
  fourteen commits old with no tags and no CI, and its own roadmap announced a
  breaking change to the exact subsystem Fluxget depends on. So the real
  question was never "how do I download files" — it was how to build on an
  unstable framework without becoming hostage to it.
order: 1
status: live
featured: true
stack:
  - V
  - TypeScript
  - aria2 JSON-RPC
  - WebView2
  - PowerShell
tags:
  - systems
  - architecture
---

## Discipline is not a mechanism

Isolation from an unstable framework is only real if something enforces it. Being
careful is not enforcement, so the boundary gets expressed three ways — each one
checkable:

| Mechanism | What it does | Where |
| --- | --- | --- |
| **The seam** | Only `main.v` and `platform/` may import vails. Everything else — `rpc/`, `engine/`, the entire frontend — is plain V with no framework knowledge. | `scripts/check-isolation.ps1` |
| **The contract** | ~34 vails symbols Fluxget depends on, checked in two layers. Compiling `platform/contract.v` *is* the check, and `contract_test.v` proves the behaviour still holds. | `platform/contract.v` |
| **The pin** | `vendor/vails` is a submodule and `vails.lock` records the last revision that passed the gate. The sync script always tries upstream `main` and **rolls back automatically** if the gate goes red. | `scripts/sync-vails.ps1` |

The pin is the interesting one. Upstream is always tried, so improvements land on
their own. But a failing gate reverts the revision instead of leaving the app
broken. You keep the upside and drop the risk.

## The domain model came first

`CONTEXT.md` defines the vocabulary before any UI exists, and it is strict about
words borrowed from upstream.

A `GID` is aria2's 16-hex download id: opaque, never parsed. A `Status` passes
through unchanged, so an aria2 release cannot invent a state the UI has never
heard of.

Two entries do most of the work:

- **Snapshot** — the whole world at one instant, fetched with a single
  `system.multicall` per tick. That is why the UI never makes three round trips.
- **Notice** — a queued event, delivered in the *next* snapshot rather than
  pushed. A handler may not emit from a worker thread, so push is not an option.
  `core/` owns the queue.

The phrase that keeps this honest: a notice is a transition noticed by diffing two
ticks. Nothing pushed it.

## Scheduling as a pure function

```lisp
(schedule/eval rules conditions now state) -> Effect
```

Pure. No I/O, no clock reads. That is what makes the scheduler testable against a
table of times instead of by waiting — a year of schedules can be asserted in
milliseconds.

Rules define recurring windows. Conditions override them. The effect is a
decision: set a preset, pause everything, stop seeding.

A `Preset` is a named `Limit` (`night` = 1 MiB/s), and a schedule always picks a
preset by name rather than hard-coding numbers.

## What is actually running

Fluxget finds `aria2c`, spawns it, speaks its JSON-RPC on loopback, and shows a
live queue.

The screenshot is not a mockup: a real window, the real dev server, the real
`bridge.Router`, a real child process, and a real 100% HTTP transfer.

Worth noting how the capability model works — a `Command` name *is* a capability
grant in `vails.json`, so there is no second list to keep in sync. An ungranted
command is refused with `forbidden:`.

## Where it stands

Phase 1 complete: the window opens, the bridge round-trips, and a real download
runs to completion. Phase 2 owns the design system and the multi-page frontend.
