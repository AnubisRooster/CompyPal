# Graph Report - CompyPal  (2026-09-07)

## Corpus Check
- 74 files · ~246,794 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 969 nodes · 2144 edges · 51 communities (43 shown, 7 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 294 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- SceneKitAvatarController
- OpenRouterClient
- Foundation
- AudioRecorderService
- ElevenLabsTTS
- AppearanceDelta
- AvatarScene
- MemoryStore
- CodingKeys
- .generateForCompanion()
- AvatarViewModel
- Codable
- PerformanceTrack
- AvatarTests
- Emotion
- ChatViewModel
- ChatView
- CompanionInfo
- .systemPrompt()
- AvatarController
- Gesture
- TTSEngine
- AvatarThumbnail
- KeychainService
- CatalogEntry
- CodingKeys
- Viseme
- PerformanceDirector
- ExpressionPreset
- CatalogStatus
- SettingsView
- WardrobeSlot
- SettingsViewModel
- AvatarSceneView
- opencode.json
- .read()
- CompanionApp
- .setEmotion()
- .playGesture()
- DatabaseManager
- CatalogCache
- NewCompanionView
- Pricing
- .from()
- CodingKeys
- VoicePicker
- ModelRole
- .selectVoice()
- graphify_pipeline.py
- Package.swift

## God Nodes (most connected - your core abstractions)
1. `SceneKitAvatarController` - 77 edges
2. `AvatarViewModel` - 55 edges
3. `ChatViewModel` - 43 edges
4. `Gesture` - 40 edges
5. `CodingKeys` - 37 edges
6. `MemoryStore` - 32 edges
7. `Emotion` - 30 edges
8. `AvatarTests` - 29 edges
9. `CatalogEntry` - 28 edges
10. `AvatarController` - 27 edges

## Surprising Connections (you probably didn't know these)
- `.chatModels` --calls--> `SelectionPolicy`  [INFERRED]
  ios/Companion/Features/Settings/SettingsView.swift → ios/Companion/Core/LLM/Selection/SelectionPolicy.swift
- `.body` --calls--> `ContentView`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/App/ContentView.swift
- `CatalogRefreshChecker` --calls--> `CatalogCache`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/LLM/Catalog/CatalogCache.swift
- `CatalogRefreshChecker` --calls--> `CatalogFetcher`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/LLM/Catalog/CatalogFetcher.swift
- `CatalogRefreshChecker` --calls--> `KeychainService`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/Storage/KeychainService.swift

## Import Cycles
- None detected.

## Communities (51 total, 7 thin omitted)

### Community 0 - "SceneKitAvatarController"
Cohesion: 0.06
Nodes (31): DispatchWorkItem, GLTFSCNAnimation, GLTFSCNSceneSource, AvatarDescriptor, URL, ActiveGesture, AvatarError, garmentLoadFailed (+23 more)

### Community 1 - "OpenRouterClient"
Cohesion: 0.07
Nodes (34): AsyncThrowingStream, ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage (+26 more)

### Community 2 - "Foundation"
Cohesion: 0.06
Nodes (21): AVFoundation, Companion, Error, Foundation, GLTFKit2, STTError, noResult, unavailable (+13 more)

### Community 3 - "AudioRecorderService"
Cohesion: 0.08
Nodes (22): AnyObject, AppleSpeechSTTEngine, Bool, Data, SFSpeechRecognitionTask, String, URL, AudioRecorderService (+14 more)

### Community 4 - "ElevenLabsTTS"
Cohesion: 0.12
Nodes (23): AVAudioPlayer, AVAudioPlayerDelegate, ElevenLabsTTS, Data, Double, Error, Float, Int (+15 more)

### Community 5 - "AppearanceDelta"
Cohesion: 0.14
Nodes (12): Int64, AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, Bool (+4 more)

### Community 6 - "AvatarScene"
Cohesion: 0.16
Nodes (16): AnchorEntity, ARKit, ARView, Entity, AvatarScene, AvatarView, Coordinator, Context (+8 more)

### Community 7 - "MemoryStore"
Cohesion: 0.18
Nodes (10): GRDB, appearanceAttributes(), MemoryInfo, MemoryStore, personalityTraits(), Bool, Double, Int (+2 more)

### Community 8 - "CodingKeys"
Cohesion: 0.07
Nodes (27): CatalogCacheData, CodingKeys, architecture, b64Json, contextLength, delta, entries, finishReason (+19 more)

### Community 9 - ".generateForCompanion()"
Cohesion: 0.12
Nodes (15): ImageGenerationService, Bool, Data, Int64, String, URL, FileCache, .cacheDir (+7 more)

### Community 10 - "AvatarViewModel"
Cohesion: 0.13
Nodes (11): CADisplayLink, CFTimeInterval, .body, AvatarViewModel, Bool, Data, Double, Float (+3 more)

### Community 11 - "Codable"
Cohesion: 0.18
Nodes (23): Codable, Architecture, CatalogResponse, ChatChunk, ChatResponse, ChunkChoice, Delta, ImageData (+15 more)

### Community 12 - "PerformanceTrack"
Cohesion: 0.15
Nodes (13): PerformanceBeat, PerformanceTrack, Int, CompanionAvatarView, Bool, NSRange, String, DevelopmentAvatarPreview (+5 more)

### Community 13 - "AvatarTests"
Cohesion: 0.13
Nodes (3): AVAudioPCMBuffer, Float, AvatarTests

### Community 14 - "Emotion"
Cohesion: 0.11
Nodes (17): Index, AvatarDebugState, Emotion, affectionate, concerned, happy, neutral, playful (+9 more)

### Community 15 - "ChatViewModel"
Cohesion: 0.16
Nodes (12): AnyRegexOutput, AppearanceApplier, .body, .inputBar, ChatMessage, ChatViewModel, Data, Int64 (+4 more)

### Community 16 - "ChatView"
Cohesion: 0.13
Nodes (17): ChatPlaceholderView, .body, ContentView, .body, ChatView, .avatarAccessibilityLabel, .offlineBanner, .scrollView (+9 more)

### Community 17 - "CompanionInfo"
Cohesion: 0.15
Nodes (13): Hasher, Identifiable, IndexSet, CompanionInfo, .level, Date, CompanionRow, .body (+5 more)

### Community 18 - ".systemPrompt()"
Cohesion: 0.16
Nodes (7): PersonaAssembler, Date, Double, String, PersonaAssemblerTests, Double, String

### Community 19 - "AvatarController"
Cohesion: 0.19
Nodes (9): AvatarController, EmotionSystem, GazeSystem, GestureSystem, IdleLifeSystem, ReactivitySystem, SecondaryMotionSystem, Bool (+1 more)

### Community 20 - "Gesture"
Cohesion: 0.10
Nodes (21): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+13 more)

