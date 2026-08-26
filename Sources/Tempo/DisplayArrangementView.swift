import SwiftUI

struct DisplayArrangementView: View {
    let displays: [DisplayInfo]
    let isRecording: Bool

    var body: some View {
        GeometryReader { proxy in
            if displays.isEmpty {
                ContentUnavailableView("Nenhuma tela encontrada", systemImage: "display.trianglebadge.exclamationmark")
            } else {
                let union = displays.map(\.frame).reduce(CGRect.null) { $0.union($1) }
                let scale = min((proxy.size.width - 40) / union.width, (proxy.size.height - 40) / union.height)
                let composedWidth = union.width * scale
                let composedHeight = union.height * scale
                let originX = (proxy.size.width - composedWidth) / 2
                let originY = (proxy.size.height - composedHeight) / 2

                ZStack {
                    ForEach(Array(displays.enumerated()), id: \.element.id) { index, display in
                        let x = originX + (display.frame.minX - union.minX) * scale
                        let y = originY + (display.frame.minY - union.minY) * scale
                        let width = display.frame.width * scale
                        let height = display.frame.height * scale

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(display.isBuiltIn ? Color.tempoMain : Color.tempoExternal)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(.white.opacity(0.55), lineWidth: 1)
                            }
                            .overlay(alignment: .topLeading) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(display.title)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    Text(display.resolution)
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .opacity(0.68)
                                }
                                .foregroundStyle(.white)
                                .padding(10)
                            }
                            .overlay {
                                if isRecording {
                                    ScanLine(delay: Double(index) * 0.18)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            .frame(width: width, height: height)
                            .position(x: x + width / 2, y: y + height / 2)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Arranjo de \(displays.count) telas")
    }
}

private struct ScanLine: View {
    let delay: Double
    @State private var atBottom = false

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.65), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .shadow(color: .white.opacity(0.45), radius: 4)
                .offset(y: atBottom ? proxy.size.height : 0)
                .onAppear {
                    withAnimation(.linear(duration: 3.4).repeatForever(autoreverses: false).delay(delay)) {
                        atBottom = true
                    }
                }
        }
        .allowsHitTesting(false)
    }
}
