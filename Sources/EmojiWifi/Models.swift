import Foundation
import AppKit
import CoreImage.CIFilterBuiltins
import CoreImage

// MARK: - Password Generator
class PasswordGenerator {
    private static let lowerCase = "abcdefghijklmnopqrstuvwxyz"
    private static let upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let digits = "0123456789"
    private static let special = "!@#$%^&*()_+-=[]{}|:.,<>?;"

    /// Mirrors the Windows app: length clamped to 8–63, at least one
    /// character from every selected class, rest from the union, shuffled.
    static func generateWiFiPassword(length: Int = 62, includeUppercase: Bool = true, includeLowercase: Bool = true, includeNumbers: Bool = true, includeSpecialChars: Bool = true) -> String {
        let clampedLength = min(max(length, 8), 63)
        var classes: [String] = []
        if includeLowercase { classes.append(lowerCase) }
        if includeUppercase { classes.append(upperCase) }
        if includeNumbers { classes.append(digits) }
        if includeSpecialChars { classes.append(special) }
        guard !classes.isEmpty else { return "" }

        var chars: [Character] = classes.map { $0.randomElement()! }
        let union = classes.joined()
        while chars.count < clampedLength {
            chars.append(union.randomElement()!)
        }
        chars.shuffle()
        return String(chars)
    }
}

// MARK: - QR Code Generator
class QRCodeGenerator {
    static func generateWiFiQRCode(ssid: String, password: String) -> NSImage? {
        let wifiString = WiFiQRPayload.build(ssid: ssid, password: password)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(wifiString.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: 300, height: 300))
    }

    static func parseWiFiQRCode(_ qrString: String) -> (ssid: String?, password: String?) {
        return WiFiQRPayload.parse(qrString)
    }
}

// MARK: - WiFi Joiner
class WiFiJoiner {
    static func joinWiFi(ssid: String, password: String, completion: @escaping (String) -> Void) {
        let interface: String = "en0"
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setairportnetwork", interface, ssid, password]
        task.standardOutput = pipe
        task.standardError = pipe
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8), !output.isEmpty { print("Output: \(output)") }
                if task.terminationStatus == 0 {
                    DispatchQueue.main.async { completion("✅ Successfully joined network: \(ssid)!") }
                } else {
                    DispatchQueue.main.async { completion("❌ Failed to join network. Exit code: \(task.terminationStatus)") }
                }
            } catch {
                DispatchQueue.main.async { completion("⚠️ Error running networksetup: \(error)") }
            }
        }
    }
}

// MARK: - WiFi History
struct WiFiHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let wifiName: String
    let password: String
    let description: String
    let source: String
    let timestamp: Date
    
    init(id: UUID = UUID(), wifiName: String, password: String, description: String, source: String, timestamp: Date = Date()) {
        self.id = id; self.wifiName = wifiName; self.password = password
        self.description = description; self.source = source; self.timestamp = timestamp
    }
}

class HistoryManager: ObservableObject {
    static let maxEntries = 50

    @Published var entries: [WiFiHistoryEntry] = []

    private let directory: URL?

    private var fileURL: URL {
        let appDir: URL
        if let custom = directory {
            appDir = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            appDir = appSupport.appendingPathComponent("EmojiWifi")
        }
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("history.json")
    }

    init(directory: URL? = nil) {
        self.directory = directory
        load()
    }

    func addEntry(wifiName: String, password: String, description: String, source: String) {
        let entry = WiFiHistoryEntry(wifiName: wifiName, password: password, description: description, source: source)
        entries.insert(entry, at: 0)
        if entries.count > HistoryManager.maxEntries {
            entries.removeLast(entries.count - HistoryManager.maxEntries)
        }
        save()
    }
    
    func deleteEntry(_ entry: WiFiHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }
    
    func clearAll() { entries.removeAll(); save() }
    
    private func save() {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) { try? data.write(to: fileURL) }
    }
    
    private func load() {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([WiFiHistoryEntry].self, from: data) else { return }
        entries = decoded
    }
}
