# MoonBit Ecosystem Overlap Notes

Date: 2026-06-14

This document records an initial ecosystem research pass for `moonsim`. The
goal is to avoid direct duplication of mature MoonBit ecosystem projects and to
select a topic with clear reuse value, manageable implementation scope, and
strong differentiation.

## Project Criteria

The project should contribute to the MoonBit open-source ecosystem. It should have a clear function, real usage scenarios, and reusable value.

A project must not directly migrate or duplicate a mature existing MoonBit project with highly overlapping functionality. If it builds on an existing direction, the added value and independent contribution must be clearly stated.

## Research Method

Search sources used in this round:

- GitHub repository search through GitHub MCP
- GitHub code search through GitHub MCP
- Known MoonBit ecosystem organizations such as `moonbitlang` and `moonbit-community`

Search topics:

- Markdown to HTML
- Template engine
- Graph algorithms and pathfinding
- Benchmark / stopwatch
- Logging / tracing
- Protobuf / serialization
- Actor framework
- Deterministic simulation
- IndexMap / BitSet / collection utilities
- Build tool / n2 / ninja-like tool
- Register allocation

This is not a final exhaustive audit. A second pass should be run before finalizing the topic and again before public release.

## Findings

### Markdown To HTML

Representative projects found:

- `mizchi/markdown.mbt`: CST-based incremental Markdown parser for JavaScript/MoonBit. Supports JS/WASM/native, incremental parsing, GFM, HTML rendering, mdast compatibility, and a frontend editor package. README says CommonMark compatibility is partial but the project is mature and clearly positioned.
- `oilleelssq-wq/moonmarkdown`: pure MoonBit Markdown to HTML parser targeting CommonMark compliance. README explicitly positions it against `@mizchi/markdown` and `Cmark.mbt`.
- `moonbit-community/cmark.mbt`: referenced by `mizchi/markdown.mbt` as a fully compliant parser option through C FFI.
- Other Markdown-related projects appeared in code search, including renderers, editors, and Markdown helpers.

Collision risk: High.

Recommendation: Do not build another plain Markdown-to-HTML parser. A differentiated adjacent project could be a static documentation site generator, Markdown conformance tester, Markdown AST visualization/debugger, or MoonBit-doc-specific publishing tool, but not a general Markdown parser.

### Template Engine

Representative projects found:

- `robinfang/mold`: lightweight template engine for MoonBit, published on mooncakes.io as version `0.3.0`. It has variables, filters, conditionals, loops, includes, autoescape, JSON input, structured errors, inspection, examples, docs, and a live WASM playground.
- `justjavac/moonbit-template`: precompiled template engine with code generation, filters, includes, examples, and coverage badges.
- `moonbit-community/pug-mbt`: Pug template engine implementation in MoonBit with nesting, attributes, interpolation, compile API, and pretty printing.
- `robinfang/mold-live`: in-browser playground for `mold`.

Collision risk: High.

Recommendation: Do not build a general template engine. A safe adjacent angle would need to be very specific, such as template migration tooling, template linting, visual debugging, or integration around an existing template engine. This direction is no longer ideal unless we define a sharply different contribution.

### Graph Algorithms / Pathfinding

Representative projects found:

- `I3eg1nner/moonbit-petgraph`: MoonBit port of Rust `petgraph`, with graph data structures, DFS/BFS, Dijkstra, A*, Bellman-Ford, topological sort, cycle detection, SCC, MST, DOT export, tests, CI, design docs, and package installation instructions.
- `NoEmotionYY/moon-pathplanning`: reusable path planning library for grid search, graph primitives, examples, tests, CLI demos, SVG output, BFS/DFS/Dijkstra/A*/bidirectional A*, heuristics, JSON examples, and roadmap.
- Smaller pathfinding examples also appeared in code search.

Collision risk: High.

Recommendation: Do not build a general graph algorithm library or grid pathfinding library. This area already has strong direct overlap with recommended topics.

### Collections: IndexMap / BitSet / BitMask

Representative projects found:

- `Zongzuixi114514/MoonCollections`: data structure library providing IndexMap, OrderedSet, BitSet, BloomFilter, LRUCache, UnionFind, and CountMap.

Collision risk: Medium to High.

Recommendation: Avoid a generic collections project unless it targets a narrower and demonstrably missing data structure family, with stronger benchmarks and formal/proof-oriented value.

### Logging / Tracing

Representative projects found:

- `brickfrog/moontrace`: structured tracing library for MoonBit inspired by Rust `tracing`, with spans, structured fields, subscribers, console/JSON output, OTLP export, async span wrappers, file subscriber, sampling, redaction, flamegraph export, and documentation.
- `moonbit-community/opentelemetry.mbt`: OpenTelemetry implementation for MoonBit covering traces, metrics, logs, context, baggage, propagation, SDK providers, exporters, OTLP models, and semantic conventions.
- Additional OpenTelemetry-related personal repositories appeared in code search.

Collision risk: High for logging/tracing.

Recommendation: Do not build a logging + tracing library. A possible adjacent project could be an integration plugin or visualization tool, but a core tracing library would directly overlap with mature work.

### Protobuf / Serialization

Representative projects found:

- `moonbitlang/protoc-gen-mbt`: protobuf-related generated code and runtime pieces appeared in search results.
- `moonbit-community/opentelemetry.mbt`: includes generated OTLP protocol model types and protobuf-related code paths.
- Multiple code generation and protocol projects emit or consume protobuf-like data.

Collision risk: Medium to High.

Recommendation: A full protobuf implementation is risky and may overlap existing official/community work. A smaller serialization format could be possible, but it needs a very clear independent niche.

