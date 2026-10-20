import Foundation

/// Builds and parses the "WIFI:" QR-code payload per the Wi-Fi Network Config
/// format (https://github.com/zxing/zxing/wiki/Wi-Fi-Network-Config-Format).
/// Inside the SSID and password the characters \ ; , : " must be
/// backslash-escaped, and fields are separated by unescaped semicolons —
/// otherwise phones mis-parse the password.
enum WiFiQRPayload {
    static func build(ssid: String, password: String, authType: String = "WPA", hidden: Bool = false) -> String {
        let hiddenFlag = hidden ? "true" : "false"
        return "WIFI:T:\(authType);S:\(escape(ssid));P:\(escape(password));H:\(hiddenFlag);"
    }

    static func parse(_ payload: String) -> (ssid: String?, password: String?) {
        guard payload.hasPrefix("WIFI:") else {
            return (nil, nil)
        }

        var ssid: String?
        var password: String?

        for field in splitFields(String(payload.dropFirst(5))) {
            // Fields look like "K:value" with a single-letter key.
            guard field.count >= 2, field.dropFirst().first == ":" else {
                continue
            }

            let key = field.first
            let value = unescape(String(field.dropFirst(2)))
            if key == "S" {
                ssid = value
            } else if key == "P" {
                password = value
            }
        }

        return (ssid, password)
    }

    static func escape(_ value: String) -> String {
        var escaped = String()
        escaped.reserveCapacity(value.count)
        for c in value {
            if c == "\\" || c == ";" || c == "," || c == ":" || c == "\"" {
                escaped.append("\\")
            }
            escaped.append(c)
        }
        return escaped
    }

    private static func splitFields(_ body: String) -> [String] {
        var fields: [String] = []
        var field = String()
        var isEscaped = false

        for c in body {
            if isEscaped {
                field.append(c)
                isEscaped = false
            } else if c == "\\" {
                field.append(c)
                isEscaped = true
            } else if c == ";" {
                fields.append(field)
                field = ""
            } else {
                field.append(c)
            }
        }

        fields.append(field)
        return fields
    }

    private static func unescape(_ value: String) -> String {
        var unescaped = String()
        unescaped.reserveCapacity(value.count)
        var isEscaped = false

        for c in value {
            if isEscaped {
                unescaped.append(c)
                isEscaped = false
            } else if c == "\\" {
                isEscaped = true
            } else {
                unescaped.append(c)
            }
        }

        if isEscaped {
            // Trailing lone backslash — keep it verbatim.
            unescaped.append("\\")
        }

        return unescaped
    }
}
