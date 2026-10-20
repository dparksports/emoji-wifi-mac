import XCTest
@testable import EmojiWifi

final class PasswordGeneratorTests: XCTestCase {
    func testLengthIsClampedTo8And63() {
        XCTAssertEqual(PasswordGenerator.generateWiFiPassword(length: 3).count, 8)
        XCTAssertEqual(PasswordGenerator.generateWiFiPassword(length: 100).count, 63)
        XCTAssertEqual(PasswordGenerator.generateWiFiPassword(length: 20).count, 20)
    }

    func testReturnsEmptyWhenNoCharacterClassSelected() {
        XCTAssertEqual(
            PasswordGenerator.generateWiFiPassword(length: 20, includeUppercase: false, includeLowercase: false, includeNumbers: false, includeSpecialChars: false),
            ""
        )
    }

    func testGuaranteesAtLeastOneCharacterPerSelectedClass() {
        for _ in 0..<20 {
            let password = PasswordGenerator.generateWiFiPassword(length: 8)
            XCTAssertTrue(password.contains(where: { $0.isLowercase }))
            XCTAssertTrue(password.contains(where: { $0.isUppercase }))
            XCTAssertTrue(password.contains(where: { $0.isNumber }))
            XCTAssertTrue(password.contains { "!@#$%^&*()_+-=[]{}|:.,<>?;".contains($0) })
        }
    }

    func testUsesOnlySelectedClasses() {
        let password = PasswordGenerator.generateWiFiPassword(
            length: 30, includeUppercase: false, includeLowercase: true, includeNumbers: false, includeSpecialChars: false
        )
        XCTAssertEqual(password.count, 30)
        XCTAssertTrue(password.allSatisfy { $0.isLowercase })
    }

    func testSpecialsOnlyPasswordUsesSpecialCharset() {
        let charset = Set("!@#$%^&*()_+-=[]{}|:.,<>?;")
        let password = PasswordGenerator.generateWiFiPassword(
            length: 40, includeUppercase: false, includeLowercase: false, includeNumbers: false, includeSpecialChars: true
        )
        XCTAssertTrue(password.allSatisfy { charset.contains($0) })
    }
}
