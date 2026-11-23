# Graph Report - CompyPal  (2026-11-23)

## Corpus Check
- 74 files · ~122,830 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: .plist 2, (none) 1, .jsonl 1)

## Summary
- 1080 nodes · 2249 edges · 74 communities (49 shown, 25 thin omitted)
- Extraction: 85% EXTRACTED · 15% INFERRED · 0% AMBIGUOUS · INFERRED: 331 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- AvatarTests
- ChatViewModel
- Foundation
- AvatarScene
- ElevenLabsTTS
- AppleSpeechSTTEngine
- CodingKey
- AppearanceDelta
- AvatarViewModel
- SceneKitAvatarController
- CodingKeys
- .systemPrompt()
- AvatarThumbnail
- MemoryStore
- ChatView
- Gesture
- Codable
- AvatarController
- WardrobeSlot
- CompanionInfo
- CatalogEntry
- Viseme
- CompanionTests
- ClientError
- String
- .setEnabled()
- SettingsView
- KeychainService
- opencode.json
- SettingsViewModel
- Message
- .generateForCompanion()
- AvatarError
- CompanionApp
- Pricing
- DatabaseManager
- ChatModels.swift
- FileCache
- Emotion
- ExpressionPreset
- String
- CatalogFetcher
- OpenRouterClient
- project.yml
- ReactivitySystem
- properties
- KeychainError
- CatalogCache
- GazeTarget
- TimeInterval
- CatalogStatus
- CompanionTests
- AvatarDescriptor
- NewCompanionView
- Companion
- packages
- ConnectionStatus
- MemoryStore.swift
- CodingKeys
- AppearanceIntentParser
- settings
- CaseIterable
- .apply()
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

## Communities (74 total, 25 thin omitted)

### Community 0 - "AvatarTests"
Cohesion: 0.05
Nodes (5): TTSEngine, .isPaused, completion, PerformanceTrackParser, AvatarTests

### Community 1 - "ChatViewModel"
Cohesion: 0.08
Nodes (10): AudioRecorderService, PerformanceTrack, DevelopmentAvatarPreview, .emotionGrid, .gestureGrid, .sequenceView, .body, .inputBar (+2 more)

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

### Community 6 - "CodingKey"
Cohesion: 0.07
Nodes (27): CodingKeys, inputModalities, outputModalities, CodingKeys, entries, lastRefreshed, CodingKeys, architecture (+19 more)

### Community 7 - "AppearanceDelta"
Cohesion: 0.15
Nodes (7): AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, ParametricSchemaTests

### Community 8 - "AvatarViewModel"
Cohesion: 0.14
Nodes (6): CompanionAvatarView, .debugOverlay, AvatarViewModel, .appearanceView, .body, .companionHeader

### Community 9 - "SceneKitAvatarController"
Cohesion: 0.12
Nodes (5): SceneKitAvatarController, .availableClipNames, .isGLBLoaded, .morpherIndexCount, .morpherIndexUniqueNameCount

### Community 10 - "CodingKeys"
Cohesion: 0.12
Nodes (19): CompanionState, CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount (+11 more)

### Community 11 - ".systemPrompt()"
Cohesion: 0.16
Nodes (3): MemoryInfo, PersonaAssembler, PersonaAssemblerTests

### Community 12 - "AvatarThumbnail"
Cohesion: 0.14
Nodes (9): AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong, .renderedFace, .skinColor (+1 more)

### Community 14 - "ChatView"
Cohesion: 0.14
Nodes (14): ChatPlaceholderView, .body, ContentView, .body, ChatView, .avatarAccessibilityLabel, .offlineBanner, .scrollView (+6 more)

### Community 15 - "Gesture"
Cohesion: 0.10
Nodes (21): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+13 more)

### Community 16 - "Codable"
Cohesion: 0.20
Nodes (15): CatalogCacheData, CatalogResponse, ChatChunk, ChatResponse, ChunkChoice, Delta, ImageData, ImageRequest (+7 more)

### Community 17 - "AvatarController"
Cohesion: 0.19
Nodes (7): AvatarController, PersonalityMotionProfile, EmotionSystem, GazeSystem, GestureSystem, IdleLifeSystem, PerformanceDirector

### Community 18 - "WardrobeSlot"
Cohesion: 0.20
Nodes (4): Architecture, GarmentAsset, WardrobeSlot, WardrobeSystem

### Community 19 - "CompanionInfo"
Cohesion: 0.16
Nodes (5): CompanionInfo, .level, CompanionsView, .body, CompanionsViewModel

### Community 20 - "CatalogEntry"
Cohesion: 0.27
Nodes (3): CatalogEntry, SelectionPolicy, SelectionPolicyTests

### Community 22 - "Viseme"
Cohesion: 0.23
Nodes (8): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem

### Community 24 - "CompanionTests"
Cohesion: 0.15
Nodes (3): Extraction, MemoryExtractor, CompanionTests

### Community 25 - "ClientError"
Cohesion: 0.18
Nodes (9): ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage, unauthorized (+1 more)

### Community 26 - "String"
Cohesion: 0.22
Nodes (7): AvatarDebugState, ExpressionWeights, PerformanceBeat, RigMapping, BlinkMapping, WardrobeMapping, StringProtocol

