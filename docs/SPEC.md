# AI Companion App — Development Specification

> **Audience:** This document is written to be handed directly to an AI coding agent (Cursor, OpenCode, Claude Code). It contains locked technical decisions, a phased build order, module-level specs, and acceptance criteria. Build phases in order. Do not skip ahead. At the end of each phase, the app must be runnable and the phase's Definition of Done must be met before starting the next.

---

## 1. Product Overview

We are building an iOS app of interactive AI companions. Each companion has:

- A stable **personality** driven by an LLM with a per-character system identity.
- A **realistic graphical appearance** that the user can alter on request ("give her shorter hair", "make his eyes blue").
- **Voice interaction** — the companion speaks aloud and listens to the user.
- **Persistent memory** of the user and the relationship, backed by a knowledge graph (Neo4j), reusing the schema and patterns from our existing TherAIpist app.

The differentiator is depth of memory. Most competitors have shallow recall. We lean hard on the knowledge graph from day one.

---

## 2. Locked Tech Stack

Do not substitute these without explicit approval.

| Layer | Choice | Notes |
|---|---|---|
| iOS language/UI | Swift 5.9+, SwiftUI | Min target iOS 17 |
| 3D avatar render | RealityKit + ARKit blend shapes | Phase 2 onward |
| Audio | AVFoundation | Playback + capture |
| On-device STT | Apple `Speech` framework | Primary |
| Fallback STT | Whisper (API) | Noisy input only |
| Backend | Python 3.11 + FastAPI | Async |
| Realtime transport | WebSocket | Conversational streaming |
| LLM | Anthropic Claude (official SDK) | Confirm current model IDs at build time; do not hardcode a model string you cannot verify |
| TTS | ElevenLabs | Per-companion voice ID |
| Avatar mesh | Ready Player Me API | Parameterized attributes |
| Image generation | FLUX.1 / SDXL + ControlNet | Phase 3, appearance mutation |
| Graph DB | Neo4j 5.x | Same patterns as TherAIpist |
| Object/blob store | S3-compatible | Cache meshes, audio, images |
| Auth | JWT (access + refresh) | Apple Sign-In on client |

**Secrets** (never commit; load from env): `ANTHROPIC_API_KEY`, `ELEVENLABS_API_KEY`, `READYPLAYERME_*`, `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD`, `JWT_SECRET`, `S3_*`, `OPENAI_API_KEY` (Whisper fallback only).

---

## 3. Repository Structure

Scaffold a monorepo:

```
companion-app/
├── ios/                        # Xcode project (SwiftUI)
│   ├── Companion/
│   │   ├── App/                # App entry, DI container
│   │   ├── Features/
│   │   │   ├── Chat/           # Conversation UI + VM
│   │   │   ├── Avatar/         # RealityKit renderer
│   │   │   ├── Voice/          # Record + playback
│   │   │   └── Companions/     # List, create, customize
│   │   ├── Core/
│   │   │   ├── Networking/     # API + WebSocket client
│   │   │   ├── Audio/          # AVFoundation wrappers
│   │   │   ├── Models/         # Codable DTOs
│   │   │   └── Storage/        # Local cache (NSCache + disk)
│   │   └── Resources/
│   └── CompanionTests/
├── backend/                    # FastAPI service
│   ├── app/
│   │   ├── main.py
│   │   ├── api/                # Route handlers
│   │   ├── services/           # LLM, TTS, STT, avatar, graph
│   │   ├── graph/              # Neo4j queries + schema
│   │   ├── models/             # Pydantic schemas
│   │   ├── ws/                 # WebSocket handlers
│   │   └── config.py
│   ├── tests/
│   └── pyproject.toml
├── docs/
│   └── SPEC.md                 # this file
└── docker-compose.yml          # Neo4j + backend for local dev
```

---

## 4. Knowledge Graph Schema (Neo4j)

Reuse TherAIpist conventions. Core node and relationship model:

**Nodes**
- `User` — `{id, display_name, created_at}`
- `Companion` — `{id, name, created_at}`
- `PersonalityTrait` — `{name, intensity}` (e.g. `dry_humor`, intensity 0–1)
- `AppearanceAttribute` — `{key, value}` (e.g. `key:"hair_color", value:"auburn"}`)
- `Memory` — `{id, content, kind, salience, created_at, source_turn_id}` where `kind ∈ {fact, preference, event, emotion}`
- `Voice` — `{provider, voice_id, settings}`
- `ConversationTurn` — `{id, role, text, created_at}`

**Relationships**
- `(:User)-[:HAS_COMPANION]->(:Companion)`
- `(:Companion)-[:HAS_TRAIT]->(:PersonalityTrait)`
- `(:Companion)-[:HAS_APPEARANCE]->(:AppearanceAttribute)`
- `(:Companion)-[:USES_VOICE]->(:Voice)`
- `(:User)-[:HAS_MEMORY {about_companion: <id?>}]->(:Memory)`
- `(:Companion)-[:RELATIONSHIP_STAGE {stage}]->(:User)` — stage ∈ `{acquaintance, friend, confidant}`
- `(:Memory)-[:MENTIONED_IN]->(:ConversationTurn)`

**Design rule:** Appearance is stored as **structured attributes**, never as a raw image. Images/meshes are derived artifacts cached in S3, keyed by a hash of the attribute set. This makes partial updates ("change only the hair") tractable.

---

## 5. Build Phases

### Phase 0 — Scaffold & Plumbing
Set up the repo structure, `docker-compose` with Neo4j, FastAPI skeleton with health check, and an empty SwiftUI app that authenticates via Apple Sign-In and hits `/health`.

