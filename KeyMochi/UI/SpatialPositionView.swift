import SwiftUI

struct SpatialPositionView: View {
    @Environment(AppState.self) private var appState

    /// Range for x and z in meters. Listener is treated as moving within a
    /// 1m x 1m area centred on the virtual keyboard.
    private let extent: ClosedRange<Float> = -0.5...0.5

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 16) {
            Text("Place your listening position").font(.headline)
            Text("Drag the dot to move your virtual head. Your keyboard stays fixed 30 cm in front of the origin.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4)))

                    Text("Keyboard").font(.caption).foregroundStyle(.secondary)
                        .position(x: size/2, y: size * 0.1)

                    // Coordinate grid lines
                    Path { p in
                        p.move(to: CGPoint(x: size/2, y: 0))
                        p.addLine(to: CGPoint(x: size/2, y: size))
                        p.move(to: CGPoint(x: 0, y: size/2))
                        p.addLine(to: CGPoint(x: size, y: size/2))
                    }
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                        .position(headPosition(in: size))
                        .allowsHitTesting(false)
                }
                .frame(width: size, height: size)
                .contentShape(Rectangle())
                .coordinateSpace(name: "pad")
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("pad"))
                        .onChanged { v in
                            let (x, z) = cgToMeters(v.location, size: size)
                            appState.listenerX = x.clamped(to: extent)
                            appState.listenerZ = z.clamped(to: extent)
                        }
                )
                .accessibilityElement()
                .accessibilityLabel("Listener position pad")
                .accessibilityValue(String(
                    format: "x %+0.2f meters, z %+0.2f meters",
                    appState.listenerX, appState.listenerZ))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HStack {
                Text("Height")
                Slider(value: $appState.listenerY, in: -0.3...0.3)
                Text(String(format: "%+0.2f m", appState.listenerY))
                    .font(.caption.monospaced())
                    .frame(width: 56, alignment: .trailing)
            }
            HStack {
                Button("Reset position") {
                    appState.listenerX = 0; appState.listenerY = 0; appState.listenerZ = 0
                }
                Spacer()
                Text(String(
                    format: "Listener: (%+0.2f, %+0.2f, %+0.2f) m",
                    appState.listenerX, appState.listenerY, appState.listenerZ))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func headPosition(in size: CGFloat) -> CGPoint {
        let nx = CGFloat((appState.listenerX + 0.5))
        let nz = CGFloat((appState.listenerZ + 0.5))
        return CGPoint(x: nx * size, y: nz * size)
    }

    private func cgToMeters(_ p: CGPoint, size: CGFloat) -> (Float, Float) {
        let x = Float(p.x / size) - 0.5
        let z = Float(p.y / size) - 0.5
        return (x, z)
    }
}

private extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}
