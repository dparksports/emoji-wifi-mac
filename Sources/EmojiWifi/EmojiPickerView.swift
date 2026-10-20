import SwiftUI

// MARK: - Emoji Picker View
/// Full-catalog picker: browse by category, search by name, see which emojis
/// you've already used (dimmed), and tap out a custom name — kept within the
/// 32-byte SSID limit — then use it as your WiFi name.
struct EmojiPickerView: View {
    let usedEmojis: Set<String>
    let onUse: (String) -> Void

    @State private var draftName = ""
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var hideUsed = false

    private var categories: [String] {
        return ["All"] + EmojiWiFiGenerator.catalogCategories
    }

    private var filteredEntries: [EmojiCatalogEntry] {
        var entries = EmojiWiFiGenerator.catalog
        if selectedCategory != "All" {
            entries = entries.filter { $0.category == selectedCategory }
        }
        if hideUsed {
            entries = entries.filter { !usedEmojis.contains($0.emoji) }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            entries = entries.filter { $0.name.lowercased().contains(query) }
        }
        return entries
    }

    var body: some View {
        VStack(spacing: 0) {
            // Draft name bar
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Text(draftName.isEmpty ? "Tap emojis to build your WiFi name…" : draftName)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(draftName.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    Text("\(draftName.utf8.count)/\(EmojiWiFiGenerator.ssidMaxBytes) bytes")
                        .font(.caption)
                        .foregroundColor(draftName.utf8.count >= EmojiWiFiGenerator.ssidMaxBytes ? .red : .secondary)
                    Button(action: backspace) {
                        Image(systemName: "delete.left").font(.title3)
                    }.buttonStyle(.bordered).help("Remove last emoji")
                    Button("Clear") { draftName = "" }
                        .buttonStyle(.bordered).disabled(draftName.isEmpty)
                    Button(action: { onUse(draftName) }) {
                        Text("Use as WiFi Name").fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(draftName.isEmpty)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Controls
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Search emojis by name (try \"pizza\")", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        if !searchText.isEmpty {
                            Button("Clear") { searchText = "" }.buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor)).cornerRadius(6)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)

                    Toggle("Hide used", isOn: $hideUsed)
                        .help("Hide emojis that already appear in one of your past network names")

                    Spacer()

                    Text("\(filteredEntries.count) emojis").font(.caption).foregroundColor(.secondary)
                }
                Text("Dimmed emojis already appear in one of your past network names.")
                    .font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal).padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Emoji grid
            if EmojiWiFiGenerator.catalog.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundColor(.orange)
                    Text("Emoji catalog unavailable").font(.headline)
                    Text("EmojiCatalog.json could not be loaded from the app bundle.").font(.body).foregroundColor(.secondary)
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 12), spacing: 6) {
                        ForEach(filteredEntries) { entry in
                            Button(action: { appendToDraft(entry.emoji) }) {
                                Text(entry.emoji)
                                    .font(.system(size: 26))
                                    .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(usedEmojis.contains(entry.emoji) ? 0.25 : 1)
                            .help(entry.name + (usedEmojis.contains(entry.emoji) ? " (already used)" : ""))
                        }
                    }.padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func appendToDraft(_ emoji: String) {
        guard (draftName + emoji).utf8.count <= EmojiWiFiGenerator.ssidMaxBytes else { return }
        draftName += emoji
    }

    private func backspace() {
        if !draftName.isEmpty { draftName.removeLast() }
    }
}
