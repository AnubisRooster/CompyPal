# Graph Report - CompyPal  (2026-09-21)

## Corpus Check
- 74 files · ~248,171 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: .plist 2, (none) 1, .jsonl 1)

## Summary
- 999 nodes · 2151 edges · 55 communities (46 shown, 9 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 291 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- SceneKitAvatarController
- Foundation
- OpenRouterClient
- AvatarScene
- ElevenLabsTTS
- AppearanceDelta
- AppleSpeechSTTEngine
- AvatarViewModel
- CodingKeys
- ChatViewModel
- SettingsViewModel
- AvatarThumbnail
- .generateForCompanion()
- PerformanceDirector
- MemoryStore
- .systemPrompt()
- WardrobeSlot
- Gesture
- Codable
- KeychainService
- CatalogEntry
- TTSEngine
- ChatView
- CodingKeys
- CompanionInfo
- Emotion
- AvatarTests
- AvatarController
- Viseme
- graphify_pipeline.py
- PerformanceTrack
- SettingsView
- AvatarSceneView
- opencode.json
- NewCompanionView
- ChatModels.swift
- .computePCMEnergies()
- GestureSystem
- CompanionApp
- AudioRecorderService
- DatabaseManager
- MemoryStore.swift
- .setEmotion()
- CatalogCache
- .load()
- Pricing
- CatalogFetcher
- .read()
- .from()
- NetworkMonitor
- ModelRole
- .balancedClose()
- .setListening()
- Package.swift

## God Nodes (most connected - your core abstractions)
1. `SceneKitAvatarController` - 76 edges
2. `AvatarViewModel` - 55 edges
3. `ChatViewModel` - 42 edges
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

## Communities (55 total, 9 thin omitted)

### Community 0 - "SceneKitAvatarController"
Cohesion: 0.06
Nodes (27): DispatchWorkItem, GLTFSCNAnimation, GLTFSCNSceneSource, AvatarDescriptor, URL, ActiveGesture, ExprFlicker, GLBBone (+19 more)

### Community 1 - "Foundation"
Cohesion: 0.05
Nodes (24): AVFoundation, AVSpeechSynthesisVoice, Companion, Error, Foundation, GLTFKit2, STTError, noResult (+16 more)

### Community 2 - "OpenRouterClient"
Cohesion: 0.07
Nodes (34): AsyncThrowingStream, ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage (+26 more)

### Community 3 - "AvatarScene"
Cohesion: 0.07
Nodes (29): AnchorEntity, ARKit, ARView, Entity, AvatarScene, AvatarView, Coordinator, Context (+21 more)

### Community 4 - "ElevenLabsTTS"
Cohesion: 0.10
Nodes (25): AVAudioPlayer, AVAudioPlayerDelegate, Identifiable, ElevenLabsTTS, Bool, Data, Double, Error (+17 more)

### Community 5 - "AppearanceDelta"
Cohesion: 0.14
Nodes (12): Int64, AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, Bool (+4 more)

### Community 6 - "AppleSpeechSTTEngine"
Cohesion: 0.09
Nodes (18): AnyObject, AppleSpeechSTTEngine, Bool, Data, SFSpeechRecognitionTask, String, URL, STTEngine (+10 more)

### Community 7 - "AvatarViewModel"
Cohesion: 0.11
Nodes (15): CADisplayLink, CFTimeInterval, Bool, CompanionAvatarView, .body, .debugOverlay, Bool, AvatarViewModel (+7 more)

### Community 8 - "CodingKeys"
Cohesion: 0.08
Nodes (25): CodingKeys, architecture, b64Json, contextLength, delta, entries, finishReason, id (+17 more)

### Community 9 - "ChatViewModel"
Cohesion: 0.17
Nodes (13): AnyRegexOutput, .body, .inputBar, ChatMessage, ChatViewModel, Bool, Data, Int64 (+5 more)

### Community 10 - "SettingsViewModel"
Cohesion: 0.10
Nodes (22): CaseIterable, Equatable, CatalogStatus, cached, failed, fetched, refreshing, unknown (+14 more)

### Community 11 - "AvatarThumbnail"
Cohesion: 0.13
Nodes (19): CGRect, Color, AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong (+11 more)

### Community 12 - ".generateForCompanion()"
Cohesion: 0.15
Nodes (13): ImageGenerationService, Bool, Data, Int64, String, URL, FileCache, .cacheDir (+5 more)

### Community 13 - "PerformanceDirector"
Cohesion: 0.14
Nodes (11): GazeTarget, away, camera, idle, user, GazeSystem, Bool, PerformanceDirector (+3 more)

### Community 14 - "MemoryStore"
Cohesion: 0.20
Nodes (6): MemoryStore, Bool, Int, Int64, String, AppearanceApplier

### Community 15 - ".systemPrompt()"
Cohesion: 0.16
Nodes (7): PersonaAssembler, Date, Double, String, PersonaAssemblerTests, Double, String

### Community 16 - "WardrobeSlot"
Cohesion: 0.15
Nodes (8): GarmentAsset, Set, WardrobeSlot, garmentNotFound, Set, Bool, WardrobeSystem, RawRepresentable

### Community 17 - "Gesture"
Cohesion: 0.10
Nodes (21): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+13 more)

