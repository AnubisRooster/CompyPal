# Graph Report - CompyPal  (2026-09-14)

## Corpus Check
- 74 files · ~246,794 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: .plist 2, (none) 1, .jsonl 1)

## Summary
- 969 nodes · 2172 edges · 52 communities (44 shown, 8 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 297 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- SceneKitAvatarController
- AvatarViewModel
- OpenRouterClient
- Foundation
- AudioRecorderService
- ElevenLabsTTS
- AppearanceDelta
- AvatarScene
- MemoryStore
- .generateForCompanion()
- Gesture
- CodingKeys
- CatalogEntry
- Codable
- .systemPrompt()
- ChatViewModel
- TTSEngine
- AvatarThumbnail
- CatalogStatus
- CompanionInfo
- ChatView
- AvatarController
- SettingsView
- Viseme
- WardrobeSlot
- CodingKeys
- ExpressionPreset
- .extract()
- String
- AvatarTests
- AvatarSceneView
- opencode.json
- .read()
- KeychainService
- KeychainError
- DatabaseManager
- Emotion
- CompanionApp
- SettingsViewModel
- NewCompanionView
- PerformanceDirector
- CatalogCache
- .setEmotion()
- .selectVoice()
- .computePCMEnergies()
- Pricing
- GazeSystem
- CodingKeys
- .concatenateBuffers()
- AppearanceApplier
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

## Communities (52 total, 8 thin omitted)

### Community 0 - "SceneKitAvatarController"
Cohesion: 0.06
Nodes (31): DispatchWorkItem, GLTFSCNAnimation, GLTFSCNSceneSource, AvatarDescriptor, URL, ActiveGesture, AvatarError, garmentLoadFailed (+23 more)

### Community 1 - "AvatarViewModel"
Cohesion: 0.08
Nodes (26): CADisplayLink, CFTimeInterval, PerformanceBeat, PerformanceTrack, Int, CompanionAvatarView, .body, .debugOverlay (+18 more)

### Community 2 - "OpenRouterClient"
Cohesion: 0.07
Nodes (34): AsyncThrowingStream, ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage (+26 more)

### Community 3 - "Foundation"
Cohesion: 0.06
Nodes (21): AVFoundation, Companion, Error, Foundation, GLTFKit2, STTError, noResult, unavailable (+13 more)

### Community 4 - "AudioRecorderService"
Cohesion: 0.08
Nodes (22): AnyObject, AppleSpeechSTTEngine, Bool, Data, SFSpeechRecognitionTask, String, URL, AudioRecorderService (+14 more)

### Community 5 - "ElevenLabsTTS"
Cohesion: 0.12
Nodes (23): AVAudioPlayer, AVAudioPlayerDelegate, ElevenLabsTTS, Data, Double, Error, Float, Int (+15 more)

### Community 6 - "AppearanceDelta"
Cohesion: 0.14
Nodes (12): Int64, AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, Bool (+4 more)

### Community 7 - "AvatarScene"
Cohesion: 0.16
Nodes (16): AnchorEntity, ARKit, ARView, Entity, AvatarScene, AvatarView, Coordinator, Context (+8 more)

### Community 8 - "MemoryStore"
Cohesion: 0.17
Nodes (11): GRDB, appearanceAttributes(), MemoryInfo, MemoryStore, personalityTraits(), Bool, Date, Double (+3 more)

### Community 9 - ".generateForCompanion()"
Cohesion: 0.12
Nodes (15): ImageGenerationService, Bool, Data, Int64, String, URL, FileCache, .cacheDir (+7 more)

### Community 10 - "Gesture"
Cohesion: 0.08
Nodes (21): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+13 more)

### Community 11 - "CodingKeys"
Cohesion: 0.08
Nodes (25): CodingKeys, architecture, b64Json, contextLength, delta, entries, finishReason, id (+17 more)

### Community 12 - "CatalogEntry"
Cohesion: 0.20
Nodes (10): CatalogEntry, ModelRole, chat, extract, image, SelectionPolicy, Bool, Double (+2 more)

### Community 13 - "Codable"
Cohesion: 0.19
Nodes (20): Codable, CatalogCacheData, CatalogResponse, ChatChunk, ChatResponse, ChunkChoice, Delta, ImageData (+12 more)

### Community 14 - ".systemPrompt()"
Cohesion: 0.16
Nodes (7): PersonaAssembler, Date, Double, String, PersonaAssemblerTests, Double, String

### Community 15 - "ChatViewModel"
Cohesion: 0.19
Nodes (12): AnyRegexOutput, .body, .inputBar, ChatMessage, ChatViewModel, Bool, Data, Int64 (+4 more)

### Community 16 - "TTSEngine"
Cohesion: 0.15
Nodes (13): AVSpeechSynthesizer, AVSpeechSynthesizerDelegate, AVSpeechUtterance, Bool, Double, NSRange, String, TimeInterval (+5 more)

### Community 17 - "AvatarThumbnail"
Cohesion: 0.15
Nodes (17): CGRect, Color, AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong (+9 more)

### Community 18 - "CatalogStatus"
Cohesion: 0.11
Nodes (19): CaseIterable, Equatable, CatalogStatus, cached, failed, fetched, refreshing, unknown (+11 more)

### Community 19 - "CompanionInfo"
Cohesion: 0.16
Nodes (12): Hasher, Identifiable, IndexSet, CompanionInfo, .level, CompanionRow, .body, CompanionsView (+4 more)

