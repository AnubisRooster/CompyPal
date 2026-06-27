# AI Companion App — Development Specification (On-Device Edition)

> **Audience:** Hand this directly to an AI coding agent (OpenCode/DeepSeek V4, Cursor, Claude Code). Locked decisions, phased build order, module specs, acceptance criteria. Build phases in order. At the end of each phase the app must run and the phase's Definition of Done must be met before starting the next.

> **Architecture in one line:** Everything runs on the iPhone. The only external dependency is the LLM provider (OpenRouter, BYOK, OpenAI-compatible). There is no backend server.

---

## 1. Product Overview

An iOS app of interactive AI companions. Each companion has:

- A stable **personality** driven by an LLM with a per-character system identity.
- A **realistic avatar** rendered on-device, whose appearance the user can alter on request — within a pre-built parametric space, optionally augmented by an identity-reference image (see §2 and §6).
- **Voice interaction** — speaks aloud (on-device TTS) and listens (on-device STT).
- **Persistent memory** of the user and relationship, in an embedded on-device graph, reusing the TherAIpist node/edge model.

The differentiator is depth of memory. Lean on the graph from Phase 1.

---

## 2. Architecture Boundaries (read first)

**On-device (everything except provider calls):** persona assembly, memory store + retrieval, conversation orchestration, avatar rendering, TTS, STT, all caching, model-selection policy.

**The external dependency — OpenRouter (BYOK):** the user supplies their own API key, stored in the iOS **Keychain**, entered in-app. The app calls OpenRouter directly; there is no server to proxy through. OpenRouter is used for: (a) LLM chat completions, (b) the lightweight memory-extraction call, (c) the model-catalog discovery endpoint, and (d) *optionally* identity-reference image generation. All four hit the same vendor and key, so OpenRouter remains the **single** external dependency.

**Accepted ceilings — do not silently work around these:**

- **Avatar render is parametric and on-device.** The live, animated, lip-syncing companion is a bundled mesh driven by morph targets + material swaps. Appearance changes map to that parametric space.
- **Image generation is identity-reference only, and optional.** When in scope (§6), it produces or edits a still likeness used as a *reference/texture*, using reference-image conditioning to keep the same character across edits. It fires occasionally (when a user redesigns their companion), never per turn.
- **Do NOT build real-time talking-head / live-portrait video.** Animating a generated 2D face into a live speaking avatar is out of scope. The animated avatar is always the parametric 3D mesh. A generated image informs the mesh's textures/appearance; it is not itself the live render.
- **Voice is on-device.** TTS is `AVSpeechSynthesizer`; per-companion distinctiveness is limited to the system voice catalog (voice, pitch, rate). Cloud/cloned voices are out of scope unless explicitly re-scoped.

If a feature seems to require crossing a ceiling, **stop and ask**.

---

## 3. Locked Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Language / UI | Swift 5.9+, SwiftUI | Min target iOS 17 |
| Avatar render | RealityKit + ARKit blend shapes | Bundled meshes; morph + material control |
| Audio | AVFoundation | Capture + playback |
| TTS | `AVSpeechSynthesizer` | On-device |
| STT | Apple `Speech` framework | On-device; `whisper.cpp` optional upgrade (Phase 4) |
| LLM / image transport | OpenRouter, OpenAI-compatible, SSE streaming | `https://openrouter.ai/api/v1` |
| Secrets | iOS Keychain | BYOK key entered in-app, never in a file |
| Embedded graph | SQLite via GRDB.swift (primary) | Kùzu acceptable if it builds clean for arm64 iOS |
| Local cache | App filesystem + `NSCache` | Meshes, audio, derived textures, **model catalog** |

**No backend. No Docker. No Neo4j server. No cloud TTS/STT/blob services. No local diffusion pipeline.**

---

## 4. Repository Structure

```
companion-app/
├── ios/
│   ├── Companion/
│   │   ├── App/              # entry, DI container, Keychain bootstrap
│   │   ├── Features/
│   │   │   ├── Chat/         # conversation UI + VM
│   │   │   ├── Avatar/       # RealityKit renderer, morph/material control
│   │   │   ├── Voice/        # TTS playback + STT capture
│   │   │   ├── Companions/   # list, create, customize
│   │   │   └── Settings/     # BYOK key, model mode (auto/pinned), "refresh models", cost view
│   │   ├── Core/
│   │   │   ├── LLM/
│   │   │   │   ├── Client/    # OpenRouter client (SSE chat, images), fallback rotation
│   │   │   │   ├── Catalog/   # fetch + cache + TTL refresh of the live model list
│   │   │   │   └── Selection/ # pure ranking policy (free-first, capability filters)
│   │   │   ├── Memory/        # embedded graph store + retrieval
│   │   │   ├── Persona/       # system-prompt assembly (pure, testable)
│   │   │   ├── Audio/         # AVFoundation wrappers
│   │   │   ├── Models/        # Codable domain types
│   │   │   └── Storage/       # file cache, Keychain wrapper
│   │   └── Resources/
│   │       └── Avatars/       # bundled GLB/USDZ base meshes + morph targets
│   └── CompanionTests/
├── tools/                     # BUILD-TIME ONLY, not in the app bundle
│   └── avatar-prep/
└── docs/
    └── SPEC.md
```