### Community 18 - "Codable"
Cohesion: 0.24
Nodes (18): Codable, Architecture, CatalogCacheData, CatalogResponse, ChatChunk, ChatResponse, ChunkChoice, Delta (+10 more)

### Community 19 - "KeychainService"
Cohesion: 0.14
Nodes (11): CustomStringConvertible, KeychainError, .description, encodeFailed, invalidKeyFormat, storeFailed, KeychainService, Bool (+3 more)

### Community 20 - "CatalogEntry"
Cohesion: 0.24
Nodes (7): CatalogEntry, Int, SelectionPolicy, Bool, Double, String, SelectionPolicyTests

### Community 21 - "TTSEngine"
Cohesion: 0.13
Nodes (13): AVSpeechSynthesizer, AVSpeechSynthesizerDelegate, AVSpeechUtterance, Bool, Double, NSRange, String, TimeInterval (+5 more)

### Community 22 - "ChatView"
Cohesion: 0.16
Nodes (15): ChatPlaceholderView, .body, ContentView, .body, ChatView, .avatarAccessibilityLabel, .offlineBanner, .scrollView (+7 more)

### Community 23 - "CodingKeys"
Cohesion: 0.18
Nodes (16): Hashable, CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount (+8 more)

### Community 24 - "CompanionInfo"
Cohesion: 0.18
Nodes (9): Hasher, IndexSet, CompanionInfo, .level, CompanionsView, .body, Void, CompanionsViewModel (+1 more)

### Community 25 - "Emotion"
Cohesion: 0.15
Nodes (14): AvatarDebugState, Emotion, affectionate, concerned, happy, neutral, playful, sad (+6 more)

### Community 27 - "AvatarController"
Cohesion: 0.17
Nodes (6): AvatarController, TimeInterval, UIImage, IdleLifeSystem, SecondaryMotionSystem, SCNVector3

### Community 28 - "Viseme"
Cohesion: 0.23
Nodes (10): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem (+2 more)

### Community 29 - "graphify_pipeline.py"
Cohesion: 0.13
Nodes (13): graphify_analyze, graphify_build, graphify_cluster, graphify_detect, graphify_export, graphify_extract, graphify_llm, graphify_report (+5 more)

### Community 30 - "PerformanceTrack"
Cohesion: 0.26
Nodes (7): PerformanceBeat, PerformanceTrack, Int, NSRange, DevelopmentAvatarPreview, .emotionGrid, .sequenceView

### Community 31 - "SettingsView"
Cohesion: 0.19
Nodes (7): OnboardingView, .body, SettingsView, .body, .chatModels, Double, String

