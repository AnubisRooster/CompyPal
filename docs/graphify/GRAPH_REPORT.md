# Graph Report - CompyPal  (2026-11-16)

## Corpus Check
- 74 files · ~122,063 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: .plist 2, (none) 1, .jsonl 1)

## Summary
- 1080 nodes · 2248 edges · 73 communities (51 shown, 22 thin omitted)
- Extraction: 85% EXTRACTED · 15% INFERRED · 0% AMBIGUOUS · INFERRED: 331 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- ChatViewModel
- AvatarTests
- Foundation
- AvatarScene
- ElevenLabsTTS
- AppleSpeechSTTEngine
- AppearanceDelta
- SceneKitAvatarController
- Hashable
- AvatarController
- AvatarViewModel
- MemoryStore
- CatalogEntry
- .systemPrompt()
- AvatarThumbnail
- Gesture
- CodingKey
- CompanionInfo
- String
- Viseme
- Codable
- SettingsViewModel
- ChatView
- CompanionTests
- ClientError
- WardrobeSlot
- opencode.json
- Message
- SettingsView
- .generateForCompanion()
- PerformanceDirector
- AvatarError
- CompanionApp
- Pricing
- DatabaseManager
- ChatModels.swift
- FileCache
- Emotion
- ExpressionPreset
- String
- OpenRouterClient
- GazeTarget
- project.yml
- CatalogFetcher
- properties
- KeychainError
- CompanionsViewModel
- CatalogCache
- AvatarDescriptor
- TimeInterval
- CatalogStatus
- CompanionTests
- CodingKeys
- NewCompanionView
- Companion
- packages
- ConnectionStatus
- MemoryStore.swift
- CodingKeys
- AppearanceIntentParser
- settings
- CaseIterable
- BlendShapeWeights
- .frameModel()
- dependencies
- preBuildScripts
- Package.swift

## God Nodes (most connected - your core abstractions)
1. `SceneKitAvatarController` - 76 edges
2. `AvatarViewModel` - 55 edges
3. `ChatViewModel` - 48 edges
4. `Gesture` - 40 edges
5. `MemoryStore` - 32 edges
6. `Emotion` - 30 edges
7. `AvatarController` - 30 edges
8. `AvatarTests` - 29 edges
9. `CatalogEntry` - 28 edges
10. `ElevenLabsTTS` - 23 edges

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

## Communities (73 total, 22 thin omitted)

### Community 0 - "ChatViewModel"
Cohesion: 0.06
Nodes (10): AudioRecorderService, DevelopmentAvatarPreview, .appearanceView, .emotionGrid, .gestureGrid, .sequenceView, .body, .inputBar (+2 more)

### Community 1 - "AvatarTests"
Cohesion: 0.05
Nodes (5): TTSEngine, .isPaused, completion, PerformanceTrackParser, AvatarTests

### Community 2 - "Foundation"
Cohesion: 0.06
Nodes (19): AVFoundation, Companion, Foundation, GLTFKit2, STTError, noResult, unavailable, VoicePicker (+11 more)

### Community 3 - "AvatarScene"
Cohesion: 0.09
Nodes (7): ARKit, AvatarScene, AvatarView, Coordinator, AvatarSceneView, Coordinator, RealityKit

### Community 4 - "ElevenLabsTTS"
Cohesion: 0.10
Nodes (8): ElevenLabsTTS, TTSError, decodeFailed, emptyAudio, .errorDescription, http, missingKey, Voice

### Community 5 - "AppleSpeechSTTEngine"
Cohesion: 0.09
Nodes (6): AppleSpeechSTTEngine, STTEngine, STTEngineType, appleSpeech, whisper, WhisperSTTEngine

### Community 6 - "AppearanceDelta"
Cohesion: 0.15
Nodes (7): AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, ParametricSchemaTests

### Community 7 - "SceneKitAvatarController"
Cohesion: 0.13
Nodes (5): SceneKitAvatarController, .availableClipNames, .isGLBLoaded, .morpherIndexCount, .morpherIndexUniqueNameCount

