---
title: blip
summary: A Lisp dialect in V where ordinary programs need no macros, and which borrows one idea each from Racket and Gleam.
problem: >-
  Lisp asks you to write macros for things other languages treat as syntax. That
  is a real ergonomic win and a real cost: programs stop being readable without
  knowing which forms are macros. So the question was whether the readability
  comes from macros or from what the language already does — and, if it does
  not have to be macros, which three modern additions are worth having without
  inheriting a whole language's baggage to get them.
order: 0
status: in-progress
featured: true
stack:
  - V
  - Lisp
  - CEK machine
  - Tail calls
demo: https://metif12.github.io/blip
repo: https://github.com/metif12/blip
started: 2026-10-03
tags:
  - languages
  - interpreters
---

A Lisp dialect implemented in V, designed so that ordinary programs are written
**without macros** — while macros remain available for the cases that genuinely
need them.

## The bet: you should not need macros

Most Lisps ask you to write macros for things other languages treat as syntax. That
is a real ergonomic win. It is also a real cost — the program stops being readable
unless you already know which forms are macros.

So blip tries a different arrangement. Take the ergonomics that modern Lisps
worked for, and provide them as language features instead:

| | From | What it removes |
| --- | --- | --- |
| `match*` | Racket | Nesting one `match` inside another to compare two values |
| `use` | Gleam | The staircase indentation of callback chains |
| Opaque types | Gleam | Encapsulation without classes, interfaces or inheritance |

Because these are forms the reader knows, a program reads the same to someone who
has never run it. No macroexpansion required.

## Tail calls are structural, not a flag

Execution is a CEK-style machine with an explicit continuation stack. That buys
proper tail calls today and fibers later, without redesigning the evaluator.

The test suite prints the stack depth at the end of every run:

```text
ok   self tail call 250k => 250000   (steps=7000020, kont=0)
ok   mutual tail call 2e4 => pong    (steps=400020,  kont=0)
ok   tail in cond 1e5 => 100000      (steps=2900021, kont=0)
ok   non-tail fib => 6765            (steps=503488,  kont=0)
```

A quarter-million tail calls, and the stack ends at zero. The frame in tail
position gets reused rather than pushed, so a loop stays a loop.

`tests/non_tail.v` exists for the opposite reason. The bug where a call that
should have been a tail call pushes a frame instead is easy to write and invisible
until the program runs out of memory.

## The reader is where the language actually lives

`let*` does not work yet, and the reason is more interesting than a missing
feature.

In most Lisps `[...]` is unambiguous: a binding group in form position, a vector
in value position. blip wants `[...]` to be *both*, so a binding form and its
initialisers read the same way.

That only works if the reader knows which reading applies before it has finished
reading — and it does not yet. So `let*` is blocked on the reader, not on the
evaluator. `docs/010-roadmap.md` names what else is missing: rest parameters and
callable keywords.

## Four findings from building the value representation

The `Value` type is shaped the way it is because of four things found along the
way. Three of them are limits of the language rather than design choices, and all
four are verified by programs in `src/`.

### A boxed sum type cannot hold a pair

```v
struct cons_v { head int
               tail Lst }
// error: invalid recursive struct `cons_v`
```

A cons cell is recursive by definition, so the representation V would hand over
for free would need an extra allocation *on top of* the boxing.

### A sum-type field cannot be set from a local

Not in a loop, not in recursion — `v := cons_v{head: x}` errors with `x evaluated
but not used`, while the identical plain struct compiles and runs.

That looks like a checker bug, and it is worth reporting upstream. Either way it
rules the representation out today.

### A `voidptr` field is not a GC root

This was the original design, and it silently corrupted programs. The probe builds
a 2,000,000-cell cons chain, churns the heap, then walks it — and **25 cells
survived**.

V derives GC roots from *typed* fields, and a `voidptr` does not say what it
points at. The fix was to make the payload a typed reference. The same probe then
reported 2,000,000 / 2,000,000 with a correct sum.

### A method-less marker interface holding a struct is broken

It compiles cleanly, then dies with `invalid memory access` in both dev and
`-prod`. Adding one method fixes it.

Worth remembering anywhere an interface is used as a tagged union: a construct
that builds without complaint and corrupts memory at runtime deserves more than a
footnote.

## Where it stands

Milestone M3. The reader parses all six example programs, and the machine
evaluates closures, arithmetic, branching, `loop`, `dotimes`, `letrec`, `cond` and
`case`. The tail-call suite is 17 tests and passes. Embedding and the REPL are
next.

There is no static type system in v1. Type information exists as optional, erased
annotations plus runtime contracts, and both are opt-in per program.

The site in the header is generated by blip itself, in sixteen languages.
