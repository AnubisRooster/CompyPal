import Foundation
import Testing
import SceneKit
@testable import Companion

@Suite("Avatar integration — real GLB load through SceneKit")
struct AvatarIntegrationTests {
    @Test @MainActor
    func rivenGLBLoadsWithMorpherIndexPopulated() async throws {
        let controller = SceneKitAvatarController()
        guard let glbURL = Bundle.main.url(forResource: "riven", withExtension: "glb") else {
            Issue.record("riven.glb not found in main bundle")
            return
        }
        guard let mappingURL = Bundle.main.url(forResource: "RigMapping", withExtension: "json") else {
            Issue.record("RigMapping.json not found in main bundle")
            return
        }

        try await controller.load(AvatarDescriptor(glbURL: glbURL, rigMappingURL: mappingURL))

        #expect(controller.isGLBLoaded, "GLB should load successfully")

        if controller.morpherIndexCount < 300 {
            Issue.record("""
                Expected ≥300 morpher bindings for Riven (7 primitives × 57 names).
                Got: \(controller.morpherIndexCount) bindings, \(controller.morpherIndexUniqueNameCount) unique names.
                This means the multi-morpher pairing in recoverMorphTargetNames is not
                producing the expected parallel morpher entries.
                """)
            return
        }

        let morphCount = controller.morpherIndexUniqueNameCount
        #expect(morphCount >= 57,
                "Riven has at least 57 unique morph target names (plus viseme aliases). Got: \(morphCount)")

        for name in ["Fcl_MTH_A", "Fcl_MTH_I", "Fcl_EYE_Close_L", "Fcl_ALL_Joy"] {
            #expect(controller.morpherIndexContains(name),
                    "Critical morph name '\(name)' must be in index")
        }
    }
}
