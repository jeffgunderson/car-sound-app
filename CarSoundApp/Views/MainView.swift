import SwiftUI

struct MainView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(spacing: 24) {
                connectionBadge

                if let audioErrorMessage = viewModel.audioErrorMessage {
                    Text(audioErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if viewModel.isPlaying {
                    Text("Playing engine sound")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.audioDebugStatus.isEmpty {
                    Text(viewModel.audioDebugStatus)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Sound Profile")
                        .font(.headline)

                    Picker("Sound Profile", selection: Binding(
                        get: { viewModel.selectedProfile.id },
                        set: { newID in
                            guard let profile = viewModel.soundProfiles.first(where: { $0.id == newID }) else {
                                return
                            }
                            viewModel.selectProfile(profile)
                        }
                    )) {
                        ForEach(viewModel.soundProfiles) { profile in
                            Text(profile.name).tag(profile.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Master Volume")
                        .font(.headline)
                    Slider(value: $viewModel.masterVolume, in: 0...1)
                }

                if viewModel.selectedProfile.isSynthesized {
                    NavigationLink {
                        SynthTunerView()
                    } label: {
                        Label("Synth Tuner", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Label(
                        viewModel.isPlaying ? "Stop" : "Play",
                        systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if viewModel.devModeEnabled {
                    DevSimulatorView()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Active Engine Sound")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    private var connectionBadge: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(viewModel.connectionBadgeText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
    }

    private var statusColor: Color {
        switch viewModel.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .orange
        case .unavailable:
            return .red
        }
    }
}

#Preview {
    MainView()
        .environment(AppViewModel())
}
