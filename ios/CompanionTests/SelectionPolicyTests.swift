import Testing
@testable import Companion

struct SelectionPolicyTests {
    let freeModel = CatalogEntry(
        id: "free/chat",
        name: "Free Chat",
        pricing: .zero,
        contextLength: 4096,
        modalities: Modalities(input: ["text"], output: ["text"]),
        supportedParameters: ["streaming", "tools"]
    )

    let cheapModel = CatalogEntry(
        id: "cheap/chat",
        name: "Cheap Chat",
        pricing: Pricing(prompt: 0.0001, completion: 0.0002, image: nil, perRequest: nil),
        contextLength: 8192,
        modalities: Modalities(input: ["text"], output: ["text"]),
        supportedParameters: ["streaming", "tools"]
    )

    let expensiveModel = CatalogEntry(
        id: "expensive/chat",
        name: "Expensive Chat",
        pricing: Pricing(prompt: 0.002, completion: 0.006, image: nil, perRequest: nil),
        contextLength: 16384,
        modalities: Modalities(input: ["text", "image"], output: ["text"]),
        supportedParameters: ["streaming"]
    )

    let imageModel = CatalogEntry(
        id: "image/model",
        name: "Image Generator",
        pricing: Pricing(prompt: 0.01, completion: 0.01, image: 0.05, perRequest: nil),
        contextLength: nil,
        modalities: Modalities(input: ["text", "image"], output: ["image"]),
        supportedParameters: ["input_references", "streaming"]
    )

    let nonStreamingModel = CatalogEntry(
        id: "basic/chat",
        name: "Basic Chat",
        pricing: .zero,
        contextLength: 2048,
        modalities: Modalities(input: ["text"], output: ["text"]),
        supportedParameters: nil
    )

    @Test func freeModelRanksFirstForChat() {
        let policy = SelectionPolicy(role: .chat, catalog: [cheapModel, freeModel, expensiveModel], pinnedModelId: nil)
        let ranked = policy.rank()
        #expect(ranked.first?.id == "free/chat")
    }

    @Test func cheapestPaidModelAfterFree() {
        let policy = SelectionPolicy(role: .chat, catalog: [expensiveModel, cheapModel, freeModel], pinnedModelId: nil)
        let ranked = policy.rank()
        #expect(ranked[0].id == "free/chat")
        #expect(ranked[1].id == "cheap/chat")
        #expect(ranked[2].id == "expensive/chat")
    }

    @Test func pinnedModelAlwaysFirst() {
        let policy = SelectionPolicy(role: .chat, catalog: [freeModel, expensiveModel, cheapModel], pinnedModelId: "expensive/chat")
        let ranked = policy.rank()
        #expect(ranked.first?.id == "expensive/chat")
    }

    @Test func bestReturnsTopFreeModel() {
        let policy = SelectionPolicy(role: .chat, catalog: [expensiveModel, cheapModel, freeModel], pinnedModelId: nil)
        let best = policy.best()
        #expect(best?.id == "free/chat")
    }

    @Test func imageModelFilteredByRole() {
        let policy = SelectionPolicy(role: .image, catalog: [freeModel, imageModel, cheapModel], pinnedModelId: nil)
        let ranked = policy.rank()
        #expect(ranked.allSatisfy { $0.modalities?.output?.contains("image") ?? false })
        #expect(ranked.contains { $0.id == "image/model" })
    }

    @Test func nonStreamingModelMeetsChatRole() {
        let policy = SelectionPolicy(role: .chat, catalog: [nonStreamingModel], pinnedModelId: nil)
        let ranked = policy.rank()
        #expect(ranked.contains { $0.id == "basic/chat" })
    }

    @Test func emptyCatalogReturnsNilBest() {
        let policy = SelectionPolicy(role: .chat, catalog: [], pinnedModelId: nil)
        #expect(policy.best() == nil)
    }

    @Test func toolCallingModelFilteredByExtractRole() {
        let noToolsModel = CatalogEntry(
            id: "no-tools/model",
            name: "No Tools",
            pricing: .zero,
            contextLength: 4096,
            modalities: Modalities(input: ["text"], output: ["text"]),
            supportedParameters: ["streaming"]
        )
        let hasToolsModel = CatalogEntry(
            id: "tools/model",
            name: "Has Tools",
            pricing: .zero,
            contextLength: 4096,
            modalities: Modalities(input: ["text"], output: ["text"]),
            supportedParameters: ["tools"]
        )
        let policy = SelectionPolicy(role: .extract, catalog: [noToolsModel, hasToolsModel], pinnedModelId: nil)
        let ranked = policy.rank()
        #expect(ranked.count == 1)
        #expect(ranked.first?.id == "tools/model")
    }
}