**Definition of Done:** `docker-compose up` runs Neo4j + backend; iOS app builds, signs in, and shows a green "connected" state.

---

### Phase 1 — Text Companion with Memory
The core differentiator. No voice, no avatar yet — just a strong, persistent personality.

1. `POST /companions` — create a companion with name + initial traits. Writes `Companion`, `PersonalityTrait` nodes.
2. `POST /companions/{id}/chat` (WebSocket preferred) — send user message, stream back the companion's reply.
3. **Retrieval step:** before each LLM call, query the graph for the N most salient `Memory` nodes for this user+companion and inject them into the system context.
4. **Personality system prompt:** assemble from the companion's traits + appearance + relationship stage. Keep this assembly in `services/persona.py` as a pure function so it's testable.
5. **Memory extraction:** after each turn, run a lightweight LLM pass to extract new facts/preferences/events and write `Memory` nodes with a `salience` score. Deduplicate against existing memories.
6. **Relationship progression:** increment a counter; promote `acquaintance → friend → confidant` at thresholds. Gate certain response styles on stage in the system prompt.

**Definition of Done:** A user can create a companion, hold a multi-session conversation, and the companion correctly recalls facts from earlier sessions. Personality is consistent and distinct between two differently-configured companions.

---

### Phase 2 — Voice & Avatar
Add presence.

1. **TTS:** `services/tts.py` wraps ElevenLabs. Each companion gets a `Voice` node. Stream audio back to the client in chunks; play via `AVPlayer` as chunks arrive to minimize latency.
2. **STT:** iOS uses Apple `Speech` for on-device transcription. Send transcript text (not audio) to the backend for normal cases. Whisper fallback only when on-device confidence is low.
3. **3D Avatar:** integrate Ready Player Me. Render the mesh in RealityKit. Map companion `AppearanceAttribute` nodes to Ready Player Me avatar parameters.
4. **Lip sync:** drive ARKit blend shapes (visemes) from the TTS audio waveform in real time, or use OVRLipSync. Sync to playback clock.
5. **Expression:** map the companion's current emotional state (from the LLM response metadata) to a small set of facial blend-shape presets.

**Definition of Done:** The companion appears as a 3D avatar, speaks its replies aloud with lip movement roughly synced to audio, and the user can talk to it by voice end to end.

---

### Phase 3 — Appearance Mutation on Request
The "change her hair" feature.

1. **NLU parse:** detect appearance-change intent in user messages and extract structured deltas, e.g. `{hair_length: "short", eye_color: "blue"}`. Implement as a tool/function call on the LLM so it returns structured JSON.
2. **Apply delta:** update the companion's `AppearanceAttribute` nodes.
3. **Regenerate artifact:**
   - 3D path: call Ready Player Me with new params, cache the new mesh in S3 keyed by attribute hash, push the asset URL to the client.
   - Image/video path (optional, later): regenerate a base identity image via FLUX/SDXL + ControlNet (ControlNet preserves identity while altering the targeted feature only).
4. **Confirmation loop:** companion acknowledges the change in-character ("How's this?") and the avatar updates live.

**Definition of Done:** User says "give her green eyes and a bob", the avatar visibly updates, and the change persists across sessions.

---

### Phase 4 — Polish & Hardening
Latency optimization (target < 1.5s to first audio token), offline graceful degradation, caching, error states, reconnection logic on the WebSocket, rate limiting, and observability (structured logs + traces on the backend).

---

## 6. API Contracts (initial)

Keep DTOs in sync between `backend/app/models` (Pydantic) and `ios/.../Core/Models` (Codable).

**Create companion**
```
POST /companions
{ "name": "Aria", "traits": [{"name":"curious","intensity":0.8}],
  "appearance": {"hair_color":"auburn","eye_color":"green"},
  "voice_id": "<elevenlabs_voice_id>" }
→ 201 { "companion_id": "..." }
```

**Chat (WebSocket)** — client sends:
```
{ "type":"user_message", "companion_id":"...", "text":"..." }
```
Server streams:
```
{ "type":"token", "text":"..." }                      // repeated
{ "type":"emotion", "state":"warm" }
{ "type":"audio_chunk", "seq":0, "data":"<base64>" }  // repeated
{ "type":"appearance_update", "asset_url":"..." }     // when changed
{ "type":"done" }
```

**Get companion state**
```
GET /companions/{id} → full appearance + traits + relationship stage
```

---

## 7. Coding Conventions

**Swift**
- SwiftUI + MVVM. One `ObservableObject` view model per feature.
- Networking through a single `APIClient` actor; no ad-hoc `URLSession` calls in views.
- All DTOs `Codable`. No force-unwrapping in production paths.
- Cache meshes/textures/audio via `NSCache` with disk fallback keyed by content hash.

**Python**
- Type hints everywhere; Pydantic v2 for all request/response models.
- Services are stateless and dependency-injected; never instantiate clients inside route handlers.
- All Neo4j access goes through `app/graph/` — no raw Cypher in route handlers.
- Async I/O throughout. Use connection pooling for Neo4j.

**General**
- Secrets only from env. Provide a `.env.example` with every key, values blank.
- Every phase ships with tests for its core logic (persona assembly, memory dedup, appearance delta application are the priority units to test).

---

## 8. First Tasks for the Agent

1. Generate the repo structure in Section 3.
2. Write `docker-compose.yml` for Neo4j + the FastAPI backend.
3. Implement Phase 0 end to end and confirm the Definition of Done.
4. Stop and report. Do not begin Phase 1 until Phase 0 is verified running.

When a model ID, SDK method, or external API parameter is uncertain, look it up against current official documentation rather than guessing — several of these APIs change frequently.