---

## 5. Memory Graph (embedded, on-device)

Reuse the TherAIpist node/edge model as SQLite tables via GRDB.

**Node tables:** `user`, `companion`, `personality_trait` (name, intensity 0–1), `appearance_attribute` (key, value), `memory` (id, content, kind ∈ {fact, preference, event, emotion}, salience, created_at, source_turn_id), `voice` (system_voice_id, pitch, rate), `conversation_turn` (id, role, text, created_at).

**Edge tables:** `has_companion`, `has_trait`, `has_appearance`, `uses_voice`, `has_memory` (about_companion nullable), `relationship_stage` (stage ∈ {acquaintance, friend, confidant}), `mentioned_in`.

**Retrieval:** before each LLM call, query top-N memories for this user+companion by salience and recency, optionally stage-filtered. Single SQL query in `Core/Memory/`. No raw SQL elsewhere.

**Appearance stored as structured attributes, never as a raw image.** If an identity-reference image exists (§6), store only a local file reference to the cached asset on the `companion`, derived from the attributes — not as the source of truth.

---

## 6. Model Selection, Cost & Dynamic Catalog

The product must never hardcode model IDs. Free tags and slugs on OpenRouter change frequently; a pinned slug will silently rot. Model choice is **resolved at runtime from the live catalog** against a cost-first policy, with user override.

