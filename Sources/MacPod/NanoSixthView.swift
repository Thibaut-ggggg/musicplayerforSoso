import SwiftUI

enum NanoSixthMetrics {
    // Apple specifies a 40.9 × 37.5 mm body and a square 1.54-inch display.
    static let scale: CGFloat = 2.0 / 3.0
    static let designWidth: CGFloat = 244
    static let designHeight: CGFloat = designWidth * 37.5 / 40.9
    static let designButtonHeight: CGFloat = 4
    static let bodyWidth: CGFloat = (designWidth * scale).rounded()
    static let bodyHeight: CGFloat = (designHeight * scale).rounded()
    static let bodyCorner: CGFloat = 12 * scale
    static let buttonHeight: CGFloat = (designButtonHeight * scale).rounded()
    static let glassSide: CGFloat = designHeight - 10
    // A slimmer bezel keeps artwork readable at the compact desktop size.
    static let screenSide: CGFloat = 196
}

/// Sixth-generation nano: rolled aluminum edges, inset black glass, and a
/// square LCD. Artwork stays unobstructed until the pointer or focus enters.
struct NanoSixthView: View {
    let state: NowPlaying
    let isDark: Bool
    var onCommand: (MRCommand) -> Void
    var onMenu: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var isHovered = false
    @FocusState private var controlsFocused: Bool