### Benchmark / Stopwatch

Representative projects found:

- No obvious mature standalone MoonBit benchmark harness or stopwatch library was found in repository search.
- Code search mostly returned benchmark scripts embedded inside unrelated projects, not reusable benchmark infrastructure.

Collision risk: Low.

Risk: The project may be too small if implemented only as a stopwatch helper.

Possible differentiation:

- Criterion-like benchmark runner for MoonBit
- Warmup, sample collection, statistics, percentile reports
- Baseline comparison and regression detection
- Markdown/JSON/HTML report output
- Multi-target runner notes for native/js/wasm where feasible
- Example benchmark suites for collections, parsers, and algorithms

Recommendation: Promising as a secondary option, but must be expanded beyond a stopwatch into a full benchmark harness to provide enough reusable value.

### Deterministic Simulation

Representative projects found:

- No mature generic deterministic simulation framework was found in repository search.
- Code search found domain-specific simulations inside games, EtherCAT, and other projects, but not a reusable simulation kernel.

Collision risk: Low.

Possible differentiation:

- Generic virtual-time scheduler
- Seeded deterministic RNG
- Event queue and deterministic ordering
- Scenario runner
- Trace recording and replay
- Snapshot/checkpoint support
- Model-test helpers for algorithms, queues, protocols, games, or distributed systems
- CLI demo runner and report generator

Recommendation: Strong candidate. It has enough natural scope, avoids obvious direct overlap, and can demonstrate real reuse through examples.

### Build Tool Similar To n2 / ninja

Representative projects found:

- No obvious MoonBit n2/ninja-like build tool was found.

Collision risk: Low.

Risk: Harder engineering surface. Requires filesystem handling, process execution, dependency graph parsing, incremental rebuild semantics, CLI ergonomics, and cross-platform behavior. Scope could easily exceed a focused library milestone.

Recommendation: Interesting but higher risk than deterministic simulation.

### Register Allocation / Compiler Infrastructure

Representative projects found:

- Register allocation code appears inside compiler or VM projects such as `Milky2018/wasmoon`, `yjl9903/minimoonbit-moca`, and teaching compiler repositories.
- These are embedded implementations, not necessarily reusable standalone libraries.

Collision risk: Medium.

Risk: High implementation complexity and harder demo story unless the project is carefully framed as a reusable teaching/verification library.

Recommendation: Possible if the goal is a compiler-focused entry, but not the best default choice.

## Comparison Summary

| Rank | Direction | Collision Risk | Implementation Risk | Reuse Value | Recommendation |
| --- | --- | --- | --- | --- | --- |
| 1 | Deterministic simulation framework | Low | Medium | High | Best candidate |
| 2 | Benchmark harness | Low | Medium | Medium | Good backup, must expand scope |
| 3 | Build tool | Low | High | High | Interesting but risky |
| 4 | Register allocation library | Medium | High | Medium | Only if compiler-focused |
| 5 | Protobuf/serialization | Medium-High | High | High | Risky overlap and complexity |
| 6 | Collections | Medium-High | Medium | Medium | Existing overlap |
| 7 | Graph/pathfinding | High | Medium | High | Avoid direct overlap |
| 8 | Template engine | High | Medium | High | Avoid direct overlap |
| 9 | Markdown parser | High | Medium | High | Avoid direct overlap |
| 10 | Logging/tracing | High | High | High | Avoid direct overlap |

## Recommended Topic

Working title: `moonsim`

A deterministic simulation and replay framework for MoonBit.

### Core Problem

MoonBit projects need a reusable way to model systems that evolve over time while remaining reproducible. Examples include games, path planners, queueing systems, distributed protocols, schedulers, retry logic, and teaching demos.

### Core Value

`moonsim` would provide a small deterministic runtime kernel rather than a domain-specific simulator:

- virtual clock instead of wall-clock time
- deterministic event scheduling
- stable ordering for same-tick events
- seeded RNG
- trace recording
- replay verification
- snapshot/checkpoint support
- scenario runner and examples

### Why It Avoids Duplication

Existing search results show domain-specific simulation code, but no generic MoonBit simulation framework. The project is not another Markdown parser, template engine, graph library, pathfinder, tracing library, or collection package.

### Expected Modules

- `core`: simulation time, tick, event id, deterministic ordering
- `rng`: seedable deterministic RNG and distributions
- `scheduler`: event queue, delayed events, repeating events, cancellation
- `trace`: event log, replay log, deterministic digest
- `scenario`: test harness for scripted simulation scenarios
- `snapshot`: lightweight checkpoint/restore model
- `metrics`: counters, gauges, histograms for simulation output
- `examples`: queue simulation, traffic light, retry/backoff, game loop, small protocol model
- `cmd`: CLI runner for examples and trace comparison

### Differentiation

If another project also chooses deterministic simulation, `moonsim` should stand out through:

- replayable traces and deterministic digests
- clear library API plus CLI scenario runner
- multiple real examples, not just a toy loop
- strong tests for event ordering, cancellation, RNG reproducibility, replay, and snapshot behavior
- documentation explaining how to use it for games, protocols, and algorithm experiments

## Next Steps

1. Confirm the topic: `moonsim` deterministic simulation framework.
2. Create a design document with API shape, module boundaries, and non-goals.
3. Initialize a MoonBit project skeleton.
4. Implement the minimal deterministic kernel first: virtual time, event queue, seeded RNG, and trace log.
5. Add tests from day one.
6. Add examples and CLI after the kernel is stable.
7. Run a second ecosystem check before public release.