### Community 8 - "Hashable"
Cohesion: 0.12
Nodes (19): CompanionState, CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount (+11 more)

### Community 9 - "AvatarController"
Cohesion: 0.15
Nodes (7): AvatarController, EmotionSystem, GazeSystem, GestureSystem, IdleLifeSystem, ReactivitySystem, SecondaryMotionSystem

### Community 10 - "AvatarViewModel"
Cohesion: 0.14
Nodes (3): .body, .debugOverlay, AvatarViewModel

### Community 12 - "CatalogEntry"
Cohesion: 0.20
Nodes (7): CatalogEntry, ModelRole, chat, extract, image, SelectionPolicy, SelectionPolicyTests

### Community 13 - ".systemPrompt()"
Cohesion: 0.16
Nodes (3): MemoryInfo, PersonaAssembler, PersonaAssemblerTests

### Community 14 - "AvatarThumbnail"
Cohesion: 0.14
Nodes (9): AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong, .renderedFace, .skinColor (+1 more)

### Community 15 - "Gesture"
Cohesion: 0.10
Nodes (21): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+13 more)

### Community 16 - "CodingKey"
Cohesion: 0.10
Nodes (19): CodingKeys, entries, lastRefreshed, CodingKeys, architecture, contextLength, id, name (+11 more)

### Community 17 - "CompanionInfo"
Cohesion: 0.16
Nodes (9): ChatPlaceholderView, .body, ContentView, .body, CompanionInfo, .level, CompanionRow, .body (+1 more)

### Community 18 - "String"
Cohesion: 0.18
Nodes (9): Architecture, CodingKeys, inputModalities, outputModalities, AvatarDebugState, ExpressionWeights, PerformanceBeat, PerformanceTrack (+1 more)

### Community 19 - "Viseme"
Cohesion: 0.22
Nodes (8): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem

### Community 20 - "Codable"
Cohesion: 0.26
Nodes (13): CatalogCacheData, CatalogResponse, ChatChunk, ChatResponse, ChunkChoice, Delta, ImageData, ImageResponse (+5 more)

### Community 21 - "SettingsViewModel"
Cohesion: 0.18
Nodes (4): KeychainService, SettingsViewModel, .imageGenEnabled, Security

### Community 22 - "ChatView"
Cohesion: 0.15
Nodes (11): CompanionAvatarView, .body, ChatView, .avatarAccessibilityLabel, .companionHeader, .offlineBanner, .scrollView, DotLoader (+3 more)

### Community 24 - "CompanionTests"
Cohesion: 0.15
Nodes (3): Extraction, MemoryExtractor, CompanionTests

### Community 25 - "ClientError"
Cohesion: 0.18
Nodes (9): ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage, unauthorized (+1 more)

### Community 26 - "WardrobeSlot"
Cohesion: 0.28
Nodes (3): GarmentAsset, WardrobeSlot, WardrobeSystem

### Community 27 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 28 - "Message"
Cohesion: 0.21
Nodes (7): ChatRequest, CodingKeys, maxTokens, messages, model, stream, Message

### Community 29 - "SettingsView"
Cohesion: 0.24
Nodes (5): OnboardingView, .body, SettingsView, .body, .chatModels

### Community 32 - "AvatarError"
Cohesion: 0.17
Nodes (4): AvatarError, garmentLoadFailed, garmentNotFound, glbLoadFailed

### Community 33 - "CompanionApp"
Cohesion: 0.22
Nodes (4): CatalogRefreshChecker, CompanionApp, .body, OSLog

### Community 34 - "Pricing"
Cohesion: 0.22
Nodes (5): Pricing, CodingKeys, image, perRequest, prompt

### Community 35 - "DatabaseManager"
Cohesion: 0.29
Nodes (3): DatabaseManager, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 36 - "ChatModels.swift"
Cohesion: 0.27
Nodes (9): ServerDone, ServerEmotion, ServerError, ServerToken, UserMessage, CodingKeys, companionId, text (+1 more)

### Community 38 - "Emotion"
Cohesion: 0.18
Nodes (10): Emotion, affectionate, concerned, happy, neutral, playful, sad, surprised (+2 more)