### Community 32 - "AvatarSceneView"
Cohesion: 0.24
Nodes (8): AvatarSceneView, Coordinator, Context, Coordinator, SCNView, Void, UITapGestureRecognizer, UIViewRepresentable

### Community 33 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 34 - "NewCompanionView"
Cohesion: 0.21
Nodes (7): AVSpeechSynthesisVoiceGender, String, NewCompanionView, .body, Int64, String, Void

### Community 35 - "ChatModels.swift"
Cohesion: 0.24
Nodes (11): CodingKey, CodingKeys, companionId, text, type, ServerDone, ServerEmotion, ServerError (+3 more)

### Community 37 - "GestureSystem"
Cohesion: 0.23
Nodes (3): GestureSystem, ReactivitySystem, String

### Community 38 - "CompanionApp"
Cohesion: 0.24
Nodes (8): App, CatalogRefreshChecker, CompanionApp, .body, Never, Task, Void, Scene

### Community 39 - "AudioRecorderService"
Cohesion: 0.29
Nodes (6): AudioRecorderService, Bool, SFSpeechRecognitionTask, String, Void, SFSpeechAudioBufferRecognitionRequest

### Community 40 - "DatabaseManager"
Cohesion: 0.39
Nodes (5): DatabaseQueue, DatabaseManager, Bool, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 41 - "MemoryStore.swift"
Cohesion: 0.33
Nodes (6): GRDB, appearanceAttributes(), MemoryInfo, personalityTraits(), Date, Double

### Community 43 - "CatalogCache"
Cohesion: 0.36
Nodes (3): CatalogCache, Bool, TimeInterval

### Community 44 - ".load()"
Cohesion: 0.43
Nodes (3): Double, String, .appearanceView

### Community 45 - "Pricing"
Cohesion: 0.43
Nodes (5): Decoder, Pricing, Double, KeyedDecodingContainer, Sendable

### Community 46 - "CatalogFetcher"
Cohesion: 0.48
Nodes (4): CatalogFetcher, JSONDecoder, String, URLSession

### Community 49 - "NetworkMonitor"
Cohesion: 0.40
Nodes (3): NetworkMonitor, Network, ObservableObject

### Community 50 - "ModelRole"
Cohesion: 0.50
Nodes (4): ModelRole, chat, extract, image

## Knowledge Gaps
- **155 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `emptyAudio` (+150 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 297 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `ChatViewModel` to `Foundation`, `OpenRouterClient`, `ElevenLabsTTS`, `AudioRecorderService`, `AvatarViewModel`, `CatalogCache`, `.generateForCompanion()`, `.load()`, `MemoryStore`, `Gesture`, `NetworkMonitor`, `KeychainService`, `CatalogEntry`, `TTSEngine`, `ChatView`, `CompanionInfo`, `PerformanceTrack`?**
  _High betweenness centrality (0.216) - this node is a cross-community bridge._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `SceneKitAvatarController`, `Foundation`, `GestureSystem`, `ChatViewModel`, `.setEmotion()`, `.load()`, `PerformanceDirector`, `WardrobeSlot`, `NetworkMonitor`, `.setListening()`, `Emotion`, `AvatarController`, `Viseme`, `PerformanceTrack`?**
  _High betweenness centrality (0.161) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Foundation` to `OpenRouterClient`, `ChatModels.swift`, `AvatarScene`, `AppearanceDelta`, `AppleSpeechSTTEngine`, `MemoryStore.swift`, `CatalogCache`, `.generateForCompanion()`, `MemoryStore`, `.systemPrompt()`, `WardrobeSlot`, `NetworkMonitor`, `Codable`, `KeychainService`, `CodingKeys`, `Emotion`?**
  _High betweenness centrality (0.142) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _155 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `SceneKitAvatarController` be split into smaller, more focused modules?**
  _Cohesion score 0.057297297297297295 - nodes in this community are weakly interconnected._