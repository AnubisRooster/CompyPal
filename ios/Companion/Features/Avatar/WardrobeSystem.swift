import Foundation

// MARK: - WardrobeSystem (A6)

@MainActor
final class WardrobeSystem {
    private weak var controller: AvatarController?
    private var equippedGarments: [WardrobeSlot: GarmentAsset] = [:]

    init(controller: AvatarController) {
        self.controller = controller
    }

    func equip(_ garment: GarmentAsset) async throws {
        try await controller?.attachGarment(garment)
        equippedGarments[garment.slot] = garment
    }

    func unequip(slot: WardrobeSlot) {
        controller?.detachGarment(slot: slot)
        equippedGarments[slot] = nil
    }

    func garment(for slot: WardrobeSlot) -> GarmentAsset? {
        equippedGarments[slot]
    }

    func allEquipped() -> [WardrobeSlot: GarmentAsset] {
        equippedGarments
    }

    func isSlotOccupied(_ slot: WardrobeSlot) -> Bool {
        equippedGarments[slot] != nil
    }
}
