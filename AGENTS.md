# AGENTS.md — AI Companion App

This is the operating manual for any AI coding agent working in this repo. The full technical specification lives in `docs/SPEC.md` and is the source of truth. This file tells you **how to behave**; the SPEC tells you **what to build**.

## The one rule that matters most

**Build in phases, in order. Stop at every phase gate.** The SPEC defines Phases 0–4, each with a Definition of Done. Do not start a phase until the previous phase is runnable and its Definition of Done is verified. When you finish a phase, stop and report — do not roll into the next phase on your own.

This matters specifically because you will be tempted to scaffold everything at once. Don't. A running Phase 0 beats a half-built Phase 3.

## Project in one paragraph

iOS app of interactive AI companions. Everything runs on-device — the only external dependency is OpenRouter (the user brings their own API key). Each companion has an LLM-driven personality, a 3D parametric avatar in RealityKit, voice interaction via AVFoundation, and long-term memory in an embedded GRDB.swift (SQLite) graph. The memory depth is the differentiator — lean on the graph from Phase 1.

## Stack (do not substitute without asking)

- **iOS:** Swift 5.9+, SwiftUI, RealityKit + ARKit, AVFoundation. Min target iOS 17.
- **LLM provider:** OpenRouter (BYOK), OpenAI-compatible API, SSE streaming.
- **Graph:** SQLite via GRDB.swift. All queries live in `Core/Memory/` — never in view models.
- **Runtime LLM (the companion's brain):** Resolved from the live OpenRouter catalog by a cost-first selection policy, not hardcoded.
- **TTS:** AVSpeechSynthesizer (on-device). **STT:** Apple `Speech` framework (on-device, whisper.cpp optional Phase 4).
- **Avatar:** Bundled parametric meshes in RealityKit, driven by morph targets + material swaps.

## Commands

```bash
# Regenerate Xcode project (after changing project.yml)
cd ios && xcodegen generate

# iOS — open ios/Companion.xcodeproj in Xcode, or:
cd ios && xcodebuild -scheme Companion -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
cd ios && xcodebuild test -scheme Companion -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Code conventions

**Swift**
- SwiftUI + MVVM, one `ObservableObject` view model per feature.
- All provider traffic through `Core/LLM/Client/OpenRouterClient` actor. No ad-hoc `URLSession` calls in views.
- All graph access through `Core/Memory/`. No raw SQL outside that directory.
- Everything `Codable`. No force-unwraps in production paths.
- Cache meshes/textures/audio/catalog via `NSCache` + disk, keyed by content hash / role.
- Catalog parsing and selection policy are pure and unit-tested; no network code inside the policy.

## Hard don'ts

- **Don't hardcode secrets.** API key comes from the iOS Keychain, entered in-app. No .env files, no plist secrets.
- **Don't hardcode model IDs.** Resolve from the live catalog at runtime. Ship seed defaults only as cold-start hints that are re-validated against the fetched catalog.
- **Don't invent model IDs, SDK method names, or external API parameters.** When unsure of an OpenRouter API shape or a framework API, check current official docs.
- **Don't store appearance as raw images.** Appearance is structured attributes in the graph; images/meshes are derived artifacts cached by attribute hash.
- **Don't skip the retrieval step.** Before every companion LLM call, query the graph for salient memories and inject them. That's the product.
- **Don't build a backend server.** The app has no backend — everything runs on the iPhone.

## Notes on you, the agent (DeepSeek V4)

You're strong at agentic coding and tool calling. Two tendencies to manage: you retry and self-correct aggressively, which can balloon tool calls — when a step is genuinely blocked (missing credential, ambiguous SPEC point), stop and ask rather than thrashing. And you're verbose in thinking mode — keep reasoning proportional to the task. For routine edits, lighter is fine.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **CompyPal**.

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact before editing.** Use `impact({target: "symbolName", direction: "upstream"})` or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .`; report callers, processes, and risk. Never substitute grep for graph analysis.
- **MUST analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "main"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "main" --repo .`.
- MUST warn on HIGH/CRITICAL `risk` pre-edit; never use `riskSharedAxes` to waive a HIGH/CRITICAL `risk` warning. Compare File/symbol: MCP File omits axes; Graph-RAG expands File.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- **MUST use `query({search_query: "concept"})` for concepts/flows, `context({name: "symbolName"})` for a named symbol, or `impact` for blast radius, on read-only callers, dependencies, imports, or execution flow.** Graph first; text search only for empty/`UNKNOWN`/literals.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/CompyPal/context` | Codebase overview, check index freshness |
| `gitnexus://repo/CompyPal/clusters` | All functional areas |
| `gitnexus://repo/CompyPal/processes` | All execution flows |
| `gitnexus://repo/CompyPal/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