### Community 20 - "ChatView"
Cohesion: 0.16
Nodes (15): ChatPlaceholderView, .body, ContentView, .body, ChatView, .avatarAccessibilityLabel, .offlineBanner, .scrollView (+7 more)

### Community 21 - "AvatarController"
Cohesion: 0.21
Nodes (8): AvatarController, EmotionSystem, GestureSystem, IdleLifeSystem, ReactivitySystem, SecondaryMotionSystem, SCNVector3, String

### Community 22 - "SettingsView"
Cohesion: 0.17
Nodes (8): Bool, OnboardingView, .body, SettingsView, .body, .chatModels, Double, String

### Community 23 - "Viseme"
Cohesion: 0.19
Nodes (10): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem (+2 more)

### Community 24 - "WardrobeSlot"
Cohesion: 0.23
Nodes (9): Hashable, Architecture, GarmentAsset, Set, WardrobeSlot, Bool, WardrobeSystem, RawRepresentable (+1 more)

### Community 25 - "CodingKeys"
Cohesion: 0.19
Nodes (15): CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount, voiceId (+7 more)

### Community 26 - "ExpressionPreset"
Cohesion: 0.14
Nodes (13): BlendShapeWeights, ExpressionPreset, amused, concerned, curious, excited, neutral, playful (+5 more)

### Community 27 - ".extract()"
Cohesion: 0.15
Nodes (3): Index, PerformanceTrackParser, StringProtocol

### Community 28 - "String"
Cohesion: 0.22
Nodes (13): AvatarDebugState, BlinkMapping, ExpressionWeights, GazeTarget, away, camera, idle, user (+5 more)

### Community 30 - "AvatarSceneView"
Cohesion: 0.26
Nodes (8): AvatarSceneView, Coordinator, Context, Coordinator, SCNView, Void, UITapGestureRecognizer, UIViewRepresentable

### Community 31 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 32 - ".read()"
Cohesion: 0.29
Nodes (4): CatalogFetcher, JSONDecoder, String, URLSession

### Community 33 - "KeychainService"
Cohesion: 0.29
Nodes (3): KeychainService, Bool, String

### Community 34 - "KeychainError"
Cohesion: 0.20
Nodes (9): CustomStringConvertible, KeychainError, .description, encodeFailed, invalidKeyFormat, readFailed, storeFailed, OSStatus (+1 more)

### Community 35 - "DatabaseManager"
Cohesion: 0.42
Nodes (5): DatabaseQueue, DatabaseManager, Bool, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 36 - "Emotion"
Cohesion: 0.20
Nodes (10): Emotion, affectionate, concerned, happy, neutral, playful, sad, surprised (+2 more)

### Community 37 - "CompanionApp"
Cohesion: 0.28
Nodes (8): App, CatalogRefreshChecker, CompanionApp, .body, Never, Task, Void, Scene

### Community 38 - "SettingsViewModel"
Cohesion: 0.25
Nodes (3): SettingsViewModel, .imageGenEnabled, Bool

### Community 39 - "NewCompanionView"
Cohesion: 0.31
Nodes (5): NewCompanionView, .body, Int64, String, Void

### Community 40 - "PerformanceDirector"
Cohesion: 0.39
Nodes (4): PerformanceDirector, Int, NSRange, String

### Community 41 - "CatalogCache"
Cohesion: 0.36
Nodes (3): CatalogCache, Bool, TimeInterval

### Community 43 - ".selectVoice()"
Cohesion: 0.33
Nodes (4): AVSpeechSynthesisVoice, AVSpeechSynthesisVoiceGender, String, VoicePicker

### Community 45 - "Pricing"
Cohesion: 0.60
Nodes (4): Decoder, Pricing, Double, KeyedDecodingContainer

### Community 47 - "CodingKeys"
Cohesion: 0.40
Nodes (5): CodingKey, CodingKeys, companionId, text, type

## Knowledge Gaps
- **155 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `emptyAudio` (+150 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 267 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `ChatViewModel` to `KeychainService`, `OpenRouterClient`, `Foundation`, `AudioRecorderService`, `ElevenLabsTTS`, `AvatarViewModel`, `MemoryStore`, `CatalogCache`, `.generateForCompanion()`, `Gesture`, `CatalogEntry`, `TTSEngine`, `AppearanceApplier`, `CompanionInfo`, `ChatView`?**
  _High betweenness centrality (0.223) - this node is a cross-community bridge._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `SceneKitAvatarController`, `Foundation`, `Emotion`, `PerformanceDirector`, `.setEmotion()`, `Gesture`, `GazeSystem`, `ChatViewModel`, `AvatarController`, `Viseme`, `WardrobeSlot`, `String`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Foundation` to `OpenRouterClient`, `DatabaseManager`, `AudioRecorderService`, `KeychainError`, `AppearanceDelta`, `MemoryStore`, `CatalogCache`, `.generateForCompanion()`, `Codable`, `.systemPrompt()`, `AppearanceApplier`, `WardrobeSlot`, `CodingKeys`, `ExpressionPreset`, `String`?**
  _High betweenness centrality (0.142) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _155 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `SceneKitAvatarController` be split into smaller, more focused modules?**
  _Cohesion score 0.058416139716952725 - nodes in this community are weakly interconnected._