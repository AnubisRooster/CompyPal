# AGENTS.md — AI Companion App

This is the operating manual for any AI coding agent working in this repo. The full technical specification lives in `docs/SPEC.md` and is the source of truth. This file tells you **how to behave**; the SPEC tells you **what to build**.

## The one rule that matters most

**Build in phases, in order. Stop at every phase gate.** The SPEC defines Phases 0–4, each with a Definition of Done. Do not start a phase until the previous phase is runnable and its Definition of Done is verified. When you finish a phase, stop and report — do not roll into the next phase on your own.

This matters specifically because you will be tempted to scaffold everything at once. Don't. A running Phase 0 beats a half-built Phase 3.

## Project in one paragraph

iOS app of interactive AI companions. Each companion has a persistent personality (LLM-driven), a realistic avatar whose appearance the user can change by request, voice interaction, and long-term memory backed by a Neo4j knowledge graph. The memory depth is the differentiator — lean on the graph from Phase 1.

## Stack (do not substitute without asking)

- **iOS:** Swift 5.9+, SwiftUI, RealityKit + ARKit, AVFoundation. Min target iOS 17.
- **Backend:** Python 3.11, FastAPI, async throughout, WebSocket for conversational streaming.
- **Graph:** Neo4j 5.x. All Cypher lives in `backend/app/graph/` — never in route handlers.
- **Runtime LLM (the companion's brain):** Anthropic Claude via the official SDK. This is separate from the model running *you* (the coding agent). Don't conflate them.
- **TTS:** ElevenLabs. **STT:** Apple `Speech` on-device, Whisper fallback. **Avatar:** Ready Player Me.

## Commands

```bash
# Infra (Neo4j + backend)
docker-compose up -d

# Backend
cd backend && uv sync           # or: pip install -e .
uvicorn app.main:app --reload   # serves on :8000
pytest                          # run tests

# Regenerate Xcode project (after changing project.yml)
cd ios && xcodegen generate

# iOS — open ios/Companion.xcodeproj in Xcode, or:
cd ios && xcodebuild -scheme Companion -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Code conventions

**Python**
- Type hints everywhere. Pydantic v2 for all request/response models.
- Services are stateless and dependency-injected. Never instantiate API clients inside route handlers.
- All Neo4j access goes through `backend/app/graph/`. No raw Cypher elsewhere.
- Async I/O throughout. Pool the Neo4j driver.

**Swift**
- SwiftUI + MVVM, one `ObservableObject` view model per feature.
- All networking through a single `APIClient` actor. No ad-hoc `URLSession` calls in views.
- Everything `Codable`. No force-unwraps in production paths.
- Cache meshes/textures/audio via `NSCache` with disk fallback, keyed by content hash.

**Both**
- Keep DTOs in sync between `backend/app/models` (Pydantic) and `ios/.../Core/Models` (Codable). If you change one, change the other in the same commit.
- Write tests for core logic as you go. Priority units: persona assembly, memory dedup, appearance-delta application.

## Hard don'ts

- **Don't hardcode secrets.** Everything comes from env. Keep `.env.example` complete with blank values.
- **Don't invent model IDs, SDK method names, or external API parameters.** The ElevenLabs, Ready Player Me, Anthropic, and Neo4j APIs change. When you're unsure of a parameter or model string, check current official docs before writing it. A confident wrong API call costs more than a lookup.
- **Don't store appearance as raw images.** Appearance is structured attributes in the graph; images/meshes are derived artifacts cached by attribute hash. This keeps partial updates ("change only the hair") tractable.
- **Don't skip the retrieval step.** Before every companion LLM call, query the graph for salient memories and inject them. That's the product.

## Notes on you, the agent (DeepSeek V4)

You're strong at agentic coding and tool calling. Two tendencies to manage: you retry and self-correct aggressively, which can balloon tool calls — when a step is genuinely blocked (missing credential, ambiguous SPEC point), stop and ask rather than thrashing. And you're verbose in thinking mode — keep reasoning proportional to the task. For routine edits, lighter is fine.
