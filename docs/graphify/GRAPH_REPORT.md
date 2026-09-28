# Graph Report - CompyPal  (2026-09-28)

## Corpus Check
- 74 files · ~249,070 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: .plist 2, (none) 1, .jsonl 1)

## Summary
- 999 nodes · 2151 edges · 57 communities (43 shown, 14 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 291 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- AvatarViewModel
- OpenRouterClient
- Foundation
- AvatarScene
- ElevenLabsTTS
- AppearanceDelta
- AppleSpeechSTTEngine
- Gesture
- CodingKeys
- AvatarController
- SceneKitAvatarController
- MemoryStore
- SettingsViewModel
- .generateForCompanion()
- PerformanceDirector
- CompanionInfo
- .systemPrompt()
- WardrobeSlot
- AvatarThumbnail
- Codable
- SettingsView
- CatalogEntry
- TTSEngine
- KeychainService
- ChatView
- CodingKeys
- AvatarTests
- Viseme
- ExpressionPreset
- graphify_pipeline.py
- opencode.json
- ChatModels.swift
- .computePCMEnergies()
- Emotion
- String
- CompanionApp
- DatabaseManager
- .loadGLB()
- .setEmotion()
- CatalogCache
- TimeInterval
- NewCompanionView
- CompanionTests
- Pricing
- CatalogFetcher
- .ensureUser()
- AvatarTypes.swift
- AvatarDescriptor
- .from()
- .updateAppearanceMaterials()
- .frameModel()
- ModelRole
- .balancedClose()
- AppearanceApplier
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

## Communities (57 total, 14 thin omitted)

### Community 0 - "AvatarViewModel"
Cohesion: 0.05
Nodes (44): AnyRegexOutput, CADisplayLink, CFTimeInterval, AudioRecorderService, Bool, SFSpeechRecognitionTask, String, Void (+36 more)

### Community 1 - "OpenRouterClient"
Cohesion: 0.07
Nodes (34): AsyncThrowingStream, ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage (+26 more)

### Community 2 - "Foundation"
Cohesion: 0.06
Nodes (26): AVFoundation, AVSpeechSynthesisVoice, Companion, Error, Foundation, GLTFKit2, STTError, noResult (+18 more)

### Community 3 - "AvatarScene"
Cohesion: 0.09
Nodes (24): AnchorEntity, ARKit, ARView, Entity, AvatarScene, AvatarView, Coordinator, Context (+16 more)

### Community 4 - "ElevenLabsTTS"
Cohesion: 0.10
Nodes (25): AVAudioPlayer, AVAudioPlayerDelegate, Identifiable, ElevenLabsTTS, Bool, Data, Double, Error (+17 more)

### Community 5 - "AppearanceDelta"
Cohesion: 0.14
Nodes (12): Int64, AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, Bool (+4 more)

### Community 6 - "AppleSpeechSTTEngine"
Cohesion: 0.09
Nodes (18): AnyObject, AppleSpeechSTTEngine, Bool, Data, SFSpeechRecognitionTask, String, URL, STTEngine (+10 more)

### Community 7 - "Gesture"
Cohesion: 0.08
Nodes (21): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+13 more)

### Community 8 - "CodingKeys"
Cohesion: 0.08
Nodes (25): CodingKeys, architecture, b64Json, contextLength, delta, entries, finishReason, id (+17 more)

### Community 9 - "AvatarController"
Cohesion: 0.12
Nodes (10): AvatarController, Bool, TimeInterval, UIImage, GestureSystem, IdleLifeSystem, ReactivitySystem, SecondaryMotionSystem (+2 more)

### Community 10 - "SceneKitAvatarController"
Cohesion: 0.11
Nodes (13): DispatchWorkItem, SceneKitAvatarController, .availableClipNames, .isGLBLoaded, .morpherIndexCount, .morpherIndexUniqueNameCount, Bool, Int (+5 more)

### Community 11 - "MemoryStore"
Cohesion: 0.21
Nodes (10): GRDB, appearanceAttributes(), MemoryInfo, MemoryStore, personalityTraits(), Bool, Double, Int (+2 more)

### Community 12 - "SettingsViewModel"
Cohesion: 0.10
Nodes (22): CaseIterable, Equatable, CatalogStatus, cached, failed, fetched, refreshing, unknown (+14 more)

### Community 13 - ".generateForCompanion()"
Cohesion: 0.15
Nodes (13): ImageGenerationService, Bool, Data, Int64, String, URL, FileCache, .cacheDir (+5 more)

### Community 14 - "PerformanceDirector"
Cohesion: 0.14
Nodes (11): GazeTarget, away, camera, idle, user, GazeSystem, Bool, PerformanceDirector (+3 more)

### Community 15 - "CompanionInfo"
Cohesion: 0.15
Nodes (12): Hasher, IndexSet, CompanionInfo, .level, Date, CompanionRow, .body, CompanionsView (+4 more)

### Community 16 - ".systemPrompt()"
Cohesion: 0.16
Nodes (7): PersonaAssembler, Date, Double, String, PersonaAssemblerTests, Double, String

### Community 17 - "WardrobeSlot"
Cohesion: 0.15
Nodes (8): GarmentAsset, Set, WardrobeSlot, garmentNotFound, Set, Bool, WardrobeSystem, RawRepresentable

### Community 18 - "AvatarThumbnail"
Cohesion: 0.15
Nodes (17): CGRect, Color, AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong (+9 more)

