import Foundation

// MARK: - Catalog entry
/// One entry of the emoji catalog, generated from Unicode's emoji-test.txt
/// (release 14.0, filtered to fully-qualified, non-flag, single-visual emoji —
/// see tools/generate_emoji_catalog.py in the emoji-wifi-windows repo).
struct EmojiCatalogEntry: Codable, Identifiable, Equatable {
    let emoji: String
    let name: String
    let category: String
    let subCategory: String

    var id: String { emoji }

    enum CodingKeys: String, CodingKey {
        case emoji = "Emoji"
        case name = "Name"
        case category = "Category"
        case subCategory = "SubCategory"
    }
}

// MARK: - Seeded RNG
/// SplitMix64: deterministic themed combinations that stay stable across runs,
/// so screenshots, docs, and muscle memory don't shift every launch
/// (same idea as the Windows app's seeded Random).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - CSV Parsing
func parseCSVLine(_ line: String) -> [String] {
    var components: [String] = []
    var currentComponent = ""
    var inQuotes = false
    for (index, character) in line.enumerated() {
        if character == "\"" {
            if index + 1 < line.count && line[line.index(line.startIndex, offsetBy: index + 1)] == "\"" {
                currentComponent += "\""
            } else { inQuotes.toggle() }
        } else if character == "," && !inQuotes {
            components.append(currentComponent); currentComponent = ""
        } else { currentComponent += String(character) }
    }
    components.append(currentComponent)
    return components
}

