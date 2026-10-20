import XCTest
@testable import EmojiWifi

final class WiFiQRPayloadTests: XCTestCase {
    func testBuildEscapesSpecialCharacters() {
        XCTAssertEqual(
            WiFiQRPayload.build(ssid: "a;b:c", password: "p\\d,e\"f"),
            "WIFI:T:WPA;S:a\\;b\\:c;P:p\\\\d\\,e\\\"f;H:false;"
        )
    }

    func testParseRoundTripsSpecialCharacters() {
        let ssid = "net;work:\"name\""
        let password = "pa\\ss;wo:rd,123!"

        let parsed = WiFiQRPayload.parse(WiFiQRPayload.build(ssid: ssid, password: password))

        XCTAssertEqual(parsed.ssid, ssid)
        XCTAssertEqual(parsed.password, password)
    }

    func testParseRoundTripsEmojiSsid() {
        let parsed = WiFiQRPayload.parse(WiFiQRPayload.build(ssid: "🍕🎉🚀", password: "correct horse battery"))

        XCTAssertEqual(parsed.ssid, "🍕🎉🚀")
        XCTAssertEqual(parsed.password, "correct horse battery")
    }

    func testParseReadsPasswordContainingColonAndComma() {
        // Regression: these characters are in the generated password charset and
        // previously broke the naive semicolon split.
        let parsed = WiFiQRPayload.parse("WIFI:T:WPA;S:home;P:ab:cd,ef;;")

        XCTAssertEqual(parsed.ssid, "home")
        XCTAssertEqual(parsed.password, "ab:cd,ef")
    }

    func testParseReturnsNilForNonWifiPayload() {
        let parsed = WiFiQRPayload.parse("https://example.com")

        XCTAssertNil(parsed.ssid)
        XCTAssertNil(parsed.password)
    }

    func testParseIgnoresUnknownFieldsAndKeepsValues() {
        let parsed = WiFiQRPayload.parse("WIFI:T:WPA;S:cafe;P:secret;H:true;X:extra;")

        XCTAssertEqual(parsed.ssid, "cafe")
        XCTAssertEqual(parsed.password, "secret")
    }

    func testBuildWithHiddenAndAuthType() {
        let payload = WiFiQRPayload.build(ssid: "net", password: "pw", authType: "WEP", hidden: true)
        XCTAssertEqual(payload, "WIFI:T:WEP;S:net;P:pw;H:true;")
        let parsed = WiFiQRPayload.parse(payload)
        XCTAssertEqual(parsed.ssid, "net")
        XCTAssertEqual(parsed.password, "pw")
    }
}
