# Graph Report - CompyPal  (2026-10-05)

## Corpus Check
- 74 files · ~249,035 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: .plist 2, (none) 1, .jsonl 1)

## Summary
- 1006 nodes · 2181 edges · 63 communities (36 shown, 27 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 304 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Foundation
- OpenRouterClient
- AvatarScene
- ElevenLabsTTS
- Codable
- AppearanceDelta
- ChatViewModel
- AppleSpeechSTTEngine
- Gesture
- CodingKeys
- SceneKitAvatarController
- MemoryStore
- .generateForCompanion()
- AvatarViewModel
- .systemPrompt()
- AvatarThumbnail
- KeychainService
- CompanionInfo
- TTSEngine
- SettingsViewModel
- .setEmotion()
- CatalogEntry
- WardrobeSlot
- Viseme
- CodingKeys
- PerformanceDirector
- ChatView
- .extract()
- AudioRecorderService
- Emotion
- AvatarTests
- AvatarSceneView
- opencode.json
- .beginSpeaking()
- CompanionApp
- String
- CatalogCache
- SettingsView
- AvatarController
- DatabaseManager
- MemoryStore.swift
- SecondaryMotionSystem
- TimeInterval
- .setEnabled()
- GazeTarget
- CompanionAvatarView
- SwiftUI
- ContentView
- CatalogFetcher
- AvatarDescriptor
- NewCompanionView
- Pricing
- CodingKeys
- AvatarError
- .frameModel()
- ModelRole
- Package.swift

## God Nodes (most connected - your core abstractions)
1. `SceneKitAvatarController` - 76 edges
2. `AvatarViewModel` - 55 edges
3. `ChatViewModel` - 48 edges
4. `Gesture` - 40 edges
5. `CodingKeys` - 37 edges
6. `MemoryStore` - 32 edges
7. `Emotion` - 30 edges
8. `AvatarController` - 30 edges
9. `AvatarTests` - 29 edges
10. `CatalogEntry` - 28 edges

## Surprising Connections (you probably didn't know these)
- `.chatModels` --calls--> `SelectionPolicy`  [INFERRED]
  ios/Companion/Features/Settings/SettingsView.swift → ios/Companion/Core/LLM/Selection/SelectionPolicy.swift
- `CatalogRefreshChecker` --calls--> `CatalogCache`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/LLM/Catalog/CatalogCache.swift
- `CatalogRefreshChecker` --calls--> `CatalogFetcher`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/LLM/Catalog/CatalogFetcher.swift
- `CatalogRefreshChecker` --calls--> `KeychainService`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/Storage/KeychainService.swift
- `.body` --calls--> `ChatView`  [INFERRED]
  ios/Companion/App/ContentView.swift → ios/Companion/Features/Chat/ChatView.swift

## Import Cycles
- None detected.

## Communities (63 total, 27 thin omitted)

### Community 0 - "Foundation"
Cohesion: 0.06
Nodes (18): AVFoundation, Companion, Foundation, STTError, noResult, unavailable, VoicePicker, CatalogError (+10 more)

### Community 1 - "OpenRouterClient"
Cohesion: 0.07
Nodes (20): ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage, unauthorized (+12 more)

### Community 2 - "AvatarScene"
Cohesion: 0.07
Nodes (17): ARKit, AvatarScene, AvatarView, Coordinator, BlendShapeWeights, ExpressionPreset, amused, concerned (+9 more)

### Community 3 - "ElevenLabsTTS"
Cohesion: 0.10
Nodes (8): ElevenLabsTTS, TTSError, decodeFailed, emptyAudio, .errorDescription, http, missingKey, Voice

### Community 4 - "Codable"
Cohesion: 0.14
Nodes (24): Architecture, CatalogCacheData, CatalogResponse, ChatChunk, ChatRequest, ChatResponse, ChunkChoice, Delta (+16 more)

### Community 5 - "AppearanceDelta"
Cohesion: 0.14
Nodes (7): AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, ParametricSchemaTests

### Community 6 - "ChatViewModel"
Cohesion: 0.14
Nodes (4): .body, .inputBar, ChatMessage, ChatViewModel

### Community 7 - "AppleSpeechSTTEngine"
Cohesion: 0.09
Nodes (6): AppleSpeechSTTEngine, STTEngine, STTEngineType, appleSpeech, whisper, WhisperSTTEngine

### Community 8 - "Gesture"
Cohesion: 0.08
Nodes (24): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+16 more)

### Community 9 - "CodingKeys"
Cohesion: 0.08
Nodes (25): CodingKeys, architecture, b64Json, contextLength, delta, entries, finishReason, id (+17 more)

### Community 10 - "SceneKitAvatarController"
Cohesion: 0.12
Nodes (5): SceneKitAvatarController, .availableClipNames, .isGLBLoaded, .morpherIndexCount, .morpherIndexUniqueNameCount