func loadSingleEmojiDescriptionsFromCSV() -> [String: String] {
    var descriptions: [String: String] = [:]
    guard let url = Bundle.module.url(forResource: "single", withExtension: "csv") else {
        print("❌ Could not find single.csv in bundle"); return descriptions
    }
    do {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        for line in csvContent.components(separatedBy: CharacterSet.newlines).dropFirst() {
            if line.isEmpty { continue }
            let components = parseCSVLine(line)
            if components.count >= 2 {
                descriptions[components[0].trimmingCharacters(in: .whitespacesAndNewlines)] = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        print("✅ Loaded \(descriptions.count) emoji descriptions from single.csv")
    } catch { print("❌ Error loading single.csv: \(error)") }
    return descriptions
}

func loadEmojiCombinationsFromCSV() -> [(name: String, emojis: String)] {
    var combinations: [(name: String, emojis: String)] = []
    guard let url = Bundle.module.url(forResource: "combos", withExtension: "csv") else {
        print("❌ Could not find combos.csv in bundle"); return combinations
    }
    do {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        for line in csvContent.components(separatedBy: CharacterSet.newlines).dropFirst() {
            if line.isEmpty { continue }
            let components = parseCSVLine(line)
            if components.count >= 2 {
                combinations.append((name: components[0].trimmingCharacters(in: .whitespacesAndNewlines), emojis: components[1].trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        print("✅ Loaded \(combinations.count) emoji combinations from combos.csv")
    } catch { print("❌ Error loading combos.csv: \(error)") }
    return combinations
}

// MARK: - Emoji WiFi Name Generator
class EmojiWiFiGenerator {
    /// 802.11 SSIDs are limited to 32 bytes.
    static let ssidMaxBytes = 32

    private static let themedCombosPerCategory = 6
    private static let comboSeed: UInt64 = 0x20261019

    static var loadedDescriptions: [String: String] = [:]
    static var loadedCombinations: [(name: String, emojis: String)] = []
    static var themedCombinations: [(name: String, emojis: String)] = []

    // MARK: Catalog

    static var catalog: [EmojiCatalogEntry] = []
    static var catalogIndex: [String: EmojiCatalogEntry] = [:]
    static var catalogCategories: [String] = []

    static func initializeFromCSV() {
        loadedDescriptions = loadSingleEmojiDescriptionsFromCSV()
        loadedCombinations = loadEmojiCombinationsFromCSV()
        loadCatalog()
        themedCombinations = generateThemedCombinations()
    }

    private static func loadCatalog() {
        guard let url = Bundle.module.url(forResource: "EmojiCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([EmojiCatalogEntry].self, from: data),
              !entries.isEmpty else {
            print("⚠️ EmojiCatalog.json unavailable; falling back to single.csv dataset")
            return
        }
        catalog = entries
        catalogIndex = Dictionary(entries.map { ($0.emoji, $0) }, uniquingKeysWith: { first, _ in first })
        var seen = Set<String>()
        catalogCategories = entries.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
        print("✅ Loaded \(entries.count) emoji from EmojiCatalog.json across \(catalogCategories.count) categories")
    }

    // MARK: Combinations

    static var emojiCombinations: [(name: String, emojis: String)] {
        return loadedCombinations.isEmpty ? [
            ("Tech Hub", "💻📶🌐"), ("Signal Strong", "📡⚡🔥"), ("Network Master", "🔗💾🎮"), ("Digital Space", "🌐💻📱"), ("WiFi Zone", "📶🔗💡"), ("Space Station", "🚀🛰️🌌"), ("Galaxy Network", "🌌⭐🌑"), ("Rocket WiFi", "🚀⚡💨"), ("Astronaut Zone", "👨‍🚀🛰️🌌"), ("Cosmic Signal", "⭐🌌📡"), ("Gaming Hub", "🎮🎵🎧"), ("Game Zone", "🎮⚔️🛡️"), ("Player One", "🎮👾🤖"), ("Gaming Station", "🎮🎸🎤"), ("Arcade WiFi", "🎮💾🔫"), ("Music Studio", "🎵🎧🎤"), ("Rock WiFi", "🎸🤘🎵"), ("Sound Wave", "🎵🌊🎧"), ("Music Zone", "🎤🎸🎵"), ("Audio Hub", "🎧🎵🎤"), ("Nature WiFi", "🌲🌻🌱"), ("Forest Signal", "🌲🏞️🌿"), ("Garden Network", "🌻🌱🌿"), ("Tree WiFi", "🌲🌳🌱"), ("Natural Zone", "🌿🌻🌱"), ("Food Network", "🍕🍔🍟"), ("Pizza WiFi", "🍕🍕🍕"), ("Burger Zone", "🍔🍟🥤"), ("Snack Hub", "🍟🍕🍰"), ("Foodie WiFi", "🍕🍔🍰"), ("Cool Zone", "😎🔥⚡"), ("Stylish WiFi", "😎💎✨"), ("Awesome Network", "😎👍🔥"), ("Epic WiFi", "🔥⚡💥"), ("Legendary Zone", "👑⚡🔥"), ("Dark Network", "🖤🌑👻"), ("Ghost WiFi", "👻💀🖤"), ("Mystery Zone", "🔮🌑👻"), ("Shadow Network", "🖤🌑👻"), ("Night WiFi", "🌙⭐👻"), ("Dark Vader", "🖤🤖⚔️"), ("Fun Zone", "😄🎉🎈"), ("Happy WiFi", "😊🌈✨"), ("Party Network", "🎉🎊🎈"), ("Joy Zone", "😄😊🎉"), ("Smile WiFi", "😊💖✨"), ("Cat Zone", "🐱😸🐾"), ("Dog WiFi", "🐶🐕🐾"), ("Panda Paradise", "🐼🎋🎍"), ("Animal Kingdom", "🐱🐶🐼"), ("Pet Network", "🐾🐱🐶"), ("Storm WiFi", "⛈️⚡🌧️"), ("Sunny Zone", "☀️🌞🌻"), ("Rainbow Network", "🌈☀️🌧️"), ("Weather Hub", "🌤️⛈️🌈"), ("Sky WiFi", "☁️🌤️🌈"), ("Love Zone", "💖💕💗"), ("Heart WiFi", "❤️💙💚"), ("Sweet Network", "💖🍰💕"), ("Romance Zone", "💕💖💗"), ("Love Hub", "❤️💕💖"), ("Power Zone", "⚡🔥💥"), ("Energy WiFi", "⚡🔋💡"), ("Lightning Fast", "⚡💨🚀"), ("Power Hub", "⚡🔥💥"), ("Energy Zone", "🔋⚡💡"), ("Simple WiFi", "✨💫⭐"), ("Clean Zone", "🤍✨💫"), ("Pure Network", "🤍💫✨"), ("Minimal WiFi", "✨🤍💫"), ("Clear Zone", "💫✨🤍")
        ] : loadedCombinations
    }

    /// Curated combinations plus deterministic themed combinations generated
    /// from the catalog (six per category, mirroring the Windows app).
    static func getAllCombinations() -> [(name: String, emojis: String)] {
        return emojiCombinations + themedCombinations
    }

    static func getRandomCombination() -> (name: String, emojis: String) {
        return getAllCombinations().randomElement() ?? ("WiFi Zone", "📶🔗💡")
    }

    /// Auto-generates themed pairs/triples from each catalog category with a
    /// seeded RNG so the list is identical on every machine and every launch.
    static func generateThemedCombinations() -> [(name: String, emojis: String)] {
        guard !catalog.isEmpty else { return [] }
        var rng = SeededGenerator(seed: comboSeed)
        var existing = Set(emojiCombinations.map { $0.emojis })
        var themed: [(name: String, emojis: String)] = []

        for category in catalogCategories {
            let pool = catalog.filter { $0.category == category }.map { $0.emoji }
            guard pool.count >= 2 else { continue }

            var made = 0
            var attempts = 0
            while made < themedCombosPerCategory && attempts < 100 {
                attempts += 1
                let count = Int.random(in: 2...3, using: &rng)
                let picked = pickDistinct(from: pool, count: count, using: &rng)
                let emojis = picked.joined()
                if emojis.utf8.count > ssidMaxBytes || existing.contains(emojis) { continue }
                existing.insert(emojis)
                let name = picked.map { titleCase(catalogIndex[$0]?.name ?? "emoji") }.joined(separator: " + ")
                themed.append((name, emojis))
                made += 1
            }
        }
        return themed
    }

    private static func pickDistinct(from pool: [String], count: Int, using rng: inout SeededGenerator) -> [String] {
        var available = pool
        var picked: [String] = []
        while picked.count < count && !available.isEmpty {
            let index = Int.random(in: 0..<available.count, using: &rng)
            picked.append(available.remove(at: index))
        }
        return picked
    }

    private static func titleCase(_ name: String) -> String {
        return name.split(separator: " ").map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }

    // MARK: Emoji pool

    static var singleEmojis: [String] {
        if !catalog.isEmpty { return catalog.map { $0.emoji } }
        return loadedDescriptions.isEmpty ? [
            "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🥹", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "🥲", "😋", "😛", "😜", "😝", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "😫", "😩", "🥺", "😢", "😭", "😮‍💨", "😤", "😠", "😡", "🤬", "😈", "👿", "💀", "👻", "👽", "🤖", "🤡", "👹", "👺", "😼", "😽", "😿", "😹", "😾", "😺", "😸", "🙌", "👏", "👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛", "🤜", "🙏", "✍️", "💅", "👂", "👃", "👀", "🧠", "🦷", "👅", "💋", "👶", "👧", "👦", "👩", "🧑", "👨", "👵", "👴", "👸", "🤴", "👰", "🤵", "🤰", "🤱", "👼", "🎅", "🦸", "🦹", "🧙", "🧚", "🧛", "🧜", "🧝", "🧞", "🧟", "🚶", "🏃", "💃", "🕺", "🗣️", "👤", "👥",
            "🐵", "🐒", "🦍", "🦧", "🐶", "🐕", "🐩", "🐺", "🦊", "🦝", "🐱", "🐈", "🦁", "🐅", "🐆", "🐴", "🐎", "🦌", "🐮", "🐂", "🐃", "🐄", "🐷", "🐖", "🐗", "🐏", "🐑", "🐐", "🐪", "🐫", "🦙", "🦒", "🐘", "🦣", "🦏", "🦛", "🐭", "🐁", "🐀", "🐹", "🐰", "🐇", "🐿️", "🦫", "🦇", "🐻", "🐨", "🐼", "🦥", "🦦", "🦨", "🦘", "🦡", "🐾", "🦃", "🐔", "🐓", "🐣", "🐤", "🐥", "🐦", "🐧", "🕊️", "🦅", "🦆", "🦢", "🦉", "🦤", "🪶", "🐸", "🐊", "🐢", "🐍", "🦎", "🦖", "🦕", "🐳", "🐋", "🐬", "🦭", "🐟", "🐠", "🐡", "🦈", "🐙", "🐚", "🐌", "🦋", "🐛", "🐜", "🐝", "🪲", "🦗", "🕷️", "🦂", "🦟", "🦠", "💐", "🌸", "💮", "🌹", "🥀", "🌺", "🌻", "🌷", "🌱", "🌲", "🌳", "🌴", "🌵", "🌾", "🌿", "🍀", "🍁", "🍂", "🍃",
            "🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🥭", "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🥝", "🍅", "🥥", "🥑", "🍆", "🥔", "🥕", "🌽", "🌶️", "🥒", "🍄", "🌰", "🥜", "🍯", "🍞", "🥐", "🥖", "🥨", "🥞", "🧇", "🧀", "🥩", "🥓", "🍔", "🍟", "🍕", "🌭", "🌮", "🌯", "🥙", "🥗", "🥘", "🍝", "🍜", "🥟", "🍣", "🍤", "🍚", "🍛", "🍙", "🍘", "🍠", "🍢", "🍡", "🍧", "🍨", "🍦", "🥧", "🍰", "🍮", "🍬", "🍭", "🍫", "🍩", "🍪", "☕", "🍵", "🥤", "🥛", "🍻", "🥂", "🥃", "🍸", "🍹", "🍾", "🧊",
            "🌎", "🌍", "🌏", "🌐", "🗾", "🧭", "🏔️", "⛰️", "🌋", "🏕️", "🏖️", "🏜️", "🏝️", "🌃", "🏙️", "🌉", "🏠", "🏡", "🏢", "🏣", "🏥", "🏦", "🏨", "⛪", "🕌", "🕍", "⛩️", "🕋", "🗽", "🗼", "🏯", "🏰", "⛲", "🗿", "🚂", "🚆", "🚇", "🚝", "🚋", "🚌", "🚎", "🚕", "🚗", "🚙", "🚚", "🚛", "🚜", "🚲", "🛴", "🛵", "🏍️", "🛺", "🚨", "🚑", "🚒", "🚓", "✈️", "🛫", "🛬", "🚁", "🚀", "🛰️", "🛸", "🚢", "⛵", "🚤", "⚓", "🚧", "⛽", "🚦", "🚥",
            "⌚", "📱", "📲", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "💾", "💿", "📀", "🧮", "🔭", "🔬", "💡", "🔦", "🔋", "🔌", "🔧", "🔨", "🔩", "⚙️", "🔪", "⚔️", "🛡️", "🔫", "🏹", "💣", "💰", "💴", "💵", "💶", "💷", "💳", "🧾", "✉️", "📧", "📥", "📤", "📦", "📫", "📪", "🔔", "🔕", "📓", "📔", "📒", "📚", "📖", "🔖", "📎", "📌", "📍", "📐", "📏", "✂️", "🔒", "🔑", "🗝️", "🚪", "🛋️", "🛏️", "🖼️", "🎈", "🎁", "🎉", "🎊", "🎀", "🪄", "🎵", "🎶", "🎤", "🎧", "🎷", "🎸", "🎹", "🎺", "🥁", "🎬", "🎨", "🎰", "🎲", "🎳", "🎮", "🕹️", "♠️", "♥️", "♦️", "♣️", "🌟", "⭐", "☀️", "🌙", "☁️", "🌧️", "🌩️", "❄️", "🔥", "💧", "🌈", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "💯", "✅", "❌", "❓", "❕", "⚠️", "🆘"
        ] : Array(loadedDescriptions.keys)
    }

    // MARK: Generation

    /// Picks a random emoji, preferring ones absent from `excluding` (e.g.
    /// emojis the user already used). Falls back to the full pool when
    /// everything is excluded.
    static func randomSingleEmoji(excluding: Set<String> = []) -> String {
        let pool = singleEmojis
        let candidates = excluding.isEmpty ? pool : pool.filter { !excluding.contains($0) }
        return (candidates.isEmpty ? pool : candidates).randomElement() ?? "📶"
    }

    static func generateSingleEmojiWiFiName(excluding: Set<String> = []) -> String {
        return randomSingleEmoji(excluding: excluding)
    }

    static func generateRandomLengthEmojiWiFiName(min: Int = 1, max: Int = 4, excluding: Set<String> = []) -> String {
        let length = Int.random(in: min...max)
        var result = ""
        for _ in 0..<length {
            let next = randomSingleEmoji(excluding: excluding)
            if (result + next).utf8.count > ssidMaxBytes { break }
            result += next
        }
        return result
    }

    static func generateEmojiWiFiName() -> String { getRandomCombination().emojis }

    // MARK: Descriptions & used-emoji tracking

    static func getSingleEmojiDescription(_ emoji: String) -> String {
        if let info = catalogIndex[emoji] {
            return info.name.prefix(1).uppercased() + info.name.dropFirst()
        }
        if !loadedDescriptions.isEmpty {
            return loadedDescriptions[emoji] ?? "A unique emoji symbol"
        }
        let descriptions: [String: String] = [
            "📶": "Antenna Bars", "📡": "Satellite Antenna", "💻": "Laptop", "📱": "Mobile Phone", "🌐": "Globe", "🔗": "Link", "💾": "Floppy Disk", "🎮": "Video Game", "🚀": "Rocket", "🛰️": "Satellite", "🌌": "Milky Way", "🌑": "New Moon", "⭐": "Star", "👨‍🚀": "Astronaut", "🤖": "Robot", "👾": "Alien Monster", "⚔️": "Crossed Swords", "🛡️": "Shield", "💥": "Collision", "🖤": "Black Heart", "❤️": "Red Heart", "💙": "Blue Heart", "💚": "Green Heart", "💜": "Purple Heart", "🤍": "White Heart", "🎵": "Musical Note", "🎧": "Headphone", "🎤": "Microphone", "🎸": "Guitar", "🍕": "Pizza", "🍔": "Hamburger", "🍟": "French Fries", "🍰": "Shortcake", "🌲": "Evergreen Tree", "🌻": "Sunflower", "🐱": "Cat Face", "🐶": "Dog Face", "🐼": "Panda Face", "💡": "Light Bulb", "🔑": "Key", "🔒": "Locked", "⚡": "High Voltage", "🔥": "Fire", "❄️": "Snowflake", "🌈": "Rainbow", "😎": "Sunglasses", "🤓": "Nerd Face", "😈": "Devil", "👻": "Ghost", "💀": "Skull", "👍": "Thumbs Up", "✌️": "Peace Sign", "🤘": "Rock On", "👊": "Fist", "🧠": "Brain", "🌱": "Seedling", "🔬": "Microscope"
        ]
        return descriptions[emoji] ?? "A unique emoji symbol"
    }

    /// Returns the pool emojis that appear anywhere in the given network
    /// names, so the UI can tell "already used" from "new to you".
    static func findUsedEmojis(in networkNames: [String]) -> Set<String> {
        var used = Set<String>()
        guard !singleEmojis.isEmpty else { return used }
        for name in networkNames where !name.isEmpty {
            for emoji in singleEmojis where !used.contains(emoji) && name.contains(emoji) {
                used.insert(emoji)
            }
        }
        return used
    }
}
