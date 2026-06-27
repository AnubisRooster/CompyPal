import Foundation
import Testing
@testable import Companion

struct ParametricSchemaTests {
    let schema = ParametricSchema.shared

    @Test func validSkinToneAccepted() {
        let delta = AppearanceDelta(attribute: "skin_tone", value: "tan", declined: nil, suggestion: nil)
        let result = schema.validate(delta: delta)
        #expect(result.declined != true)
        #expect(result.value == "tan")
    }

    @Test func validEyeColorAccepted() {
        let delta = AppearanceDelta(attribute: "eye_color", value: "green", declined: nil, suggestion: nil)
        let result = schema.validate(delta: delta)
        #expect(result.declined != true)
        #expect(result.value == "green")
    }

    @Test func invalidValueGetsClosestMatch() {
        let delta = AppearanceDelta(attribute: "hair_color", value: "blonde", declined: nil, suggestion: nil)
        let result = schema.validate(delta: delta)
        #expect(result.value == "blonde")
    }

    @Test func typosGetCorrected() {
        let delta = AppearanceDelta(attribute: "eye_color", value: "gren", declined: nil, suggestion: nil)
        let result = schema.validate(delta: delta)
        #expect(result.value == "green")
    }

    @Test func unknownAttributeDeclined() {
        let delta = AppearanceDelta(attribute: "height", value: "tall", declined: nil, suggestion: nil)
        let result = schema.validate(delta: delta)
        #expect(result.declined == true)
    }

    @Test func unknownValueNoCloseMatch() {
        let delta = AppearanceDelta(attribute: "hair_color", value: "rainbow", declined: nil, suggestion: nil)
        let result = schema.validate(delta: delta)
        #expect(result.suggestion != nil)
        #expect(result.declined == true)
    }

    @Test func colorForValidAttribute() {
        let color = schema.color(for: "eye_color", value: "blue")
        #expect(color != nil)
    }

    @Test func colorForInvalidAttributeReturnsNil() {
        let color = schema.color(for: "eye_color", value: "purple")
        #expect(color == nil)
    }

    @Test func allKeysIncludesExpected() {
        let keys = schema.allKeys()
        #expect(keys.contains("skin_tone"))
        #expect(keys.contains("eye_color"))
        #expect(keys.contains("hair_color"))
        #expect(keys.contains("hair_length"))
        #expect(keys.contains("hair_style"))
    }

    @Test func nearbyMatch() {
        let delta = AppearanceDelta(attribute: "hair_color", value: "blak", declined: nil, suggestion: nil)
        let result = schema.validate(delta: delta)
        #expect(result.value == "black")
    }
}