### Community 39 - "ExpressionPreset"
Cohesion: 0.18
Nodes (11): ExpressionPreset, amused, concerned, curious, excited, neutral, playful, serious (+3 more)

### Community 44 - "GazeTarget"
Cohesion: 0.22
Nodes (5): GazeTarget, away, camera, idle, user

### Community 45 - "project.yml"
Cohesion: 0.20
Nodes (9): iOS, name, options, bundleIdPrefix, deploymentTarget, xcodeVersion, settings, SWIFT_VERSION (+1 more)

### Community 49 - "properties"
Cohesion: 0.22
Nodes (9): properties, CFBundleDisplayName, CFBundleName, CFBundleShortVersionString, CFBundleVersion, NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription, UIApplicationSupportsIndirectInputEvents (+1 more)

### Community 50 - "KeychainError"
Cohesion: 0.25
Nodes (6): KeychainError, .description, encodeFailed, invalidKeyFormat, readFailed, storeFailed

### Community 55 - "CatalogStatus"
Cohesion: 0.25
Nodes (6): CatalogStatus, cached, failed, fetched, refreshing, unknown

### Community 56 - "CompanionTests"
Cohesion: 0.25
Nodes (8): platform, settings, sources, type, GENERATE_INFOPLIST_FILE, PRODUCT_BUNDLE_IDENTIFIER, TEST_TARGET_NAME, CompanionTests

### Community 57 - "CodingKeys"
Cohesion: 0.29
Nodes (6): ImageRequest, CodingKeys, model, n, prompt, size

### Community 59 - "Companion"
Cohesion: 0.29
Nodes (7): info, platform, sources, type, path, path, Companion

### Community 60 - "packages"
Cohesion: 0.29
Nodes (7): from, url, from, url, packages, GLTFKit2, GRDB

### Community 61 - "ConnectionStatus"
Cohesion: 0.33
Nodes (5): ConnectionStatus, failed, idle, success, testing

### Community 62 - "MemoryStore.swift"
Cohesion: 0.60
Nodes (3): GRDB, appearanceAttributes(), personalityTraits()

### Community 63 - "CodingKeys"
Cohesion: 0.33
Nodes (6): CodingKeys, inputReferences, model, n, prompt, size

### Community 65 - "settings"
Cohesion: 0.33
Nodes (6): settings, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, DEVELOPMENT_TEAM, INFOPLIST_FILE, MARKETING_VERSION

### Community 67 - "CaseIterable"
Cohesion: 0.40
Nodes (3): ModelMode, auto, pinned

### Community 70 - "dependencies"
Cohesion: 0.50
Nodes (4): dependencies, dependencies, package, target

### Community 71 - "preBuildScripts"
Cohesion: 0.50
Nodes (4): preBuildScripts, basedOnDependencyAnalysis, name, script

## Knowledge Gaps
- **159 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `http` (+154 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 347 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **22 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `ChatViewModel` to `AppearanceIntentParser`, `AvatarTests`, `Foundation`, `ElevenLabsTTS`, `OpenRouterClient`, `MemoryStore`, `CatalogEntry`, `AvatarViewModel`, `.read()`, `Gesture`, `CompanionInfo`, `CatalogCache`, `SettingsViewModel`, `ChatView`, `CompanionTests`, `.generateForCompanion()`?**
  _High betweenness centrality (0.195) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _159 weakly-connected nodes found - possible missing edges._
- **Should `ChatViewModel` be split into smaller, more focused modules?**
  _Cohesion score 0.05754475703324808 - nodes in this community are weakly interconnected._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `ChatViewModel`, `Foundation`, `Emotion`, `SceneKitAvatarController`, `AvatarController`, `.setEmotion()`, `GazeTarget`, `.playGesture()`, `String`, `Viseme`, `AvatarDescriptor`, `ChatView`, `WardrobeSlot`, `PerformanceDirector`?**
  _High betweenness centrality (0.134) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Should `AvatarTests` be split into smaller, more focused modules?**
  _Cohesion score 0.050816696914700546 - nodes in this community are weakly interconnected._