import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header

            DisplayArrangementView(displays: model.displays, isRecording: model.isRecording)
                .frame(height: 245)
                .padding(.horizontal, 28)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.tempoStage)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.72), lineWidth: 1)
                        }
                        .shadow(color: Color.tempoInk.opacity(0.08), radius: 24, y: 12)
                }
                .padding(.horizontal, 28)

            statusArea
                .frame(minHeight: 84)
                .padding(.horizontal, 34)

            Divider().opacity(0.45)

            controls
                .padding(24)
        }
        .frame(width: 620, height: 560)
        .background(Color.tempoCanvas)
        .preferredColorScheme(.light)
        .alert("Continuar o timelapse?", isPresented: $model.showResumePrompt) {
            Button("Continuar", action: model.resumeRecording)
            Button("Manter pausado", role: .cancel, action: model.keepPaused)
        } message: {
            Text(model.resumePromptMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TEMPO")
                    .font(.custom("Avenir Next Condensed", size: 28).weight(.heavy))
                    .tracking(3.5)
                    .foregroundStyle(Color.tempoInk)
                Text("Seu dia inteiro, em até 36 segundos.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tempoMuted)
            }
            Spacer()
            if model.isRecording {
                Label("GRAVANDO", systemImage: "record.circle.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tempoRecord)
                    .symbolEffect(.pulse)
            } else if model.isPaused {
                Label("PAUSADO", systemImage: "pause.circle.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.tempoPause)
            } else {
                Text("LOCAL • SEM ÁUDIO")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.tempoMuted)
            }
        }
        .padding(.horizontal, 34)
        .padding(.top, 26)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private var statusArea: some View {
        switch model.phase {
        case .idle:
            infoRow(title: "\(model.displays.count) \(model.displays.count == 1 ? "tela pronta" : "telas prontas")", detail: "As posições acima serão mantidas no vídeo.")
        case .requestingPermission:
            infoRow(title: "Verificando permissão…", detail: "O macOS pode pedir acesso à gravação da tela.")
        case .recording:
            if model.frameCount == 0 {
                infoRow(
                    title: model.lastCaptureErrorMessage == nil ? "Preparando a primeira captura…" : "Tentando reconectar à captura…",
                    detail: model.lastCaptureErrorMessage ?? "O relógio começará quando o primeiro quadro for salvo."
                )
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack {
                        metric(formatDuration(model.recordingDuration(at: context.date)), label: "CAPTURADO")
                        Spacer()
                        metric("\(model.frameCount)", label: "QUADROS")
                        Spacer()
                        metric(formatInterval(model.captureInterval), label: "INTERVALO")
                    }
                }
            }
        case .paused(let reason):
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(reason.title, systemImage: reason.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.tempoPause)
                    Text(model.pausedDetail(for: reason))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.tempoMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                metric(formatDuration(model.recordingDuration()), label: "CAPTURADO")
                metric("\(model.frameCount)", label: "QUADROS")
            }
        case .exporting:
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("Criando o vídeo…")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("\(Int(model.exportProgress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.tempoMuted)
                }
                ProgressView(value: model.exportProgress)
                    .tint(Color.tempoMain)
            }
        case .finished(let url):
            HStack {
                infoRow(title: "Vídeo criado", detail: url.lastPathComponent)
                Spacer()
                Button("Mostrar no Finder") { model.revealFinishedVideo() }
                    .buttonStyle(.bordered)
            }
        case .failed(let message):
            VStack(alignment: .leading, spacing: 6) {
                Label("Ação necessária", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.tempoRecord)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.tempoMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            if model.canStart {
                VStack(alignment: .leading, spacing: 5) {
                    Text("QUALIDADE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.tempoMuted)
                    Picker("Qualidade", selection: $model.quality) {
                        ForEach(OutputQuality.allCases) { quality in
                            Text("\(quality.title) · \(quality.detail)").tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    .labelsHidden()
                }
            } else {
                Label(controlHint, systemImage: controlHintIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.tempoMuted)
            }

            Spacer()

            actionButtons
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch model.phase {
        case .recording:
            HStack(spacing: 10) {
                Button(action: model.pauseManually) {
                    Label("Pausar", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if model.canExport {
                    Button(action: model.stopAndExport) {
                        Label("Parar e criar vídeo", systemImage: "stop.fill")
                            .frame(minWidth: 148)
                    }
                    .buttonStyle(TempoButtonStyle(color: Color.tempoRecord))
                } else {
                    Button(action: model.cancelRecording) {
                        Label("Cancelar", systemImage: "xmark")
                            .frame(minWidth: 104)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        case .paused:
            HStack(spacing: 10) {
                if model.canExport {
                    Button(action: model.stopAndExport) {
                        Label("Criar vídeo", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button(action: model.cancelRecording) {
                        Label("Cancelar", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button(action: model.resumeRecording) {
                    Label("Continuar", systemImage: "play.fill")
                        .frame(minWidth: 104)
                }
                .buttonStyle(TempoButtonStyle(color: Color.tempoMain))
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canResume)
            }
        case .exporting, .requestingPermission:
            Button("Aguarde…") { }
                .buttonStyle(TempoButtonStyle(color: Color.tempoMuted))
                .disabled(true)
        case .failed(let message):
            if message.contains("Ajustes do Sistema") {
                Button("Abrir Ajustes", action: model.openPrivacySettings)
                    .buttonStyle(TempoButtonStyle(color: Color.tempoMain))
            } else {
                Button("Tentar novamente", action: model.reset)
                    .buttonStyle(TempoButtonStyle(color: Color.tempoMain))
            }
        case .finished:
            Button("Nova gravação", action: model.reset)
                .buttonStyle(TempoButtonStyle(color: Color.tempoMain))
        case .idle:
            Button(action: model.start) {
                Label("Iniciar timelapse", systemImage: "record.circle")
                    .frame(minWidth: 150)
            }
            .buttonStyle(TempoButtonStyle(color: Color.tempoMain))
            .keyboardShortcut(.defaultAction)
        }
    }

    private var controlHint: String {
        if model.isPaused { return "Quadros preservados no disco" }
        if model.phase == .exporting { return "Mantenha o app aberto" }
        return "Captura leve em segundo plano"
    }

    private var controlHintIcon: String {
        if model.isPaused { return "externaldrive.fill.badge.checkmark" }
        if model.phase == .exporting { return "film.stack" }
        return "leaf"
    }

    private func infoRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 14, weight: .semibold))
            Text(detail).font(.system(size: 12)).foregroundStyle(Color.tempoMuted)
        }
    }

    private func metric(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.tempoInk)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.tempoMuted)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        interval < 60 ? "\(Int(interval)) s" : "\(Int(interval / 60)) min"
    }
}

private struct TempoButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 42)
            .background(color.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: color.opacity(0.22), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