### 6.1 Roles
Three model roles, each resolved independently:
- **chat** — the companion's conversational brain. Needs streaming; prefers tool/function-calling (for appearance-intent parsing in Phase 3).
- **extract** — the post-turn memory-extraction call. Needs reliable JSON output; can be a smaller/cheaper model than chat.
- **image** — optional identity-reference generation/editing (§2). Needs image output and **input-reference** support (to preserve the companion's identity across edits).

### 6.2 Dynamic catalog (`Core/LLM/Catalog`)
- Fetch the live list from OpenRouter's models discovery API (`GET /api/v1/models`, and the dedicated image-models endpoint for the `image` role).
- Parse per model: id, pricing (prompt/completion/image), input/output modalities, and `supported_parameters` (streaming, tools, input references).
- **Refresh cadence:** on app launch if the cache is older than a configurable TTL (default 12h); via a manual "Refresh models" button in Settings; and opportunistically when a call fails with "model not found." Refresh runs in the background — the app always boots from the cached catalog and never blocks on the network.
- **Offline:** fall back to the last-good cached catalog. If there is none (first run, no network), surface a clear "connect to fetch models" state.
- Persist the raw catalog + a derived ranked shortlist per role + a `last_refreshed` timestamp in local cache.

### 6.3 Selection policy (`Core/LLM/Selection`, pure & unit-tested)
Input: catalog + role + user preference. Output: an ordered candidate list.
1. **Filter** to models meeting the role's capability requirements (e.g. chat → streaming; image → image output + input references).
2. **Rank free-first:** models priced at $0 (free variants) sort above paid.
3. **Within a tier, cheapest-first** (sum of relevant per-token / per-image prices). Equivalent to OpenRouter's `:floor` routing intent.
4. **Apply a quality floor** so a free model that can't tool-call isn't selected for a tool-calling task — fall through to the cheapest capable paid model instead.
5. **User override:** Settings offers "Auto (recommended)" per role, or a pinned model picked from the live catalog.

### 6.4 Fallback rotation
`Core/LLM/Client` tries the top candidate; on 429 (free-tier rate limit), 5xx, or "model not found," it advances to the next candidate and marks the catalog stale to trigger a refresh. This directly absorbs free-tier limits (≈20 req/min, 50–1000 req/day) and weekly slug churn.

### 6.5 Cost posture
- Chat/extract default to free or `:floor`-cheap models; BYOK routing is free for the first 1M requests/month, then a small fee — so bringing the user's own provider key keeps routing near-zero.
- Image is the only routinely-paid modality and fires only on redesign, not per message. Default the `image` role to the cheapest reference-capable model; let the user opt into a higher-quality one.
- Voice is on-device and therefore $0 — it is not a model role.

### 6.6 Seed defaults (validated against the live catalog, never trusted blindly)
Ship a small seed list per role as a cold-start hint only (e.g. a current free general model for chat, a cheap small model for extract, the cheapest reference-capable image model). On first successful catalog fetch, the live data supersedes the seeds. Do not treat seeds as authoritative; verify every seed slug still exists in the fetched catalog before use.

---

## 7. Build Phases

### Phase 0 — Scaffold, BYOK & Catalog
SwiftUI skeleton. Settings screen to enter an OpenRouter key (Keychain). Implement `Core/LLM/Catalog` (fetch + cache + TTL) and `Core/LLM/Selection` (policy). A "Test connection" button that resolves the **chat** role from the live catalog and makes one non-streaming completion.

**DoD:** App builds; key persists in Keychain; catalog fetches and caches; "Test connection" uses an auto-selected (free-preferred) model from the live list and returns a real response. Selection policy has unit tests.

### Phase 1 — Text Companion with Memory
1. Create a companion (name + traits + appearance attributes).
2. Chat screen: stream replies via SSE using the resolved **chat** model, with fallback rotation on failure.
3. **Retrieval:** inject salient memories before each call.
4. **Persona assembly** (`Core/Persona/`): pure function, unit-tested.
5. **Memory extraction:** post-turn call on the resolved **extract** model, JSON-only, deduped before write.
6. **Relationship progression:** counter-based stage promotion; gate style on stage.

**DoD:** Multi-session conversation with correct recall. Two companions feel distinct. If the selected model is rate-limited or removed mid-session, fallback rotation keeps the chat working.

### Phase 2 — Voice & Avatar
1. **TTS:** `AVSpeechSynthesizer`, per-companion voice/pitch/rate.
2. **STT:** Apple `Speech`, transcript into the chat pipeline.
3. **Avatar:** bundled mesh in RealityKit; map `appearance_attribute` rows to materials + morph targets.
4. **Lip sync:** drive viseme blend shapes from `AVSpeechSynthesizer` timing callbacks.
5. **Expression:** map an emotional-state set to blend-shape presets.

**DoD:** Companion appears as a 3D avatar, speaks with roughly-synced lips, full voice loop works, no network call except OpenRouter.

### Phase 3 — Appearance Mutation (parametric, on-device)
1. **Intent parse:** detect appearance-change intent → structured delta via tool/JSON call.
2. **Validate against the parametric space.** In-space requests apply; out-of-space requests are declined in-character with the nearest supported alternative. Never fabricate generation.
3. **Apply delta:** update `appearance_attribute` rows; update materials/morphs live.
4. **Confirm in-character;** persist across sessions.

**DoD:** "Green eyes and a shorter cut" updates live and persists. Out-of-space requests handled gracefully.

### Phase 3.5 — Optional: Identity-Reference Image (gated by §2)
Only if enabled. When a user requests a look the parametric space can't represent:
1. Resolve the **image** model from the catalog (cheapest reference-capable).
2. Generate/edit a still likeness using the companion's existing reference image as an input reference, to preserve identity.
3. Cache the result locally; apply it to the mesh as a texture/reference where feasible; persist the file reference on the companion.
4. **Hard stop:** no talking-head video, no live-portrait animation. The animated render stays the parametric mesh.

**DoD:** A redesign request produces an identity-consistent reference image, applied/cached, with the live avatar still driven by the mesh. The feature is feature-flagged off by default.

### Phase 4 — Polish & Hardening
First-token latency < 1.5s. Offline state (everything but chat/image still works). Keychain edge cases, SSE reconnection, request cancellation. Optional `whisper.cpp` STT. Accessibility pass.

---

## 8. Provider Client Contract (`Core/LLM`)

Base URL `https://openrouter.ai/api/v1`; key from Keychain at call time.
- **Catalog:** `GET /models` (and the image-models discovery endpoint) → parse pricing, modalities, `supported_parameters`.
- **Chat (streaming):** `POST /chat/completions`, `stream: true`, SSE deltas → chat VM. Model = resolved **chat** candidate; rotate on failure.
- **Extract (non-streaming):** `POST /chat/completions`, JSON-only system prompt. Model = resolved **extract**.
- **Image (optional):** `POST /images` with `input_references` for identity preservation. Model = resolved **image**.

Never embed a key or a hardcoded model slug. Resolve models from the catalog; supply seed defaults only as cold-start hints that are re-validated against live data.

---

## 9. Coding Conventions

- SwiftUI + MVVM, one `ObservableObject` VM per feature.
- All provider traffic through a single client actor in `Core/LLM/Client`. No ad-hoc `URLSession` in views.
- All graph access through `Core/Memory`. No raw SQL elsewhere.
- Catalog parsing and selection policy are pure and unit-tested; no network code inside the policy.
- Everything `Codable`. No force-unwraps in production paths.
- Cache meshes/textures/audio/catalog via `NSCache` + disk, keyed by content hash / role.
- Secrets only from Keychain. No runtime secret files ship.
- Priority test units: persona assembly, memory dedup, appearance-delta validation, **selection policy**, **catalog cache/TTL**.

---

## 10. First Tasks for the Agent

1. Generate the `ios/` structure in §4.
2. Implement Phase 0 end to end: Keychain BYOK + catalog fetch/cache + selection policy + a test call on an auto-selected free model.
3. Stop and report. Do not begin Phase 1 until Phase 0's DoD is verified.

When a model ID, slug, framework API (GRDB, RealityKit morph targets, `AVSpeechSynthesizer` callbacks), or the exact OpenRouter request/response shape is uncertain, check current official docs before writing it. Never hardcode a model slug.