### Community 21 - "TTSEngine"
Cohesion: 0.14
Nodes (13): AVSpeechSynthesizer, AVSpeechSynthesizerDelegate, AVSpeechUtterance, Bool, Double, NSRange, String, TimeInterval (+5 more)

### Community 22 - "AvatarThumbnail"
Cohesion: 0.15
Nodes (17): CGRect, Color, AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong (+9 more)

### Community 23 - "KeychainService"
Cohesion: 0.14
Nodes (12): CustomStringConvertible, KeychainError, .description, encodeFailed, invalidKeyFormat, readFailed, storeFailed, KeychainService (+4 more)

### Community 24 - "CatalogEntry"
Cohesion: 0.26
Nodes (6): CatalogEntry, SelectionPolicy, Bool, Double, String, SelectionPolicyTests

### Community 25 - "CodingKeys"
Cohesion: 0.18
Nodes (16): Hashable, CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount (+8 more)

### Community 26 - "Viseme"
Cohesion: 0.19
Nodes (10): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem (+2 more)

### Community 27 - "PerformanceDirector"
Cohesion: 0.20
Nodes (10): GazeTarget, away, camera, idle, user, .debugOverlay, PerformanceDirector, Int (+2 more)

### Community 28 - "ExpressionPreset"
Cohesion: 0.13
Nodes (13): BlendShapeWeights, ExpressionPreset, amused, concerned, curious, excited, neutral, playful (+5 more)

