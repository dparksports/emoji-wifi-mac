import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins
import AVFoundation
import CoreImage
import CoreWLAN

// MARK: - Password Generator
class PasswordGenerator {
    static func generateWiFiPassword(length: Int = 62, includeUppercase: Bool = true, includeLowercase: Bool = true, includeNumbers: Bool = true, includeSpecialChars: Bool = true) -> String {
        var characters = ""
        
        if includeLowercase {
            characters += "abcdefghijklmnopqrstuvwxyz"
        }
        if includeUppercase {
            characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        if includeNumbers {
            characters += "0123456789"
        }
        if includeSpecialChars {
            characters += "!@#$%^&*()_+-=[]{}|;:.,<>?"
        }
        
        guard !characters.isEmpty else { return "" }
        
        var password = ""
        for _ in 0..<length {
            password += String(characters.randomElement()!)
        }
        
        return password
    }
}

// MARK: - QR Code Generator
class QRCodeGenerator {
    static func generateWiFiQRCode(ssid: String, password: String) -> NSImage? {
        let wifiString = "WIFI:T:WPA;S:\(ssid);P:\(password);H:false;;"
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(wifiString.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaleTransform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: scaleTransform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: 300, height: 300))
    }
    
    static func parseWiFiQRCode(_ qrString: String) -> (ssid: String?, password: String?) {
        // Use a more robust parsing approach that handles Unicode characters
        var ssid: String?
        var password: String?
        
        // Find the SSID part
        if let ssidRange = qrString.range(of: "S:") {
            let startIndex = ssidRange.upperBound
            if let endIndex = qrString.range(of: ";", range: startIndex..<qrString.endIndex) {
                ssid = String(qrString[startIndex..<endIndex.lowerBound])
            }
        }
        
        // Find the password part
        if let passwordRange = qrString.range(of: "P:") {
            let startIndex = passwordRange.upperBound
            if let endIndex = qrString.range(of: ";", range: startIndex..<qrString.endIndex) {
                password = String(qrString[startIndex..<endIndex.lowerBound])
            }
        }
        
        return (ssid, password)
    }
}

// MARK: - WiFi Joiner (from AutoJoin.swift)
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
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    print("Output: \(output)")
                }
                
                if task.terminationStatus == 0 {
                    DispatchQueue.main.async {
                        completion("✅ Successfully joined network: \(ssid)!")
                    }
                } else {
                    DispatchQueue.main.async {
                        completion("❌ Failed to join network. Exit code: \(task.terminationStatus)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion("⚠️ Error running networksetup: \(error)")
                }
            }
        }
    }
}

// MARK: - CSV Export/Import Functions (MODIFIED)

// Helper function to parse CSV lines with quoted fields
func parseCSVLine(_ line: String) -> [String] {
    var components: [String] = []
    var currentComponent = ""
    var inQuotes = false
    
    for (index, character) in line.enumerated() {
        if character == "\"" {
            if index + 1 < line.count && line[line.index(line.startIndex, offsetBy: index + 1)] == "\"" {
                currentComponent += "\""
            } else {
                inQuotes.toggle()
            }
        } else if character == "," && !inQuotes {
            components.append(currentComponent)
            currentComponent = ""
        } else {
            currentComponent += String(character)
        }
    }
    components.append(currentComponent)
    return components
}

func loadSingleEmojiDescriptionsFromCSV() -> [String: String] {
    var descriptions: [String: String] = [:]
    
    guard let url = Bundle.module.url(forResource: "single", withExtension: "csv") else {
        print("❌ Could not find single.csv in bundle")
        return descriptions
    }
    
    do {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let lines = csvContent.components(separatedBy: CharacterSet.newlines)
        
        for line in lines.dropFirst() {
            if line.isEmpty { continue }
            let components = parseCSVLine(line)
            if components.count >= 2 {
                let emoji = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let description = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                descriptions[emoji] = description
            }
        }
        print("✅ Loaded \(descriptions.count) emoji descriptions from single.csv")
    } catch {
        print("❌ Error loading single.csv: \(error)")
    }
    
    return descriptions
}