    private var showsControls: Bool { isHovered || controlsFocused || voiceOverEnabled }
    private var metal: [Color] {
        (isDark
            ? [0.12, 0.37, 0.26, 0.29, 0.22, 0.36, 0.10]
            : [0.48, 0.94, 0.72, 0.78, 0.68, 0.96, 0.43])
            .map { Color(white: $0) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            hardwareButtons
                .accessibilityHidden(true)
                .allowsHitTesting(false)

            ZStack {
                enclosure
                glass
                screen
            }
            .frame(width: NanoSixthMetrics.designWidth, height: NanoSixthMetrics.designHeight)
            .offset(y: NanoSixthMetrics.designButtonHeight)
        }
        .frame(width: NanoSixthMetrics.designWidth,
               height: NanoSixthMetrics.designHeight + NanoSixthMetrics.designButtonHeight)
        .scaleEffect(NanoSixthMetrics.scale)
        .frame(width: ShellStyle.nano6.size.width, height: ShellStyle.nano6.size.height)
        .contentShape(RoundedRectangle(cornerRadius: NanoSixthMetrics.bodyCorner))
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: showsControls)
        .modifier(WindowDragging())
        .contextMenu {
            Button("Settings…", action: onMenu)
        }
    }

    private var enclosure: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(LinearGradient(
                stops: zip([0.0, 0.025, 0.08, 0.45, 0.90, 0.975, 1.0], metal)
                    .map { .init(color: $0.1, location: $0.0) },
                startPoint: .leading, endPoint: .trailing
            ))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.22), .clear, .black.opacity(0.12)],
                        startPoint: .top, endPoint: .bottom
                    ))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.75), .black.opacity(0.28), .white.opacity(0.45)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 0.8)
            }
    }

    private var hardwareButtons: some View {
        HStack(spacing: 18) {
            topButton(width: 22)
            topButton(width: 22)
            Spacer()
            topButton(width: 46)
        }
        .padding(.horizontal, 17)
        .frame(width: NanoSixthMetrics.designWidth)
    }

    private func topButton(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(LinearGradient(
                colors: [metal[1], metal[3], metal[0]],
                startPoint: .top, endPoint: .bottom
            ))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(.black.opacity(0.35), lineWidth: 0.5)
            }
            .frame(width: width, height: 7)
    }

    private var glass: some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .fill(Color(white: 0.015))
            .overlay {
                // The original glass catches a diagonal reflection at its upper left.
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: .zero)
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.46, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.16, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.17), .white.opacity(0.015)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                }
                .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.45), .black.opacity(0.8), .white.opacity(0.20)],
                        startPoint: .top, endPoint: .bottom
                    ), lineWidth: 0.8)
            }
            .frame(width: NanoSixthMetrics.glassSide, height: NanoSixthMetrics.glassSide)
    }

    private var screen: some View {
        ZStack {
            artwork
                .accessibilityHidden(true)
            playbackOverlay
                .opacity(showsControls ? 1 : 0)
                .allowsHitTesting(showsControls)
        }
        .frame(width: NanoSixthMetrics.screenSide, height: NanoSixthMetrics.screenSide)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.black.opacity(0.3), lineWidth: 0.5)
                .allowsHitTesting(false)
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.12)))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LinearGradient(
                    colors: [.black.opacity(0.8), .white.opacity(0.25)],
                    startPoint: .top, endPoint: .bottom
                ), lineWidth: 0.7)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Now Playing")
    }

    @ViewBuilder
    private var artwork: some View {
        if let image = state.artwork {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: NanoSixthMetrics.screenSide, height: NanoSixthMetrics.screenSide)
                .clipped()
        } else {
            ZStack {
                LinearGradient(colors: [Color(white: 0.23), Color(white: 0.07)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "music.note")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    private var playbackOverlay: some View {
        VStack(spacing: 0) {
            Button(action: onMenu) {
                VStack(spacing: 3) {
                    Text(state.title ?? "Not Playing")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                    if let artist = state.artist, !artist.isEmpty {
                        Text(artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(colors: [.black.opacity(0.82), .black.opacity(0.45)],
                                           startPoint: .top, endPoint: .bottom))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focused($controlsFocused)
            .accessibilityLabel("Open Settings")
            .accessibilityValue([state.title, state.artist].compactMap { $0 }.joined(separator: ", "))
            .help("Open Settings")

            Spacer(minLength: 0)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    transportButton("Previous Track", symbol: "backward.end.fill", command: .previousTrack)
                    transportButton(state.isPlaying ? "Pause" : "Play",
                                    symbol: state.isPlaying ? "pause.fill" : "play.fill",
                                    command: .togglePlayPause, prominent: true)
                    transportButton("Next Track", symbol: "forward.end.fill", command: .nextTrack)
                }
                if let duration = state.duration, duration.isFinite, duration > 0 {
                    let elapsed = min(max(state.elapsed ?? 0, 0), duration)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.3))
                            Capsule().fill(.white)
                                .frame(width: geometry.size.width * elapsed / duration)
                        }
                    }
                        .frame(height: 3)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Playback progress")
                        .accessibilityValue("\(formatTime(elapsed)) of \(formatTime(duration))")
                        .padding(.horizontal, 10)
                    HStack {
                        Text(formatTime(elapsed))
                        Spacer()
                        Text("−" + formatTime(duration - elapsed))
                    }
                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 2)
                    .padding(.horizontal, 10)
                }
            }
            .padding(.bottom, 8)
            // Expand before painting the background: the controls' intrinsic
            // width must not leave uncovered strips at the display edges.
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [.black.opacity(0.45), .black.opacity(0.82)],
                                       startPoint: .top, endPoint: .bottom))
        }
        .frame(width: NanoSixthMetrics.screenSide, height: NanoSixthMetrics.screenSide)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    private func transportButton(_ label: String, symbol: String, command: MRCommand,
                                 prominent: Bool = false) -> some View {
        Button { onCommand(command) } label: {
            ZStack {
                Image(systemName: symbol)
                    .foregroundStyle(Color(white: 0.4))
                    .offset(y: 0.75)
                Image(systemName: symbol)
                    .foregroundStyle(LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: Color(white: 0.96), location: 0.40),
                            .init(color: Color(white: 0.72), location: 0.65),
                            .init(color: Color(white: 0.88), location: 1)
                        ],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .shadow(color: .white.opacity(0.55), radius: 0.3, y: -0.5)
            }
                .font(.system(size: prominent ? 25 : 18, weight: .semibold))
                .offset(x: symbol == "play.fill" ? 1 : 0)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(NanoTransportStyle())
        .focused($controlsFocused)
        .accessibilityLabel(label)
        .help(label)
    }

    private func formatTime(_ time: Double) -> String {
        guard time.isFinite else { return "0:00" }
        let seconds = Int(min(max(time, 0), Double(Int.max / 2)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct NanoTransportStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .shadow(color: .black.opacity(0.22), radius: 1, y: 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
    }
}
