import Foundation
import SwiftUI

struct ParametricSchema {
    let attributes: [AttributeDef]

    static let shared = ParametricSchema(attributes: [
        AttributeDef(key: "skin_tone", label: "Skin Tone", type: .color, values: [
            "light": UIColor(red: 0.95, green: 0.82, blue: 0.72, alpha: 1),
            "medium": UIColor(red: 0.85, green: 0.65, blue: 0.50, alpha: 1),
            "tan": UIColor(red: 0.73, green: 0.53, blue: 0.37, alpha: 1),
            "dark": UIColor(red: 0.45, green: 0.30, blue: 0.20, alpha: 1),
        ]),
        AttributeDef(key: "hair_color", label: "Hair Color", type: .color, values: [
            "brown": UIColor(red: 0.40, green: 0.25, blue: 0.15, alpha: 1),
            "black": UIColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1),
            "blonde": UIColor(red: 0.92, green: 0.82, blue: 0.60, alpha: 1),
            "red": UIColor(red: 0.80, green: 0.30, blue: 0.15, alpha: 1),
            "white": UIColor(red: 0.90, green: 0.88, blue: 0.85, alpha: 1),
            "blue": UIColor(red: 0.30, green: 0.50, blue: 0.85, alpha: 1),
            "green": UIColor(red: 0.25, green: 0.70, blue: 0.35, alpha: 1),
            "purple": UIColor(red: 0.60, green: 0.30, blue: 0.75, alpha: 1),
        ]),
        AttributeDef(key: "eye_color", label: "Eye Color", type: .color, values: [
            "brown": UIColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 1),
            "blue": UIColor(red: 0.25, green: 0.45, blue: 0.80, alpha: 1),
            "green": UIColor(red: 0.20, green: 0.65, blue: 0.35, alpha: 1),
            "hazel": UIColor(red: 0.55, green: 0.45, blue: 0.20, alpha: 1),
            "gray": UIColor(red: 0.60, green: 0.60, blue: 0.65, alpha: 1),
            "amber": UIColor(red: 0.75, green: 0.55, blue: 0.15, alpha: 1),
        ]),
        AttributeDef(key: "hair_length", label: "Hair Length", type: .enum, values: [
            "short": .black, "medium": .black, "long": .black,
        ]),
        AttributeDef(key: "hair_style", label: "Hair Style", type: .enum, values: [
            "straight": .black, "wavy": .black, "curly": .black,
        ]),
    ])

    func validate(delta: AppearanceDelta) -> AppearanceDelta {
        guard let def = attributes.first(where: { $0.key == delta.attribute }) else {
            return AppearanceDelta(attribute: delta.attribute, value: nil, declined: true, suggestion: "unknown attribute")
        }
        if def.values.keys.contains(delta.value ?? "") {
            return delta
        }
        let closest = closestMatch(query: delta.value ?? "", in: Array(def.values.keys))
        return AppearanceDelta(
            attribute: delta.attribute,
            value: closest,
            declined: closest == nil,
            suggestion: closest.map { "I don't have that exact \(delta.attribute). How about \($0)?" }
                ?? "I can't change \(delta.attribute) right now."
        )
    }

    func allKeys() -> [String] { attributes.map { $0.key } }

    func color(for attribute: String, value: String) -> UIColor? {
        guard let def = attributes.first(where: { $0.key == attribute }),
              case .color = def.type
        else { return nil }
        return def.values[value] as? UIColor
    }

    private func closestMatch(query: String, in values: [String]) -> String? {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        if values.contains(q) { return q }
        let distances = values.map { (value: $0, dist: levenshtein(a: q, b: $0.lowercased())) }
        let best = distances.min { $0.dist < $1.dist }
        if let best, best.dist <= 2 { return best.value }
        return nil
    }

    private func levenshtein(a: String, b: String) -> Int {
        let empty = [Int](repeating: 0, count: b.count + 1)
        var last = [Int](0...b.count)
        for (i, ca) in a.enumerated() {
            var cur = [i + 1] + empty.dropLast()
            for (j, cb) in b.enumerated() {
                cur[j + 1] = ca == cb ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last!
    }
}

struct AttributeDef {
    let key: String
    let label: String
    let type: AttributeType
    let values: [String: UIColor]

    enum AttributeType {
        case color, `enum`
    }
}



struct AppearanceDelta: Codable {
    let attribute: String
    let value: String?
    let declined: Bool?
    let suggestion: String?

    init(attribute: String, value: String?, declined: Bool? = nil, suggestion: String? = nil) {
        self.attribute = attribute
        self.value = value
        self.declined = declined
        self.suggestion = suggestion
    }
}