### Community 19 - "Codable"
Cohesion: 0.24
Nodes (18): Codable, Architecture, CatalogCacheData, CatalogResponse, ChatChunk, ChatResponse, ChunkChoice, Delta (+10 more)

### Community 20 - "SettingsView"
Cohesion: 0.15
Nodes (8): readFailed, OnboardingView, .body, SettingsView, .body, .chatModels, Double, String

### Community 21 - "CatalogEntry"
Cohesion: 0.24
Nodes (7): CatalogEntry, Int, SelectionPolicy, Bool, Double, String, SelectionPolicyTests

### Community 22 - "TTSEngine"
Cohesion: 0.13
Nodes (13): AVSpeechSynthesizer, AVSpeechSynthesizerDelegate, AVSpeechUtterance, Bool, Double, NSRange, String, TimeInterval (+5 more)

### Community 23 - "KeychainService"
Cohesion: 0.15
Nodes (11): CustomStringConvertible, KeychainError, .description, encodeFailed, invalidKeyFormat, storeFailed, KeychainService, Bool (+3 more)

### Community 24 - "ChatView"
Cohesion: 0.16
Nodes (15): ChatPlaceholderView, .body, ContentView, .body, ChatView, .avatarAccessibilityLabel, .offlineBanner, .scrollView (+7 more)

### Community 25 - "CodingKeys"
Cohesion: 0.18
Nodes (16): Hashable, CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount (+8 more)

### Community 27 - "Viseme"
Cohesion: 0.23
Nodes (10): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem (+2 more)

### Community 28 - "ExpressionPreset"
Cohesion: 0.13
Nodes (13): BlendShapeWeights, ExpressionPreset, amused, concerned, curious, excited, neutral, playful (+5 more)

### Community 29 - "graphify_pipeline.py"
Cohesion: 0.13
Nodes (13): graphify_analyze, graphify_build, graphify_cluster, graphify_detect, graphify_export, graphify_extract, graphify_llm, graphify_report (+5 more)

### Community 30 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 31 - "ChatModels.swift"
Cohesion: 0.24
Nodes (11): CodingKey, CodingKeys, companionId, text, type, ServerDone, ServerEmotion, ServerError (+3 more)

### Community 33 - "Emotion"
Cohesion: 0.18
Nodes (10): Emotion, affectionate, concerned, happy, neutral, playful, sad, surprised (+2 more)

### Community 34 - "String"
Cohesion: 0.35
Nodes (3): ExprFlicker, Float, String

### Community 35 - "CompanionApp"
Cohesion: 0.24
Nodes (8): App, CatalogRefreshChecker, CompanionApp, .body, Never, Task, Void, Scene

### Community 36 - "DatabaseManager"
Cohesion: 0.33
Nodes (5): DatabaseQueue, DatabaseManager, Bool, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 37 - ".loadGLB()"
Cohesion: 0.24
Nodes (3): GLTFSCNAnimation, GLTFSCNSceneSource, URL

### Community 39 - "CatalogCache"
Cohesion: 0.36
Nodes (3): CatalogCache, Bool, TimeInterval

### Community 41 - "NewCompanionView"
Cohesion: 0.36
Nodes (5): NewCompanionView, .body, Int64, String, Void

### Community 43 - "Pricing"
Cohesion: 0.43
Nodes (5): Decoder, Pricing, Double, KeyedDecodingContainer, Sendable

### Community 44 - "CatalogFetcher"
Cohesion: 0.48
Nodes (4): CatalogFetcher, JSONDecoder, String, URLSession

### Community 46 - "AvatarTypes.swift"
Cohesion: 0.47
Nodes (4): AvatarDebugState, ExpressionWeights, PersonalityMotionProfile, Float

### Community 50 - ".frameModel()"
Cohesion: 0.60
Nodes (3): GLBBone, SCNVector3, SCNNode

### Community 52 - "ModelRole"
Cohesion: 0.50
Nodes (4): ModelRole, chat, extract, image

## Knowledge Gaps
- **155 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `emptyAudio` (+150 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 297 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `AvatarViewModel` to `OpenRouterClient`, `Foundation`, `ElevenLabsTTS`, `CatalogCache`, `Gesture`, `MemoryStore`, `.generateForCompanion()`, `CompanionInfo`, `KeychainService`, `CatalogEntry`, `TTSEngine`, `AppearanceApplier`, `ChatView`?**
  _High betweenness centrality (0.216) - this node is a cross-community bridge._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `Emotion`, `Foundation`, `.setEmotion()`, `Gesture`, `AvatarController`, `SceneKitAvatarController`, `AvatarTypes.swift`, `PerformanceDirector`, `AvatarDescriptor`, `WardrobeSlot`, `Viseme`?**
  _High betweenness centrality (0.161) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Foundation` to `OpenRouterClient`, `DatabaseManager`, `AppearanceDelta`, `AppleSpeechSTTEngine`, `CatalogCache`, `MemoryStore`, `.generateForCompanion()`, `AvatarTypes.swift`, `.systemPrompt()`, `WardrobeSlot`, `Codable`, `KeychainService`, `AppearanceApplier`, `CodingKeys`, `ExpressionPreset`, `ChatModels.swift`?**
  _High betweenness centrality (0.142) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _155 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `AvatarViewModel` be split into smaller, more focused modules?**
  _Cohesion score 0.05238095238095238 - nodes in this community are weakly interconnected._