### Community 12 - ".generateForCompanion()"
Cohesion: 0.15
Nodes (4): ImageGenerationService, FileCache, .cacheDir, .body

### Community 15 - "AvatarThumbnail"
Cohesion: 0.15
Nodes (9): AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong, .renderedFace, .skinColor (+1 more)

### Community 16 - "KeychainService"
Cohesion: 0.14
Nodes (8): KeychainError, .description, encodeFailed, invalidKeyFormat, readFailed, storeFailed, KeychainService, Security

### Community 17 - "CompanionInfo"
Cohesion: 0.16
Nodes (7): CompanionInfo, .level, CompanionRow, .body, CompanionsView, .body, CompanionsViewModel

### Community 18 - "TTSEngine"
Cohesion: 0.13
Nodes (3): TTSEngine, .isPaused, completion

### Community 19 - "SettingsViewModel"
Cohesion: 0.12
Nodes (13): CatalogStatus, cached, failed, fetched, refreshing, unknown, ConnectionStatus, failed (+5 more)

### Community 20 - ".setEmotion()"
Cohesion: 0.18
Nodes (3): EmotionSystem, GestureSystem, ReactivitySystem

### Community 21 - "CatalogEntry"
Cohesion: 0.27
Nodes (3): CatalogEntry, SelectionPolicy, SelectionPolicyTests

### Community 22 - "WardrobeSlot"
Cohesion: 0.18
Nodes (3): GarmentAsset, WardrobeSlot, WardrobeSystem

### Community 23 - "Viseme"
Cohesion: 0.18
Nodes (8): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem

### Community 24 - "CodingKeys"
Cohesion: 0.18
Nodes (12): CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount, voiceId (+4 more)

### Community 26 - "ChatView"
Cohesion: 0.17
Nodes (10): ChatView, .avatarAccessibilityLabel, .offlineBanner, .scrollView, DotLoader, .body, MessageBubble, .body (+2 more)

### Community 30 - "Emotion"
Cohesion: 0.17
Nodes (13): AvatarDebugState, Emotion, affectionate, concerned, happy, neutral, playful, sad (+5 more)

### Community 33 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 35 - ".beginSpeaking()"
Cohesion: 0.30
Nodes (3): DevelopmentAvatarPreview, .emotionGrid, .sequenceView

### Community 40 - "SettingsView"
Cohesion: 0.31
Nodes (3): SettingsView, .body, .chatModels

### Community 42 - "DatabaseManager"
Cohesion: 0.39
Nodes (3): DatabaseManager, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 43 - "MemoryStore.swift"
Cohesion: 0.33
Nodes (4): GRDB, appearanceAttributes(), MemoryInfo, personalityTraits()

### Community 47 - "GazeTarget"
Cohesion: 0.29
Nodes (5): GazeTarget, away, camera, idle, user

### Community 48 - "CompanionAvatarView"
Cohesion: 0.25
Nodes (5): CompanionAvatarView, .debugOverlay, .body, .gestureGrid, .companionHeader

### Community 49 - "SwiftUI"
Cohesion: 0.29
Nodes (3): GLTFKit2, OSLog, SwiftUI

### Community 50 - "ContentView"
Cohesion: 0.38
Nodes (5): .body, ChatPlaceholderView, .body, ContentView, .body

### Community 57 - "CodingKeys"
Cohesion: 0.40
Nodes (4): CodingKeys, companionId, text, type

### Community 58 - "AvatarError"
Cohesion: 0.40
Nodes (4): AvatarError, garmentLoadFailed, garmentNotFound, glbLoadFailed

### Community 60 - "ModelRole"
Cohesion: 0.50
Nodes (4): ModelRole, chat, extract, image

## Knowledge Gaps
- **155 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `emptyAudio` (+150 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 298 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **27 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `ChatViewModel` to `Foundation`, `OpenRouterClient`, `ElevenLabsTTS`, `.beginSpeaking()`, `CatalogCache`, `Gesture`, `MemoryStore`, `.generateForCompanion()`, `AvatarViewModel`, `KeychainService`, `CompanionInfo`, `TTSEngine`, `.read()`, `CatalogEntry`, `ChatView`, `AudioRecorderService`?**
  _High betweenness centrality (0.235) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _155 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Foundation` be split into smaller, more focused modules?**
  _Cohesion score 0.05795918367346939 - nodes in this community are weakly interconnected._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `Foundation`, `.beginSpeaking()`, `ChatViewModel`, `AvatarController`, `SceneKitAvatarController`, `SecondaryMotionSystem`, `.setEnabled()`, `GazeTarget`, `CompanionAvatarView`, `.setEmotion()`, `WardrobeSlot`, `Viseme`, `PerformanceDirector`, `AudioRecorderService`, `Emotion`?**
  _High betweenness centrality (0.154) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Should `OpenRouterClient` be split into smaller, more focused modules?**
  _Cohesion score 0.07246376811594203 - nodes in this community are weakly interconnected._