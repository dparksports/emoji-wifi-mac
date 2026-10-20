import XCTest
@testable import EmojiWifi

final class HistoryManagerTests: XCTestCase {
    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testAddEntryPersistsAndReloads() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let manager = HistoryManager(directory: dir)
        manager.addEntry(wifiName: "🍕🍕🍕", password: "pw-one", description: "Pizza WiFi", source: "generated")
        manager.addEntry(wifiName: "🚀🛰️🌌", password: "pw-two", description: "Space Station", source: "scanned")

        let reloaded = HistoryManager(directory: dir)
        XCTAssertEqual(reloaded.entries.count, 2)
        XCTAssertEqual(reloaded.entries.first?.wifiName, "🚀🛰️🌌", "newest entry first")
        XCTAssertEqual(reloaded.entries.last?.password, "pw-one")
    }

    func testHistoryIsCappedAt50Entries() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let manager = HistoryManager(directory: dir)
        for i in 0..<55 {
            manager.addEntry(wifiName: "📶\(i)", password: "pw\(i)", description: "entry \(i)", source: "generated")
        }
        XCTAssertEqual(manager.entries.count, HistoryManager.maxEntries)
        XCTAssertEqual(manager.entries.first?.wifiName, "📶54", "newest entry survives the cap")
        XCTAssertEqual(manager.entries.last?.wifiName, "📶5", "oldest entries dropped")
    }

    func testDeleteEntryRemovesIt() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let manager = HistoryManager(directory: dir)
        manager.addEntry(wifiName: "🍕", password: "pw", description: "d", source: "generated")
        let entry = manager.entries[0]
        manager.deleteEntry(entry)
        XCTAssertTrue(manager.entries.isEmpty)

        let reloaded = HistoryManager(directory: dir)
        XCTAssertTrue(reloaded.entries.isEmpty)
    }
}
