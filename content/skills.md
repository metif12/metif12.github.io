- domain: Frontend
  blurb: >-
    I build interfaces where the hard part is state, not layout. Server
    rendering, data fetching and the accessibility details that separate a demo
    from something a real user depends on.
  skills:
    - name: React
      note: Component design and the rendering model, including SSR and hydration.
    - name: TypeScript
      note: strict mode, no exceptions. Types as a design tool, not a lint pass.
    - name: TanStack Router
      note: Type-safe routing, loaders, search params and SSR integration.
    - name: TanStack Query
      note: Server state, caching and invalidation — the only client state layer I reach for.
    - name: Tailwind CSS
      note: Design tokens in CSS variables, then utility classes over them.
    - name: shadcn/ui
      note: Owning the component source rather than importing a black box.
    - name: Accessibility
      note: Semantic HTML first, focus management, labels tied to inputs.
  proof:
    - personal-site
    - fluxget

- domain: Backend
  blurb: >-
    Services that stay up: bounded lifecycles, real error paths, and the
    discipline to write the awkward tests instead of the flattering ones.
  skills:
    - name: Go
      note: Goroutines, context cancellation, and HTTP servers that shut down cleanly.
    - name: Node.js
      note: Server functions, streaming responses, deployment to an edge runtime.
    - name: API design
      note: Idempotency, versioning, and errors a client can actually act on.
    - name: JSON-RPC
      note: "aria2's engine boundary — batching calls so one poll is one request."
    - name: MCP
      note: "Model Context Protocol servers in Go: tools, schemas, stdio and streamable HTTP."
    - name: Language implementation
      note: >-
        Readers, printers and evaluators. vlip: a CEK machine with an explicit
        continuation stack, so tail calls reuse the frame instead of pushing it —
        a quarter-million of them finish at depth zero.
    - name: Testing
      note: Tests on the failure paths and on money, not on snapshot sprawl.
  proof:
    - personal-site
    - fluxget
    - vlip

- domain: Infrastructure
  blurb: >-
    Enough of the deployment story to reason about what runs where, and to keep
    the boundary between a platform and a framework machine-checked.
  skills:
    - name: Cloudflare Workers
      note: Edge runtime, Vite plugin, and what having no filesystem forces you to rethink.
    - name: Vite
      note: Plugins, build-time globbing, and environment config.
    - name: Git
      note: Submodules, lock files, and a sync script that rolls back on a red gate.
    - name: CI
      note: Typecheck, lint and tests blocking a deploy.
    - name: Observability
      note: Structured logs and the errors worth alerting on.
  proof:
    - personal-site
    - fluxget

- domain: Systems and architecture
  blurb: >-
    I care most about the seams: where one thing stops being able to depend on
    another, and how you make that boundary hold over time.
  skills:
    - name: Boundary design
      note: A platform seam enforced by a script, not by convention.
    - name: Dependency isolation
      note: A framework pinned to a verified revision, with automatic rollback.
    - name: Domain modelling
      note: Ubiquitous language written down before the UI exists, and kept honest.
    - name: Decision records
      note: ADRs for the choice and the reasoning, not the task list.
    - name: Pure functions
      note: "Scheduling as `(rules, conditions, now, state) -> Effect` so it is testable."
  proof:
    - fluxget

- domain: Learning in public
  blurb: >-
    I keep working notes on the things that surprised me. Most of what I know
    about a tool came from being wrong about it first.
  skills:
    - name: V
      note: >-
        Forty-eight merged pull requests into the compiler: `v mcp`, a Model
        Context Protocol server built on V's own parser; `v clean`, `v mod why`,
        `v tool`, `v env`; a JSON5 parser and an experimental gRPC client.
        Writing a Lisp dialect in it turned up four language limits worth
        reporting upstream.
    - name: Writing
      note: Notes and essays, mostly about the edges of tools.
  proof:
    - vlip