### Community 29 - "CatalogStatus"
Cohesion: 0.14
Nodes (14): Equatable, CatalogStatus, cached, failed, fetched, refreshing, unknown, ConnectionStatus (+6 more)

### Community 30 - "SettingsView"
Cohesion: 0.21
Nodes (6): Bool, SettingsView, .body, .chatModels, Double, String

### Community 31 - "WardrobeSlot"
Cohesion: 0.24
Nodes (7): GarmentAsset, Set, WardrobeSlot, Bool, WardrobeSystem, RawRepresentable, Sendable

### Community 32 - "SettingsViewModel"
Cohesion: 0.18
Nodes (8): CaseIterable, ModelMode, auto, pinned, SettingsViewModel, .imageGenEnabled, Bool, String

### Community 33 - "AvatarSceneView"
Cohesion: 0.26
Nodes (8): AvatarSceneView, Coordinator, Context, Coordinator, SCNView, Void, UITapGestureRecognizer, UIViewRepresentable

### Community 34 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 35 - ".read()"
Cohesion: 0.29
Nodes (4): CatalogFetcher, JSONDecoder, String, URLSession

### Community 36 - "CompanionApp"
Cohesion: 0.24
Nodes (8): App, CatalogRefreshChecker, CompanionApp, .body, Never, Task, Void, Scene

### Community 39 - "DatabaseManager"
Cohesion: 0.44
Nodes (5): DatabaseQueue, DatabaseManager, Bool, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 40 - "CatalogCache"
Cohesion: 0.36
Nodes (3): CatalogCache, Bool, TimeInterval

### Community 41 - "NewCompanionView"
Cohesion: 0.36
Nodes (5): NewCompanionView, .body, Int64, String, Void

### Community 42 - "Pricing"
Cohesion: 0.53
Nodes (4): Decoder, Pricing, Double, KeyedDecodingContainer

### Community 44 - "CodingKeys"
Cohesion: 0.40
Nodes (5): CodingKey, CodingKeys, companionId, text, type

### Community 46 - "ModelRole"
Cohesion: 0.50
Nodes (4): ModelRole, chat, extract, image

## Knowledge Gaps
- **155 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `emptyAudio` (+150 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 268 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `ChatViewModel` to `OpenRouterClient`, `Foundation`, `AudioRecorderService`, `ElevenLabsTTS`, `.playGesture()`, `MemoryStore`, `CatalogCache`, `.generateForCompanion()`, `AvatarViewModel`, `PerformanceTrack`, `ChatView`, `CompanionInfo`, `Gesture`, `TTSEngine`, `KeychainService`, `CatalogEntry`?**
  _High betweenness centrality (0.225) - this node is a cross-community bridge._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `SceneKitAvatarController`, `Foundation`, `.setEmotion()`, `.playGesture()`, `PerformanceTrack`, `Emotion`, `ChatViewModel`, `AvatarController`, `Viseme`, `PerformanceDirector`, `WardrobeSlot`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Foundation` to `OpenRouterClient`, `AudioRecorderService`, `AppearanceDelta`, `MemoryStore`, `CatalogCache`, `.generateForCompanion()`, `Codable`, `Emotion`, `ChatViewModel`, `.systemPrompt()`, `KeychainService`, `CodingKeys`, `ExpressionPreset`, `WardrobeSlot`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _155 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `SceneKitAvatarController` be split into smaller, more focused modules?**
  _Cohesion score 0.058416139716952725 - nodes in this community are weakly interconnected._