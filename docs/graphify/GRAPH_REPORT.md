# Graph Report - CompyPal  (2026-10-26)

## Corpus Check
- 74 files · ~118,728 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: .plist 2, (none) 1, .jsonl 1)

## Summary
- 1061 nodes · 2253 edges · 66 communities (43 shown, 23 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 320 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- AvatarViewModel
- OpenRouterClient
- Foundation
- AvatarScene
- ElevenLabsTTS
- MemoryStore
- AppleSpeechSTTEngine
- AppearanceDelta
- ChatView
- CodingKeys
- SettingsViewModel
- SceneKitAvatarController
- .generateForCompanion()
- .systemPrompt()
- Gesture
- AvatarThumbnail
- Codable
- CatalogEntry
- TTSEngine
- PerformanceDirector
- CodingKeys
- Viseme
- .ensureUser()
- .extract()
- AvatarTests
- String
- CompanionInfo
- SettingsView
- WardrobeSlot
- AvatarSceneView
- opencode.json
- ChatModels.swift
- .setEmotion()
- DatabaseManager
- AvatarController
- Emotion
- BehaviorSystems.swift
- AvatarError
- String
- CompanionApp
- KeychainError
- SwiftUI
- CatalogCache
- KeychainService
- GestureSystem
- project.yml
- properties
- AvatarDescriptor
- TimeInterval
- CompanionTests
- CatalogFetcher
- NewCompanionView
- Companion
- Pricing
- GazeSystem
- settings
- .frameModel()
- options
- ModelRole
- dependencies
- preBuildScripts
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
- `.body` --calls--> `ContentView`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/App/ContentView.swift
- `CatalogRefreshChecker` --calls--> `CatalogCache`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/LLM/Catalog/CatalogCache.swift
- `CatalogRefreshChecker` --calls--> `CatalogFetcher`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/LLM/Catalog/CatalogFetcher.swift
- `CatalogRefreshChecker` --calls--> `KeychainService`  [INFERRED]
  ios/Companion/App/CompanionApp.swift → ios/Companion/Core/Storage/KeychainService.swift
- `.body` --calls--> `CompanionsView`  [INFERRED]
  ios/Companion/App/ContentView.swift → ios/Companion/Features/Companions/CompanionsView.swift

## Import Cycles
- None detected.

## Communities (66 total, 23 thin omitted)

### Community 0 - "AvatarViewModel"
Cohesion: 0.05
Nodes (11): AudioRecorderService, .body, AvatarViewModel, DevelopmentAvatarPreview, .appearanceView, .emotionGrid, .sequenceView, .body (+3 more)

### Community 1 - "OpenRouterClient"
Cohesion: 0.07
Nodes (20): ClientError, .description, .errorDescription, httpError, invalidResponse, noKey, serverMessage, unauthorized (+12 more)

### Community 2 - "Foundation"
Cohesion: 0.06
Nodes (17): AVFoundation, Companion, Foundation, STTError, noResult, unavailable, VoicePicker, CatalogError (+9 more)

### Community 3 - "AvatarScene"
Cohesion: 0.07
Nodes (17): ARKit, AvatarScene, AvatarView, Coordinator, BlendShapeWeights, ExpressionPreset, amused, concerned (+9 more)

### Community 4 - "ElevenLabsTTS"
Cohesion: 0.11
Nodes (8): ElevenLabsTTS, TTSError, decodeFailed, emptyAudio, .errorDescription, http, missingKey, Voice

### Community 5 - "MemoryStore"
Cohesion: 0.16
Nodes (8): GRDB, appearanceAttributes(), MemoryStore, personalityTraits(), AppearanceApplier, from, url, GRDB

### Community 6 - "AppleSpeechSTTEngine"
Cohesion: 0.09
Nodes (6): AppleSpeechSTTEngine, STTEngine, STTEngineType, appleSpeech, whisper, WhisperSTTEngine

### Community 7 - "AppearanceDelta"
Cohesion: 0.15
Nodes (7): AppearanceDelta, AttributeDef, AttributeType, color, `enum`, ParametricSchema, ParametricSchemaTests

### Community 8 - "ChatView"
Cohesion: 0.11
Nodes (17): ChatPlaceholderView, .body, ContentView, .body, CompanionAvatarView, .body, ChatView, .avatarAccessibilityLabel (+9 more)

### Community 9 - "CodingKeys"
Cohesion: 0.08
Nodes (25): CodingKeys, architecture, b64Json, contextLength, delta, entries, finishReason, id (+17 more)

### Community 10 - "SettingsViewModel"
Cohesion: 0.10
Nodes (16): CatalogStatus, cached, failed, fetched, refreshing, unknown, ConnectionStatus, failed (+8 more)

### Community 11 - "SceneKitAvatarController"
Cohesion: 0.12
Nodes (5): SceneKitAvatarController, .availableClipNames, .isGLBLoaded, .morpherIndexCount, .morpherIndexUniqueNameCount

### Community 12 - ".generateForCompanion()"
Cohesion: 0.15
Nodes (4): ImageGenerationService, FileCache, .cacheDir, .body

### Community 13 - ".systemPrompt()"
Cohesion: 0.16
Nodes (3): MemoryInfo, PersonaAssembler, PersonaAssemblerTests

### Community 14 - "Gesture"
Cohesion: 0.10
Nodes (21): Gesture, bow, dance, handToChest, idle, jump, laugh, leanBack (+13 more)

### Community 15 - "AvatarThumbnail"
Cohesion: 0.15
Nodes (9): AvatarThumbnail, .eyeColor, .hairColor, .hairLength, .hairStyle, .isLong, .renderedFace, .skinColor (+1 more)

### Community 16 - "Codable"
Cohesion: 0.21
Nodes (14): Architecture, CatalogCacheData, CatalogResponse, ChatChunk, ChatRequest, ChatResponse, ChunkChoice, Delta (+6 more)

### Community 17 - "CatalogEntry"
Cohesion: 0.24
Nodes (4): CatalogEntry, SelectionPolicy, .chatModels, SelectionPolicyTests

### Community 18 - "TTSEngine"
Cohesion: 0.13
Nodes (3): TTSEngine, .isPaused, completion

### Community 19 - "PerformanceDirector"
Cohesion: 0.18
Nodes (6): GazeTarget, away, camera, idle, user, PerformanceDirector

### Community 20 - "CodingKeys"
Cohesion: 0.19
Nodes (12): CodingKeys, appearance, companionId, name, relationshipStage, traits, turnCount, voiceId (+4 more)

### Community 21 - "Viseme"
Cohesion: 0.23
Nodes (8): Viseme, aa, ee, ih, oh, ou, sil, LipSyncSystem

### Community 26 - "String"
Cohesion: 0.26
Nodes (8): AvatarDebugState, BlinkMapping, ExpressionWeights, PerformanceBeat, PerformanceTrack, PersonalityMotionProfile, RigMapping, WardrobeMapping

### Community 27 - "CompanionInfo"
Cohesion: 0.21
Nodes (5): CompanionInfo, .level, CompanionRow, .body, CompanionsView

### Community 29 - "WardrobeSlot"
Cohesion: 0.28
Nodes (3): GarmentAsset, WardrobeSlot, WardrobeSystem

### Community 31 - "opencode.json"
Cohesion: 0.15
Nodes (12): autoupdate, options, instructions, model, apiKey, permission, bash, edit (+4 more)

### Community 32 - "ChatModels.swift"
Cohesion: 0.24
Nodes (9): CodingKeys, companionId, text, type, ServerDone, ServerEmotion, ServerError, ServerToken (+1 more)

### Community 35 - "DatabaseManager"
Cohesion: 0.31
Nodes (3): DatabaseManager, migrationCreatesTables(), storeReadWriteRoundtrip()

### Community 37 - "Emotion"
Cohesion: 0.18
Nodes (10): Emotion, affectionate, concerned, happy, neutral, playful, sad, surprised (+2 more)

### Community 39 - "AvatarError"
Cohesion: 0.18
Nodes (4): AvatarError, garmentLoadFailed, garmentNotFound, glbLoadFailed

### Community 41 - "CompanionApp"
Cohesion: 0.24
Nodes (3): CatalogRefreshChecker, CompanionApp, .body

### Community 42 - "KeychainError"
Cohesion: 0.20
Nodes (7): KeychainError, .description, encodeFailed, invalidKeyFormat, readFailed, storeFailed, Security

### Community 43 - "SwiftUI"
Cohesion: 0.22
Nodes (4): GLTFKit2, OSLog, SceneKit, SwiftUI

### Community 47 - "GestureSystem"
Cohesion: 0.25
Nodes (3): .debugOverlay, GestureSystem, .gestureGrid

### Community 48 - "project.yml"
Cohesion: 0.22
Nodes (8): from, url, name, packages, GLTFKit2, settings, SWIFT_VERSION, targets

### Community 49 - "properties"
Cohesion: 0.22
Nodes (9): properties, CFBundleDisplayName, CFBundleName, CFBundleShortVersionString, CFBundleVersion, NSMicrophoneUsageDescription, NSSpeechRecognitionUsageDescription, UIApplicationSupportsIndirectInputEvents (+1 more)

### Community 52 - "CompanionTests"
Cohesion: 0.25
Nodes (8): platform, settings, sources, type, GENERATE_INFOPLIST_FILE, PRODUCT_BUNDLE_IDENTIFIER, TEST_TARGET_NAME, CompanionTests

### Community 55 - "Companion"
Cohesion: 0.29
Nodes (7): info, platform, sources, type, path, path, Companion

### Community 59 - "settings"
Cohesion: 0.33
Nodes (6): settings, CODE_SIGN_STYLE, CURRENT_PROJECT_VERSION, DEVELOPMENT_TEAM, INFOPLIST_FILE, MARKETING_VERSION

### Community 61 - "options"
Cohesion: 0.40
Nodes (5): iOS, options, bundleIdPrefix, deploymentTarget, xcodeVersion

### Community 62 - "ModelRole"
Cohesion: 0.50
Nodes (4): ModelRole, chat, extract, image

### Community 63 - "dependencies"
Cohesion: 0.50
Nodes (4): dependencies, dependencies, package, target

### Community 64 - "preBuildScripts"
Cohesion: 0.50
Nodes (4): preBuildScripts, basedOnDependencyAnalysis, name, script

## Knowledge Gaps
- **151 isolated node(s):** `.body`, `unavailable`, `noResult`, `missingKey`, `http` (+146 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 338 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatViewModel` connect `AvatarViewModel` to `OpenRouterClient`, `Foundation`, `ElevenLabsTTS`, `MemoryStore`, `ChatView`, `.generateForCompanion()`, `CatalogCache`, `KeychainService`, `Gesture`, `CatalogEntry`, `TTSEngine`, `CompanionInfo`?**
  _High betweenness centrality (0.220) - this node is a cross-community bridge._
- **Are the 14 inferred relationships involving `AvatarViewModel` (e.g. with `.debugOverlay` and `AvatarDebugState`) actually correct?**
  _`AvatarViewModel` has 14 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `unavailable`, `noResult` to the rest of the system?**
  _151 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `AvatarViewModel` be split into smaller, more focused modules?**
  _Cohesion score 0.05041797283176593 - nodes in this community are weakly interconnected._
- **Why does `AvatarViewModel` connect `AvatarViewModel` to `Foundation`, `.setEmotion()`, `Emotion`, `BehaviorSystems.swift`, `ChatView`, `SceneKitAvatarController`, `GestureSystem`, `AvatarDescriptor`, `PerformanceDirector`, `Viseme`, `GazeSystem`, `String`, `WardrobeSlot`?**
  _High betweenness centrality (0.147) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `ChatViewModel` (e.g. with `.inputBar` and `AudioRecorderService`) actually correct?**
  _`ChatViewModel` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Should `OpenRouterClient` be split into smaller, more focused modules?**
  _Cohesion score 0.06887755102040816 - nodes in this community are weakly interconnected._