import Combine
import SwiftUI

struct PackPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.packIndex) private var packIndex

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)],
                      spacing: 12) {
                ForEach(packIndex.metadata, id: \.id) { meta in
                    PackCard(
                        meta: meta,
                        isSelected: appState.selectedPackID == meta.id,
                        onSelect: { appState.selectedPackID = meta.id },
                        onAudition: { packIndex.auditionPack(id: meta.id) }
                    )
                }
            }
            .padding()
        }
    }
}

struct PackMetadata: Hashable, Sendable {
    let id: String
    let name: String
    let character: SoundCharacter
    let description: String
}

struct PackCard: View {
    let meta: PackMetadata
    let isSelected: Bool
    let onSelect: () -> Void
    let onAudition: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(characterColor)
                    .frame(width: 10, height: 10)
                Text(meta.character.capitalized)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            Text(meta.name).font(.headline)
            Text(meta.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            HStack {
                Button("Audition") { onAudition() }
                    .buttonStyle(.bordered)
                Spacer()
                Button(isSelected ? "Selected" : "Select") { onSelect() }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSelected)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.25),
                    lineWidth: isSelected ? 2 : 1))
    }

    private var characterColor: Color {
        // Stable palette pick from the character string's hash so new packs
        // get a deterministic colour without touching this switch.
        let palette: [Color] = [.orange, .brown, .cyan, .pink, .purple,
                                .mint, .teal, .indigo, .yellow, .red]
        let hash = meta.character.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }
}

/// Provides the pack index + audition function to the pack picker.
/// Wired up in KeyMochiApp (Task 19).
@MainActor
final class PackIndex: ObservableObject {
    @Published var metadata: [PackMetadata] = []
    var auditionHandler: ((String) -> Void)?

    func auditionPack(id: String) {
        auditionHandler?(id)
    }
}

private struct PackIndexKey: EnvironmentKey {
    @MainActor static var defaultValue: PackIndex { PackIndex() }
}

extension EnvironmentValues {
    var packIndex: PackIndex {
        get { self[PackIndexKey.self] }
        set { self[PackIndexKey.self] = newValue }
    }
}