// 2. Load the CSV file combo.csv from embedded resources
func loadEmojiCombinationsFromCSV() -> [(name: String, emojis: String)] {
    var combinations: [(name: String, emojis: String)] = []
    guard let url = Bundle.module.url(forResource: "combos", withExtension: "csv") else { 
        print("❌ Could not find combos.csv in bundle")
        return combinations
    }
    do {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let lines = csvContent.components(separatedBy: CharacterSet.newlines)
        for line in lines.dropFirst() {
            if line.isEmpty { continue }
            let components = parseCSVLine(line)
            if components.count >= 2 {
                let name = components[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let emojis = components[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                combinations.append((name: name, emojis: emojis))
            }
        }
        print("✅ Loaded \(combinations.count) emoji combinations from embedded combos.csv")
    } catch { 
        print("❌ Error loading combos.csv: \(error)") 
    }
    return combinations
}

// MARK: - Emoji WiFi Name Generator (MODIFIED)
class EmojiWiFiGenerator {
    // Static properties to hold loaded data
    static var loadedDescriptions: [String: String] = [:]
    static var loadedCombinations: [(name: String, emojis: String)] = []
    
    // Initialize with data from embedded CSV files
    static func initializeFromCSV() {
        loadedDescriptions = loadSingleEmojiDescriptionsFromCSV()
        loadedCombinations = loadEmojiCombinationsFromCSV()
    }

    // Computed property for emojiCombinations
    static var emojiCombinations: [(name: String, emojis: String)] {
        return loadedCombinations.isEmpty ? [
            ("Tech Hub", "💻📶🌐"), ("Signal Strong", "📡⚡🔥"), ("Network Master", "🔗💾🎮"), ("Digital Space", "🌐💻📱"), ("WiFi Zone", "📶🔗💡"), ("Space Station", "🚀🛰️🌌"), ("Galaxy Network", "🌌⭐🌑"), ("Rocket WiFi", "🚀⚡💨"), ("Astronaut Zone", "👨‍🚀🛰️🌌"), ("Cosmic Signal", "⭐🌌📡"), ("Gaming Hub", "🎮🎵🎧"), ("Game Zone", "🎮⚔️🛡️"), ("Player One", "🎮👾🤖"), ("Gaming Station", "🎮🎸🎤"), ("Arcade WiFi", "🎮💾🔫"), ("Music Studio", "🎵🎧🎤"), ("Rock WiFi", "🎸🤘🎵"), ("Sound Wave", "🎵🌊🎧"), ("Music Zone", "🎤🎸🎵"), ("Audio Hub", "🎧🎵🎤"), ("Nature WiFi", "🌲🌻🌱"), ("Forest Signal", "🌲🏞️🌿"), ("Garden Network", "🌻🌱🌿"), ("Tree WiFi", "🌲🌳🌱"), ("Natural Zone", "🌿🌻🌱"), ("Food Network", "🍕🍔🍟"), ("Pizza WiFi", "🍕🍕🍕"), ("Burger Zone", "🍔🍟🥤"), ("Snack Hub", "🍟🍕🍰"), ("Foodie WiFi", "🍕🍔🍰"), ("Cool Zone", "😎🔥⚡"), ("Stylish WiFi", "😎💎✨"), ("Awesome Network", "😎👍🔥"), ("Epic WiFi", "🔥⚡💥"), ("Legendary Zone", "👑⚡🔥"), ("Dark Network", "🖤🌑👻"), ("Ghost WiFi", "👻💀🖤"), ("Mystery Zone", "🔮🌑👻"), ("Shadow Network", "🖤🌑👻"), ("Night WiFi", "🌙⭐👻"), ("Dark Vader", "🖤🤖⚔️"), ("Fun Zone", "😄🎉🎈"), ("Happy WiFi", "😊🌈✨"), ("Party Network", "🎉🎊🎈"), ("Joy Zone", "😄😊🎉"), ("Smile WiFi", "😊💖✨"), ("Cat Zone", "🐱😸🐾"), ("Dog WiFi", "🐶🐕🐾"), ("Panda Paradise", "🐼🎋🎍"), ("Animal Kingdom", "🐱🐶🐼"), ("Pet Network", "🐾🐱🐶"), ("Storm WiFi", "⛈️⚡🌧️"), ("Sunny Zone", "☀️🌞🌻"), ("Rainbow Network", "🌈☀️🌧️"), ("Weather Hub", "🌤️⛈️🌈"), ("Sky WiFi", "☁️🌤️🌈"), ("Love Zone", "💖💕💗"), ("Heart WiFi", "❤️💙💚"), ("Sweet Network", "💖🍰💕"), ("Romance Zone", "💕💖💗"), ("Love Hub", "❤️💕💖"), ("Power Zone", "⚡🔥💥"), ("Energy WiFi", "⚡🔋💡"), ("Lightning Fast", "⚡💨🚀"), ("Power Hub", "⚡🔥💥"), ("Energy Zone", "🔋⚡💡"), ("Simple WiFi", "✨💫⭐"), ("Clean Zone", "🤍✨💫"), ("Pure Network", "🤍💫✨"), ("Minimal WiFi", "✨🤍💫"), ("Clear Zone", "💫✨🤍")
        ] : loadedCombinations
    }
    
    // Computed property for singleEmojis
    static var singleEmojis: [String] {
        return loadedDescriptions.isEmpty ? [
            "📶", "📡", "💻", "📱", "🌐", "🔗", "💾", "🎮", "🚀", "🛰️", "🌌", "🌑", "⭐", "👨‍🚀", "🤖", "👾", "⚔️", "🛡️", "🔫", "💥", "🖤", "❤️", "💙", "💚", "💜", "🤍", "🎵", "🎧", "🎤", "🎸", "🍕", "🍔", "🍟", "🍰", "🌲", "🏞️", "🌻", "🐱", "🐶", "🐼", "💡", "🔑", "🔒", "⚡", "🔥", "❄️", "🌈", "😎", "🤓", "😈", "👻", "💀", "👍", "👎", "✌️", "🤘", "👊", "🧠", "💭", "🌱", "🔬", "⚗️"
        ] : Array(loadedDescriptions.keys)
    }
    
    static func generateEmojiWiFiName() -> String {
        return emojiCombinations.randomElement()!.emojis
    }
    
    static func generateSingleEmojiWiFiName() -> String {
        return singleEmojis.randomElement()!
    }
    
    static func generateRandomLengthEmojiWiFiName() -> String {
        let randomLength = Int.random(in: 1...4)
        var result = ""
        for _ in 0..<randomLength {
            result += singleEmojis.randomElement()!
        }
        return result
    }
    
    static func getRandomCombination() -> (name: String, emojis: String) {
        return emojiCombinations.randomElement()!
    }
    
    static func getAllCombinations() -> [(name: String, emojis: String)] {
        return emojiCombinations
    }
    
    // Updated getSingleEmojiDescription function
    static func getSingleEmojiDescription(_ emoji: String) -> String {
        if !loadedDescriptions.isEmpty {
            return loadedDescriptions[emoji] ?? "A unique emoji symbol"
        } else {
            let descriptions: [String: String] = [
                "📶": "Antenna Bars - Perfect for WiFi signal strength", "📡": "Satellite Antenna - For space-age connectivity", "💻": "Laptop - Classic computer symbol", "📱": "Mobile Phone - Modern smartphone icon", "🌐": "Globe - Worldwide internet connection", "🔗": "Link - Network connection symbol", "💾": "Floppy Disk - Data storage and tech nostalgia", "🎮": "Video Game - Gaming and entertainment", "🚀": "Rocket - Fast, powerful, and futuristic", "🛰️": "Satellite - Space communication", "🌌": "Milky Way - Cosmic and mysterious", "🌑": "New Moon - Dark and elegant", "⭐": "Star - Bright and shining", "👨‍🚀": "Astronaut - Space explorer", "🤖": "Robot - AI and technology", "👾": "Alien Monster - Gaming and sci-fi", "⚔️": "Crossed Swords - Battle and strength", "🛡️": "Shield - Protection and security", "🔫": "Pistol - Action and power", "💥": "Collision - Explosive energy", "🖤": "Black Heart - Dark and mysterious", "❤️": "Red Heart - Love and passion", "💙": "Blue Heart - Calm and peaceful", "💚": "Green Heart - Nature and growth", "💜": "Purple Heart - Royal and mysterious", "🤍": "White Heart - Pure and clean", "🎵": "Musical Note - Music and rhythm", "🎧": "Headphone - Audio and music", "🎤": "Microphone - Voice and performance", "🎸": "Guitar - Rock music and instruments", "🍕": "Pizza - Food and fun", "🍔": "Hamburger - Fast food and casual", "🍟": "French Fries - Snacks and comfort food", "🍰": "Shortcake - Sweet treats and celebration", "🌲": "Evergreen Tree - Nature and forest", "🏞️": "National Park - Scenic landscapes", "🌻": "Sunflower - Bright and cheerful", "🐱": "Cat Face - Cute and playful", "🐶": "Dog Face - Loyal and friendly", "🐼": "Panda Face - Adorable and rare", "💡": "Light Bulb - Ideas and innovation", "🔑": "Key - Access and secrets", "🔒": "Locked - Security and privacy", "⚡": "High Voltage - Power and energy", "🔥": "Fire - Hot and intense", "❄️": "Snowflake - Cold and pure", "🌈": "Rainbow - Colorful and magical", "😎": "Sunglasses - Cool and stylish", "🤓": "Nerd Face - Smart and geeky", "😈": "Devil - Mischievous and playful", "👻": "Ghost - Spooky and mysterious", "💀": "Skull - Dark and edgy", "👍": "Thumbs Up - Approval and positivity", "👎": "Thumbs Down - Disapproval", "✌️": "Peace Sign - Peace and victory", "🤘": "Rock On - Metal and rock music", "👊": "Fist - Power and strength", "🧠": "Brain - Intelligence and thinking", "💭": "Thought Balloon - Ideas and thoughts", "🌱": "Seedling - Growth and new beginnings", "🔬": "Microscope - Science and research", "⚗️": "Alembic - Chemistry and experiments"
            ]
            return descriptions[emoji] ?? "A unique emoji symbol"
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var generatedWiFiName = ""
    @State private var generatedDescription = ""
    @State private var generatedPassword = ""
    @State private var passwordLength: Double = 62
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSpecialChars = true
    @State private var showingQRCode = false
    @State private var selectedStyle = WiFiStyle.combination
    @State private var selectedView: ContentViewType = .generateWiFi
    @State private var qrCodeImage: NSImage?
    @State private var searchText = ""
    @State private var showCopyConfirmation = false
    @State private var joinStatusMessage = ""
    @State private var showScanSuccessMessage = false
    @State private var scanSuccessMessage = ""
    
    enum ContentViewType: String, CaseIterable {
        case generateWiFi = "Generate WiFi"
        case passwordOptions = "Password Options"
        case viewCombinations = "View Combinations"
        case importQRCodeImage = "Import QR Code Image"
        case liveScanQRCode = "Live Scan QR Code"
        case joinWifi = "Join WiFi"
    }
    
    enum WiFiStyle: String, CaseIterable {
        case combination = "Combination"
        case single = "Single Emoji"
        case random = "Random Length"
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // App Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("EmojiWifi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Generate WiFi names using only emojis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                Divider()
                
                // Navigation Items
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ContentViewType.allCases, id: \.self) { viewType in
                        NavigationButton(
                            title: viewType.rawValue,
                            icon: iconForViewType(viewType),
                            isSelected: selectedView == viewType
                        ) {
                            selectedView = viewType
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                Spacer()
                
                // Current WiFi Info Section
                if !generatedWiFiName.isEmpty || !generatedPassword.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current WiFi")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            if !generatedWiFiName.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Network Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                    
                                    HStack {
                                        Text(generatedWiFiName)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                        
                                        Spacer()
                                        
                                        Button(action: { copyToClipboard(generatedWiFiName) }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.trailing, 20)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            if !generatedPassword.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Password")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                    
                                    HStack {
                                        Text(generatedPassword)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                        
                                        Spacer()
                                        
                                        Button(action: { copyToClipboard(generatedPassword) }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.trailing, 20)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                // App Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("macOS WiFi Generator")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(minWidth: 250, maxWidth: 300)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main Content Area - Now switches between views
            Group {
                switch selectedView {
                case .generateWiFi:
                    generateWiFiView
                case .passwordOptions:
                    passwordOptionsView
                case .viewCombinations:
                    combinationsView
                case .importQRCodeImage:
                    importQRCodeImageView
                case .liveScanQRCode:
                    liveScanQRCodeView
                case .joinWifi:
                    joinWifiView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(wifiName: generatedWiFiName, password: generatedPassword)
        }
        .overlay(
            Group {
                if showScanSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(scanSuccessMessage)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                                .shadow(radius: 5)
                            Spacer()
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
        )
    }
    
    // MARK: - View Components
    
    private var generateWiFiView: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 20) {
                // Style Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("WiFi Name Style")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("WiFi Style", selection: $selectedStyle) {
                        ForEach(WiFiStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                
                // Generate Button
                Button(action: generateWiFiName) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                        Text("Generate WiFi Name")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Results Section
            ScrollView {
                LazyVStack(spacing: 24) {
                    // WiFi Name Result
                    if !generatedWiFiName.isEmpty {
                        ResultCard(
                            title: "WiFi Network Name",
                            content: generatedWiFiName,
                            description: generatedDescription,
                            color: .blue,
                            actionTitle: "Copy WiFi Name",
                            action: { copyToClipboard(generatedWiFiName) }
                        )
                    }
                    
                    // Password Result
                    if !generatedPassword.isEmpty {
                        ResultCard(
                            title: "WiFi Password",
                            content: generatedPassword,
                            description: "\(Int(passwordLength)) characters",
                            color: .orange,
                            actionTitle: "Copy Password",
                            action: { copyToClipboard(generatedPassword) }
                        )
                    }
                    
                    // QR Code Section - Now directly shows the QR code
                    if !generatedWiFiName.isEmpty && !generatedPassword.isEmpty {
                        QRCodeCard(
                            wifiName: generatedWiFiName,
                            password: generatedPassword,
                            qrCodeImage: $qrCodeImage
                        )
                    }
                    
                    // Join Status Section
                    if !joinStatusMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("WiFi Connection Status")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button("Clear") {
                                    joinStatusMessage = ""
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            Text(joinStatusMessage)
                                .font(.body)
                                .foregroundColor(joinStatusMessage.contains("✅") ? .green : 
                                               joinStatusMessage.contains("❌") ? .red : .orange)
                                .padding()
                                .background(joinStatusMessage.contains("✅") ? Color.green.opacity(0.1) : 
                                            joinStatusMessage.contains("❌") ? Color.red.opacity(0.1) :
                                            Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            if !generatedWiFiName.isEmpty && !generatedPassword.isEmpty {
                generateQRCode()
            }
        }
        .onChange(of: generatedWiFiName) { _ in
            if !generatedPassword.isEmpty {
                generateQRCode()
            }
        }
        .onChange(of: generatedPassword) { _ in
            if !generatedWiFiName.isEmpty {
                generateQRCode()
            }
        }
    }
    
    private var passwordOptionsView: some View {
        VStack(spacing: 30) {
            // Header
            HStack {
                Text("Password Options")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            
            // Password Length Control
            VStack(spacing: 15) {
                Text("Password Length: \(Int(passwordLength))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Slider(value: $passwordLength, in: 8...63, step: 1)
                    .frame(maxWidth: 400)
                    .onChange(of: passwordLength) { _ in
                        regeneratePassword()
                    }
                
                Text("WiFi passwords can be 8-63 characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Character Type Options
            VStack(spacing: 20) {
                Text("Character Types")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 15) {
                    Toggle("Uppercase Letters (A-Z)", isOn: $includeUppercase)
                        .onChange(of: includeUppercase) { _ in
                            regeneratePassword()
                        }
                    Toggle("Lowercase Letters (a-z)", isOn: $includeLowercase)
                        .onChange(of: includeLowercase) { _ in
                            regeneratePassword()
                        }
                    Toggle("Numbers (0-9)", isOn: $includeNumbers)
                        .onChange(of: includeNumbers) { _ in
                            regeneratePassword()
                        }
                    Toggle("Special Characters (!@#$%^&*...)", isOn: $includeSpecialChars)
                        .onChange(of: includeSpecialChars) { _ in
                            regeneratePassword()
                        }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Character Examples
            VStack(spacing: 15) {
                Text("Character Examples")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 10) {
                    if includeUppercase {
                        Text("Uppercase: ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    if includeLowercase {
                        Text("Lowercase: abcdefghijklmnopqrstuvwxyz")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    if includeNumbers {
                        Text("Numbers: 0123456789")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    if includeSpecialChars {
                        Text("Special: !@#$%^&*()_+-=[]{}|;:,.<>?")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Warning
            if !includeUppercase && !includeLowercase && !includeNumbers && !includeSpecialChars {
                Text("⚠️ At least one character type must be selected")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Current Password Preview
            if !generatedPassword.isEmpty {
                VStack(spacing: 15) {
                    Text("Current Password Preview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(generatedPassword)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .frame(maxWidth: 400)
                    
                    Button("Regenerate Password") {
                        regeneratePassword()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var combinationsView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("All Emoji Combinations")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            
            // Search Bar - Fixed focus issue
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search combinations...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                
                // Search Results Info
                if !searchText.isEmpty {
                    HStack {
                        Text("Found \(filteredCombinations.count) combinations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            
            // Combinations Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                    ForEach(filteredCombinations, id: \.name) { combination in
                        VStack(spacing: 10) {
                            Text(combination.emojis)
                                .font(.system(size: 24))
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            
                            Text(combination.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .onTapGesture {
                            copyToClipboard(combination.emojis)
                            showCopyConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCopyConfirmation = false
                            }
                        }
                        .help("Tap to copy: \(combination.emojis)")
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Group {
                if showCopyConfirmation {
                    VStack {
                        Spacer()
                        Text("Copied to clipboard!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 20)
                }
            }
        )
        .onAppear {
            searchText = ""
        }
    }
    
    private var importQRCodeImageView: some View {
        ImportQRCodeImageView(
            onQRCodeScanned: { qrString in
                let (ssid, password) = QRCodeGenerator.parseWiFiQRCode(qrString)
                if let ssid = ssid {
                    generatedWiFiName = ssid
                    generatedDescription = "Imported from QR code"
                }
                if let password = password {
                    generatedPassword = password
                }
                generateQRCode()
                // Switch to Generate WiFi tab after successful scan
                selectedView = .generateWiFi
                // Show success message
                scanSuccessMessage = "✅ QR Code imported successfully!"
                showScanSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showScanSuccessMessage = false
                }
            },
            onJoinStatusUpdated: { message in
                joinStatusMessage = message
            }
        )
    }
    
    private var liveScanQRCodeView: some View {
        LiveScanQRCodeView(
            onQRCodeScanned: { qrString in
                let (ssid, password) = QRCodeGenerator.parseWiFiQRCode(qrString)
                print("liveScanQRCodeView: /(ssid)", "/(password)")
                generatedPassword = password!
                generatedWiFiName = ssid!
                generatedDescription = "Scanned from QR code"

                generateQRCode()
                // Switch to Generate WiFi tab after successful scan
                selectedView = .generateWiFi
                // Show success message
                scanSuccessMessage = "✅ QR Code scanned successfully!"
                showScanSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showScanSuccessMessage = false
                }
            },
            onJoinStatusUpdated: { message in
                joinStatusMessage = message
            }
        )
    }
    
    private var joinWifiView: some View {
        VStack(spacing: 30) {
            // Header
            HStack {
                Text("Join WiFi Network")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            
            // Current WiFi Info
            VStack(spacing: 20) {
                Text("Current WiFi Information")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !generatedWiFiName.isEmpty && !generatedPassword.isEmpty {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Network Name:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(generatedWiFiName)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("Password:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(generatedPassword)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: 500)
                    
                    // Join WiFi Button
                    Button(action: {
                        if !generatedWiFiName.isEmpty && !generatedPassword.isEmpty {
                            joinStatusMessage = "Joining network..."
                            WiFiJoiner.joinWiFi(ssid: generatedWiFiName, password: generatedPassword) { message in
                                joinStatusMessage = message
                            }
                        } else {
                            joinStatusMessage = "⚠️ Please generate or scan a WiFi network first"
                        }
                    }) {
                        HStack {
                            Image(systemName: "wifi")
                                .font(.title3)
                            Text("Join WiFi Network")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Status Message
                    if !joinStatusMessage.isEmpty {
                        Text(joinStatusMessage)
                            .font(.body)
                            .foregroundColor(joinStatusMessage.contains("✅") ? .green : 
                                           joinStatusMessage.contains("❌") ? .red : .orange)
                            .padding()
                            .background(joinStatusMessage.contains("✅") ? Color.green.opacity(0.1) : 
                                        joinStatusMessage.contains("❌") ? Color.red.opacity(0.1) :
                                        Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 15) {
                        Text("No WiFi Information Available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Please generate a WiFi network or scan a QR code to get network information")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                        
                        HStack(spacing: 20) {
                            Button("Generate WiFi") {
                                selectedView = .generateWiFi
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Scan QR Code") {
                                selectedView = .liveScanQRCode
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: 500)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Helper Properties
    
    private var filteredCombinations: [(name: String, emojis: String)] {
        if searchText.isEmpty {
            return EmojiWiFiGenerator.getAllCombinations()
        } else {
            let query = searchText.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return EmojiWiFiGenerator.getAllCombinations().filter { combination in
                combination.name.lowercased().contains(query) ||
                combination.emojis.contains(searchText)
            }
        }
    }
    
    private func iconForViewType(_ viewType: ContentViewType) -> String {
        switch viewType {
        case .generateWiFi:
            return "sparkles"
        case .passwordOptions:
            return "key.fill"
        case .viewCombinations:
            return "list.bullet"
        case .importQRCodeImage:
            return "photo.on.rectangle"
        case .liveScanQRCode:
            return "camera.fill"
        case .joinWifi:
            return "wifi"
        }
    }
    
    // MARK: - Helper Methods
    
    private func regeneratePassword() {
        if !generatedWiFiName.isEmpty {
            generatedPassword = PasswordGenerator.generateWiFiPassword(
                length: Int(passwordLength),
                includeUppercase: includeUppercase,
                includeLowercase: includeLowercase,
                includeNumbers: includeNumbers,
                includeSpecialChars: includeSpecialChars
            )
        }
    }
    
    private func generateWiFiName() {
        switch selectedStyle {
        case .combination:
            let combination = EmojiWiFiGenerator.getRandomCombination()
            generatedWiFiName = combination.emojis
            generatedDescription = combination.name
        case .single:
            generatedWiFiName = EmojiWiFiGenerator.generateSingleEmojiWiFiName()
            generatedDescription = EmojiWiFiGenerator.getSingleEmojiDescription(generatedWiFiName)
        case .random:
            generatedWiFiName = EmojiWiFiGenerator.generateRandomLengthEmojiWiFiName()
            generatedDescription = "Random combination of \(generatedWiFiName.count) emojis"
        }
        
        generatedPassword = PasswordGenerator.generateWiFiPassword(
            length: Int(passwordLength),
            includeUppercase: includeUppercase,
            includeLowercase: includeLowercase,
            includeNumbers: includeNumbers,
            includeSpecialChars: includeSpecialChars
        )
        
        generateQRCode()
    }
    
    private func generateQRCode() {
        if !generatedWiFiName.isEmpty && !generatedPassword.isEmpty {
            qrCodeImage = QRCodeGenerator.generateWiFiQRCode(ssid: generatedWiFiName, password: generatedPassword)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Import QR Code Image View
struct ImportQRCodeImageView: View {
    let onQRCodeScanned: (String) -> Void
    let onJoinStatusUpdated: (String) -> Void
    @State private var showingImagePicker = false
    @State private var selectedImage: NSImage?
    @State private var scannedCode = ""
    @State private var scannedSSID: String?
    @State private var scannedPassword: String?
    @State private var joinStatusMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            HStack {
                Text("Import QR Code Image")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            
            // Instructions
            VStack(spacing: 15) {
                Text("Import a QR Code Image")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Select an image file containing a QR code to extract WiFi network information")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }
            
            // Image Import Option
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Import QR Code Image")
                            .font(.headline)
                    }
                    
                    Text("Select an image file containing a QR code")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Select Image") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Image Preview
            if let image = selectedImage {
                VStack(spacing: 15) {
                    Text("Selected Image")
                        .font(.headline)
                    
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    
                    Button("Process QR Code") {
                        processQRCode()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            
            // Result Display
            if !scannedCode.isEmpty || (scannedSSID != nil && scannedPassword != nil) {
                VStack(spacing: 15) {
                    Text("Imported Result:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let ssid = scannedSSID, let password = scannedPassword {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Network:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(ssid)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Password:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(password)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .frame(maxWidth: 500)
                        
                        // Use This WiFi Button
                        Button("Use This WiFi") {
                            if let ssid = scannedSSID, let password = scannedPassword {
                                onQRCodeScanned("WIFI:T:WPA;S:\(ssid);P:\(password);H:false;;")
                            } else {
                                onQRCodeScanned(scannedCode)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        // Status Message
                        if !joinStatusMessage.isEmpty {
                            Text(joinStatusMessage)
                                .font(.body)
                                .foregroundColor(joinStatusMessage.contains("✅") ? .green : 
                                               joinStatusMessage.contains("❌") ? .red : .orange)
                                .padding()
                                .background(joinStatusMessage.contains("✅") ? Color.green.opacity(0.1) : 
                                            joinStatusMessage.contains("❌") ? Color.red.opacity(0.1) :
                                            Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    } else {
                        Text(scannedCode)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            .frame(maxWidth: 500)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private func processQRCode() {
        guard let image = selectedImage else { return }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let ciImage = CIImage(cgImage: cgImage)
        
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature], let feature = features.first else {
            scannedCode = "No QR code found in image"
            return
        }
        
        scannedCode = feature.messageString ?? "Unable to read QR code"
        let (ssid, password) = QRCodeGenerator.parseWiFiQRCode(scannedCode)
        scannedSSID = ssid
        scannedPassword = password
    }
}

// MARK: - Live Scan QR Code View
struct LiveScanQRCodeView: View {
    let onQRCodeScanned: (String) -> Void
    let onJoinStatusUpdated: (String) -> Void
    @State private var isScanning = false
    @State private var scannedCode = ""
    @State private var showingCamera = false
    @State private var scannedSSID: String?
    @State private var scannedPassword: String?
    @State private var joinStatusMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            HStack {
                Text("Live Scan QR Code")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            
            // Instructions
            VStack(spacing: 15) {
                Text("Scan a WiFi QR Code")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Use your Mac's camera to scan a QR code in real-time")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }
            
            // Camera Scanning Option
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Live Camera Scanning")
                            .font(.headline)
                    }
                    
                    Text("Use your Mac's camera to scan a QR code in real-time")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Scan QR Code") {
                        showingCamera = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Result Display
            if !scannedCode.isEmpty {
                VStack(spacing: 15) {
                    Text("Scanned Result:")
                        .font(.headline)
                        .foregroundColor(.primary)

                    let (scannedSSID, scannedPassword) = QRCodeGenerator.parseWiFiQRCode(scannedCode)
                    Text(String(describing:scannedSSID))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(String(describing:scannedCode))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding()

                    if let ssid = scannedSSID, let password = scannedPassword {

                        VStack(spacing: 10) {
                            HStack {
                                Text("Network:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(ssid)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Password:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(password)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .frame(maxWidth: 500)
                        
                        // Use This WiFi Button
                        Button("Use This WiFi") {
                            if let ssid = scannedSSID, let password = scannedPassword {
                                onQRCodeScanned("WIFI:T:WPA;S:\(ssid);P:\(password);H:false;;")
                            } else {
                                onQRCodeScanned(scannedCode)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        // Status Message
                        if !joinStatusMessage.isEmpty {
                            Text(joinStatusMessage)
                                .font(.body)
                                .foregroundColor(joinStatusMessage.contains("✅") ? .green : 
                                               joinStatusMessage.contains("❌") ? .red : .orange)
                                .padding()
                                .background(joinStatusMessage.contains("✅") ? Color.green.opacity(0.1) : 
                                            joinStatusMessage.contains("❌") ? Color.red.opacity(0.1) :
                                            Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    } else {
                        Text(scannedCode)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            .frame(maxWidth: 500)
                    }
                }
                .onChange(of: scannedCode) { newValue in
                    print("scannedCode: \(String(describing: newValue))")
                }                
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingCamera) {
            CameraQRScannerView(
                onQRCodeDetected: { qrString in
                    scannedCode = qrString
                    let (ssid, password) = QRCodeGenerator.parseWiFiQRCode(qrString)
                    scannedSSID = ssid
                    scannedPassword = password
                    showingCamera = false
                    
                    if let ssid = ssid, let password = password {
                        onQRCodeScanned("WIFI:T:WPA;S:\(ssid);P:\(password);H:false;;")
                    }
                }
            )
        }
    }
}

// MARK: - Camera QR Scanner View
struct CameraQRScannerView: NSViewRepresentable {
    let onQRCodeDetected: (String) -> Void
    
    func makeNSView(context: Context) -> CameraPreviewView {
        let cameraView = CameraPreviewView()
        cameraView.onQRCodeDetected = onQRCodeDetected
        return cameraView
    }
    
    func updateNSView(_ nsView: CameraPreviewView, context: Context) {}
}

// MARK: - Camera Preview View
class CameraPreviewView: NSView {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoOutput: AVCaptureVideoDataOutput?
    var onQRCodeDetected: ((String) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startCamera()
        } else {
            stopCamera()
        }
    }
    
    private func startCamera() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
            print("No camera available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.backgroundColor = NSColor.black.cgColor
            previewLayer.cornerRadius = 8
            previewLayer.masksToBounds = true
            
            DispatchQueue.main.async {
                self.previewLayer = previewLayer
                previewLayer.frame = self.bounds
                self.layer?.addSublayer(previewLayer)
            }
            
            session.commitConfiguration()
            self.captureSession = session
            self.videoOutput = output
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
            session.startRunning()
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    private func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        previewLayer?.frame = bounds
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature],
            let qrFeature = features.first else { return }
        
        if let payload = qrFeature.messageString {
            DispatchQueue.main.async {
                self.stopCamera()
                self.onQRCodeDetected?(payload)
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: NSViewControllerRepresentable {
    @Binding var selectedImage: NSImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeNSViewController(context: Context) -> NSViewController {
        let picker = NSOpenPanel()
        picker.allowedContentTypes = [.image]
        picker.allowsMultipleSelection = false
        picker.canChooseDirectories = false
        picker.canChooseFiles = true
        
        let controller = NSViewController()
        
        DispatchQueue.main.async {
            picker.begin { response in
                if response == .OK, let url = picker.url {
                    if let image = NSImage(contentsOf: url) {
                        selectedImage = image
                    }
                }
                presentationMode.wrappedValue.dismiss()
            }
        }
        
        return controller
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

// MARK: - Navigation Button Component
struct NavigationButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Result Card Component
struct ResultCard: View {
    let title: String
    let content: String
    let description: String
    let color: Color
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                    )
                
                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        )
    }
}

// MARK: - QR Code Card Component
struct QRCodeCard: View {
    let wifiName: String
    let password: String
    @Binding var qrCodeImage: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("QR Code")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Copy QR Code") {
                    if let image = qrCodeImage {
                        copyImageToClipboard(image)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // QR Code Display
            VStack(spacing: 15) {
                if let qrImage = qrCodeImage {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    
                    Text("Scan with your phone to connect")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Text("Generating QR Code...")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        )
    }
    
    private func copyImageToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}

// MARK: - QR Code View
struct QRCodeView: View {
    let wifiName: String
    let password: String
    @Environment(\.presentationMode) var presentationMode
    @State private var qrCodeImage: NSImage?
    
    var body: some View {
        VStack(spacing: 30) {
            // Header with prominent close button
            HStack {
                Text("WiFi QR Code")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close")
                .frame(width: 32, height: 32)
            }
            .padding()
            
            // WiFi Info
            VStack(spacing: 15) {
                Text("WiFi Network:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(wifiName)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                
                Text("Password:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(password)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: 300)
            }
            
            // QR Code Display
            VStack(spacing: 15) {
                Text("Scan with your phone to connect:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let qrImage = qrCodeImage {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 300, height: 300)
                        .overlay(
                            Text("Generating QR Code...")
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            // Instructions
            VStack(spacing: 10) {
                Text("Instructions:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("• Open your phone's camera app")
                    Text("• Point it at the QR code above")
                    Text("• Tap the WiFi notification that appears")
                    Text("• Your phone will automatically connect")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Additional close button at the bottom
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.bordered)
            .padding(.bottom)
        }
        .frame(minWidth: 500, maxWidth: 600, minHeight: 600)
        .padding(20)
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        qrCodeImage = QRCodeGenerator.generateWiFiQRCode(ssid: wifiName, password: password)
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force the app to be a regular app with Dock icon + App Switcher presence
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

// MARK: - App (MODIFIED)
@main
struct EmojiWifiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Load the data from the embedded CSV files into the app's memory.
        // This will now use the data from the embedded resources on every launch.
        EmojiWiFiGenerator.initializeFromCSV()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .help) { }
        }
    }
}