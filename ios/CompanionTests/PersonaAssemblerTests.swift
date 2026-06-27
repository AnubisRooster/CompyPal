import Foundation
import Testing
@testable import Companion

struct PersonaAssemblerTests {
    let traits: [(String, Double)] = [("friendly", 0.9), ("curious", 0.4)]
    let appearance: [(String, String)] = [("hair_color", "brown"), ("eye_color", "green")]

    @Test func includesCompanionName() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: appearance,
            stage: "acquaintance"
        )
        #expect(prompt.contains("Luna"))
    }

    @Test func includesTraits() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: appearance,
            stage: "acquaintance"
        )
        #expect(prompt.contains("friendly"))
        #expect(prompt.contains("curious"))
    }

    @Test func includesAppearance() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: appearance,
            stage: "acquaintance"
        )
        #expect(prompt.contains("brown"))
        #expect(prompt.contains("green"))
    }

    @Test func acquaintanceDirective() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: appearance,
            stage: "acquaintance"
        )
        #expect(prompt.contains("first time"))
    }

    @Test func friendDirective() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: appearance,
            stage: "friend"
        )
        #expect(prompt.contains("know each other well"))
    }

    @Test func confidantDirective() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: appearance,
            stage: "confidant"
        )
        #expect(prompt.contains("close confidants"))
    }

    @Test func includesMemories() {
        let memories = [
            MemoryInfo(content: "User loves jazz", kind: "preference", salience: 0.9, createdAt: Date()),
            MemoryInfo(content: "User has a cat named Mochi", kind: "fact", salience: 0.8, createdAt: Date()),
        ]
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: memories,
            appearance: appearance,
            stage: "friend"
        )
        #expect(prompt.contains("jazz"))
        #expect(prompt.contains("Mochi"))
    }

    @Test func noMemoriesShowsFallback() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: appearance,
            stage: "acquaintance"
        )
        #expect(prompt.contains("No prior memories yet"))
    }

    @Test func intensityDescriptions() {
        let highTrait = [("wise", 0.95)]
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: highTrait,
            memories: [],
            appearance: [],
            stage: "acquaintance"
        )
        #expect(prompt.contains("very"))
    }

    @Test func emptyAppearanceShowsDefault() {
        let prompt = PersonaAssembler.systemPrompt(
            companionName: "Luna",
            traits: traits,
            memories: [],
            appearance: [],
            stage: "acquaintance"
        )
        #expect(prompt.contains("default"))
    }
}