### Community 28 - "SettingsView"
Cohesion: 0.23
Nodes (5): OnboardingView, .body, SettingsView, .body, .chatModels

### Community 30 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 32 - "Message"
Cohesion: 0.21
Nodes (7): ChatRequest, CodingKeys, maxTokens, messages, model, stream, Message

### Community 34 - "AvatarError"
Cohesion: 0.17
Nodes (4): AvatarError, garmentLoadFailed, garmentNotFound, glbLoadFailed

### Community 35 - "CompanionApp"
Cohesion: 0.22
Nodes (4): CatalogRefreshChecker, CompanionApp, .body, OSLog

### Community 36 - "Pricing"
Cohesion: 0.22
Nodes (5): Pricing, CodingKeys, image, perRequest, prompt

### Community 37 - "DatabaseManager"
Cohesion: 0.29
Nodes (3): DatabaseManager, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 38 - "ChatModels.swift"
Cohesion: 0.27
Nodes (9): ServerDone, ServerEmotion, ServerError, ServerToken, UserMessage, CodingKeys, companionId, text (+1 more)

### Community 40 - "Emotion"
Cohesion: 0.18
Nodes (10): Emotion, affectionate, concerned, happy, neutral, playful, sad, surprised (+2 more)

### Community 41 - "ExpressionPreset"
Cohesion: 0.18
Nodes (11): ExpressionPreset, amused, concerned, curious, excited, neutral, playful, serious (+3 more)

### Community 46 - "project.yml"
Cohesion: 0.20
Nodes (9): iOS, name, options, bundleIdPrefix, deploymentTarget, xcodeVersion, settings, SWIFT_VERSION (+1 more)

### Community 48 - "properties"
Cohesion: 0.22
Nodes (9): properties, CFBundleDisplayName, CFBundleName, CFBundleShortVersionString, CFBundleVersion, NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription, UIApplicationSupportsIndirectInputEvents (+1 more)

### Community 49 - "KeychainError"
Cohesion: 0.25
Nodes (6): KeychainError, .description, encodeFailed, invalidKeyFormat, readFailed, storeFailed

### Community 51 - "GazeTarget"
Cohesion: 0.29
Nodes (5): GazeTarget, away, camera, idle, user

### Community 53 - "CatalogStatus"
Cohesion: 0.25
Nodes (6): CatalogStatus, cached, failed, fetched, refreshing, unknown

### Community 54 - "CompanionTests"
Cohesion: 0.25
Nodes (8): platform, settings, sources, type, GENERATE_INFOPLIST_FILE, PRODUCT_BUNDLE_IDENTIFIER, TEST_TARGET_NAME, CompanionTests

### Community 58 - "Companion"
Cohesion: 0.29
Nodes (7): info, platform, sources, type, path, path, Companion

### Community 59 - "packages"
Cohesion: 0.29
Nodes (7): from, url, from, url, packages, GLTFKit2, GRDB

### Community 60 - "ConnectionStatus"
Cohesion: 0.33
Nodes (5): ConnectionStatus, failed, idle, success, testing

### Community 61 - "MemoryStore.swift"
Cohesion: 0.60
Nodes (3): GRDB, appearanceAttributes(), personalityTraits()

### Community 62 - "CodingKeys"
Cohesion: 0.33
Nodes (6): CodingKeys, inputReferences, model, n, prompt, size

### Community 64 - "settings"
Cohesion: 0.33
Nodes (6): settings, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, DEVELOPMENT_TEAM, INFOPLIST_FILE, MARKETING_VERSION

### Community 66 - "CaseIterable"
Cohesion: 0.40
Nodes (3): ModelMode, auto, pinned

### Community 71 - "dependencies"
Cohesion: 0.50
Nodes (4): dependencies, dependencies, package, target

### Community 72 - "preBuildScripts"
Cohesion: 0.50
Nodes (4): preBuildScripts, basedOnDependencyAnalysis, name, script

## Knowledge Gaps
- **159 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `http` (+154 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 347 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `ChatViewModel` to `AvatarTests`, `.generateForCompanion()`, `Foundation`, `.apply()`, `ElevenLabsTTS`, `AvatarViewModel`, `OpenRouterClient`, `ChatView`, `MemoryStore`, `Gesture`, `CatalogCache`, `CompanionInfo`, `CatalogEntry`, `CompanionTests`, `SettingsViewModel`, `KeychainService`, `AppearanceIntentParser`?**
  _High betweenness centrality (0.195) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _159 weakly-connected nodes found - possible missing edges._
- **Should `AvatarTests` be split into smaller, more focused modules?**
  _Cohesion score 0.05137844611528822 - nodes in this community are weakly interconnected._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `ChatViewModel`, `Foundation`, `.playGesture()`, `Emotion`, `SceneKitAvatarController`, `ReactivitySystem`, `AvatarController`, `WardrobeSlot`, `GazeTarget`, `.setEmotion()`, `Viseme`, `.setGaze()`, `String`, `.setEnabled()`?**
  _High betweenness centrality (0.134) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Should `ChatViewModel` be split into smaller, more focused modules?**
  _Cohesion score 0.07993966817496229 - nodes in this community are weakly interconnected._