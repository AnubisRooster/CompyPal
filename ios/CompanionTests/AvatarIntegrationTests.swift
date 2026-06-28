import Foundation
import Testing
import SceneKit
@testable import Companion

private final class _BundleAnchor {}

@Suite("Avatar integration — real GLB load through SceneKit")
struct AvatarIntegrationTests {
    @Test @MainActor
    func rivenGLBLoadsWithMorpherIndexPopulated() async throws {
        let controller = SceneKitAvatarController()
        let bundle = Bundle(identifier: "ai.companion.app") ?? Bundle(for: _BundleAnchor.self)

        let glbURL = try #require(
            bundle.url(forResource: "riven", withExtension: "glb"),
            "riven.glb must be in the app bundle resources"
        )
        let mappingURL = try #require(
            bundle.url(forResource: "RigMapping", withExtension: "json"),
            "RigMapping.json must be in the app bundle resources"
        )

        try await controller.load(AvatarDescriptor(glbURL: glbURL, rigMappingURL: mappingURL))

        #expect(controller.isGLBLoaded, "GLB should load successfully")
        #expect(controller.morpherIndexCount >= 300,
                "Expected ≥300 morpher bindings for Riven (7 primitives × 57 names). Got: \(controller.morpherIndexCount)")

        #expect(controller.morpherIndexUniqueNameCount >= 57,
                "Riven has at least 57 unique morph target names (plus viseme aliases). Got: \(controller.morpherIndexUniqueNameCount)")

        for name in ["Fcl_MTH_A", "Fcl_MTH_I", "Fcl_EYE_Close_L", "Fcl_ALL_Joy"] {
            #expect(controller.morpherIndexContains(name),
                    "Critical morph name '\(name)' must be in index")
        }

        let mthAEntries = controller.morpherEntriesCount(for: "Fcl_MTH_A")
        #expect(mthAEntries == 7,
                "Fcl_MTH_A should drive all 7 face primitives in parallel. Got: \(mthAEntries)")
    }
}
