import XCTest
@testable import EmojiWifi

final class EmojiCatalogTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        EmojiWiFiGenerator.initializeFromCSV()
    }

    func testCatalogLoadedWithFullUnicode14Pool() {
        XCTAssertGreaterThanOrEqual(EmojiWiFiGenerator.catalog.count, 1300)
        XCTAssertEqual(EmojiWiFiGenerator.catalog.count, EmojiWiFiGenerator.singleEmojis.count)
        XCTAssertEqual(Set(EmojiWiFiGenerator.catalog.map { $0.emoji }).count, EmojiWiFiGenerator.catalog.count, "catalog emojis must be unique")
        XCTAssertFalse(EmojiWiFiGenerator.catalogCategories.isEmpty)
        XCTAssertGreaterThanOrEqual(EmojiWiFiGenerator.catalogCategories.count, 8)
        XCTAssertTrue(EmojiWiFiGenerator.catalog.allSatisfy { !$0.emoji.isEmpty && !$0.name.isEmpty })
    }

    func testDescriptionComesFromCatalog() {
        XCTAssertEqual(EmojiWiFiGenerator.getSingleEmojiDescription("🍕"), "Pizza")
        XCTAssertFalse(EmojiWiFiGenerator.getSingleEmojiDescription("📶").isEmpty)
    }

    func testFindUsedEmojisDetectsEmojisInsidePastNames() {
        let used = EmojiWiFiGenerator.findUsedEmojis(in: ["🍕🍕🍕", "🚀 Café", "plain text network"])
        XCTAssertTrue(used.contains("🍕"))
        XCTAssertTrue(used.contains("🚀"))
        XCTAssertFalse(used.contains("🎉"))
        XCTAssertTrue(EmojiWiFiGenerator.findUsedEmojis(in: []).isEmpty)
    }

    func testRandomSingleEmojiExcludesUsedEmojis() {
        let excluded = Set(Array(EmojiWiFiGenerator.singleEmojis.prefix(20)))
        for _ in 0..<50 {
            XCTAssertFalse(excluded.contains(EmojiWiFiGenerator.randomSingleEmoji(excluding: excluded)))
        }
    }

    func testRandomSingleEmojiFallsBackWhenEverythingExcluded() {
        let everything = Set(EmojiWiFiGenerator.singleEmojis)
        XCTAssertFalse(EmojiWiFiGenerator.randomSingleEmoji(excluding: everything).isEmpty)
    }

    func testGeneratedNamesStayWithin32ByteSsidLimit() {
        for _ in 0..<100 {
            let name = EmojiWiFiGenerator.generateRandomLengthEmojiWiFiName()
            XCTAssertLessThanOrEqual(name.utf8.count, EmojiWiFiGenerator.ssidMaxBytes)
        }
    }

    func testThemedCombinationsAreDeterministicAndFresh() {
        let first = EmojiWiFiGenerator.generateThemedCombinations()
        let second = EmojiWiFiGenerator.generateThemedCombinations()
        XCTAssertGreaterThanOrEqual(first.count, 40, "six themed combos per category")
        XCTAssertEqual(first.count, second.count, "themed combos must be identical across runs")
        XCTAssertTrue(zip(first, second).allSatisfy { $0.name == $1.name && $0.emojis == $1.emojis },
                      "themed combos must be identical across runs")

        let curated = Set(EmojiWiFiGenerator.emojiCombinations.map { $0.emojis })
        XCTAssertTrue(first.allSatisfy { !curated.contains($0.emojis) }, "themed combos must not duplicate curated ones")
        XCTAssertTrue(first.allSatisfy { $0.emojis.utf8.count <= EmojiWiFiGenerator.ssidMaxBytes })
    }

    func testGetAllCombinationsIncludesCuratedAndThemed() {
        let all = EmojiWiFiGenerator.getAllCombinations()
        XCTAssertGreaterThanOrEqual(all.count, EmojiWiFiGenerator.emojiCombinations.count + 40)
        XCTAssertFalse(all.isEmpty)
    }
}
