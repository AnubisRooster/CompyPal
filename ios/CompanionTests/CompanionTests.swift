import Foundation
import Testing
@testable import Companion

struct CompanionTests {
    @Test func decodePricingAsString() throws {
        let json = """
        {"prompt": "0.000005", "completion": "0.00003", "image": "0.0001", "per_request": "0.0"}
        """.data(using: .utf8)!
        let pricing = try JSONDecoder().decode(Pricing.self, from: json)
        #expect(pricing.prompt == 0.000005)
        #expect(pricing.completion == 0.00003)
        #expect(pricing.image == 0.0001)
        #expect(pricing.perRequest == 0.0)
    }

    @Test func decodePricingAsDoubleFallback() throws {
        let json = """
        {"prompt": 0.000005, "completion": 0.00003}
        """.data(using: .utf8)!
        let pricing = try JSONDecoder().decode(Pricing.self, from: json)
        #expect(pricing.prompt == 0.000005)
        #expect(pricing.completion == 0.00003)
    }

    @Test func decodeCatalogEntryWithArchitecture() throws {
        let json = """
        {
            "id": "openai/gpt-4o",
            "name": "GPT-4o",
            "pricing": {"prompt": "0.000005", "completion": "0.00003"},
            "context_length": 128000,
            "architecture": {"input_modalities": ["text"], "output_modalities": ["text"]},
            "supported_parameters": ["streaming", "tools"]
        }
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CatalogEntry.self, from: json)
        #expect(entry.id == "openai/gpt-4o")
        #expect(entry.architecture?.inputModalities == ["text"])
        #expect(entry.architecture?.outputModalities == ["text"])
        #expect(entry.supportedParameters == ["streaming", "tools"])
    }

    @Test func decodeCatalogEntryWithoutArchitecture() throws {
        let json = """
        {
            "id": "basic/model",
            "name": "Basic",
            "pricing": {"prompt": "0", "completion": "0"},
            "context_length": 4096
        }
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CatalogEntry.self, from: json)
        #expect(entry.id == "basic/model")
        #expect(entry.architecture == nil)
    }

    @Test func decodeChatResponseNonStreaming() throws {
        let json = """
        {
            "choices": [
                {"message": {"content": "Hello!"}, "finish_reason": "stop"}
            ]
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatResponse.self, from: json)
        #expect(response.choices?.first?.message.content == "Hello!")
    }

    @Test func stripCodeFences() throws {
        let fenced = "```json\n{\"key\": \"value\"}\n```"
        let stripped = MemoryExtractor.stripCodeFences(fenced)
        #expect(stripped == "{\"key\": \"value\"}")
    }

    @Test func stripNoFences() throws {
        let plain = "{\"key\": \"value\"}"
        let stripped = MemoryExtractor.stripCodeFences(plain)
        #expect(stripped == "{\"key\": \"value\"}")
    }

    @Test func isValidKeyValidatesOpenRouterKey() {
        #expect(KeychainService.isValidKey("sk-or-v1-abcdefghijklmnopqrstuv") == true)
        #expect(KeychainService.isValidKey("sk-or-v1-abc") == false, "too short")
        #expect(KeychainService.isValidKey("sk-ant-abc123") == false, "wrong prefix")
        #expect(KeychainService.isValidKey("") == false)
        #expect(KeychainService.isValidKey("  sk-or-v1-abcdefghijklmnopqrstuv  ") == true, "trims whitespace")
    }
}
