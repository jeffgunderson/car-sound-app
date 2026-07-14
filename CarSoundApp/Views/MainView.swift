import SwiftUI

struct MainView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero

                    connectionBadge

                    if let audioErrorMessage = viewModel.audioErrorMessage {
                        RailwayCard {
                            Text(audioErrorMessage)
                                .font(RailwayTheme.caption)
                                .foregroundStyle(RailwayTheme.statusUnavailable)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    profileCard
                    volumeCard(volume: $viewModel.masterVolume)

                    if viewModel.devModeEnabled, viewModel.selectedProfile.isSynthesized {
                        NavigationLink {
                            SynthTunerView()
                        } label: {
                            Label("Synth Tuner", systemImage: "slider.horizontal.3")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RailwayGhostButtonStyle())
                    }

                    Button {
                        viewModel.togglePlayback()
                    } label: {
                        Label(
                            viewModel.isPlaying ? "Stop" : "Play",
                            systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(RailwayPlaybackButtonStyle(isPlaying: viewModel.isPlaying))

                    if !viewModel.audioDebugStatus.isEmpty {
                        RailwayCard(padding: 12, cornerRadius: RailwayTheme.radiusControl + 4) {
                            Text(viewModel.audioDebugStatus)
                                .font(RailwayTheme.captionMedium)
                                .foregroundStyle(RailwayTheme.ink)
                                .monospacedDigit()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if viewModel.devModeEnabled {
                        DevSimulatorView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RailwayBackground()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(RailwayTheme.ui(16, weight: .medium))
                            .foregroundStyle(RailwayTheme.inkSecondary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .railwayClearNavigationBackground()
        }
        .preferredColorScheme(.dark)
        .tint(RailwayTheme.primary)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Engine Sound")
                .font(RailwayTheme.display(34))
                .foregroundStyle(RailwayTheme.ink)
                .tracking(-0.8)

            Text(heroSubtitle)
                .font(RailwayTheme.caption)
                .foregroundStyle(RailwayTheme.inkSecondary)
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var heroSubtitle: String {
        if viewModel.isPlaying {
            return "Playing engine sound · \(viewModel.selectedProfile.name)"
        }
        return "Telemetry-driven cabin sound · Tundra TRD"
    }

    private var connectionBadge: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.7), radius: 4)

            Text(viewModel.connectionBadgeText)
                .font(RailwayTheme.captionMedium)
                .foregroundStyle(RailwayTheme.inkSecondary)

            Spacer()
        }
        .railwayChip()
    }

    private var profileCard: some View {
        RailwayCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sound Profile")
                    .font(RailwayTheme.bodyMedium)
                    .foregroundStyle(RailwayTheme.ink)

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
                .font(RailwayTheme.body)
                .tint(RailwayTheme.ink)
            }
        }
    }

    private func volumeCard(volume: Binding<Float>) -> some View {
        RailwayCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Master Volume")
                        .font(RailwayTheme.bodyMedium)
                        .foregroundStyle(RailwayTheme.ink)
                    Spacer()
                    Text("\(Int(volume.wrappedValue * 100))%")
                        .font(RailwayTheme.caption)
                        .foregroundStyle(RailwayTheme.inkSecondary)
                        .monospacedDigit()
                }

                Slider(value: volume, in: 0...1)
                    .tint(RailwayTheme.primary)
            }
        }
    }

    private var statusColor: Color {
        switch viewModel.connectionStatus {
        case .connected:
            return RailwayTheme.statusConnected
        case .connecting:
            return RailwayTheme.statusConnecting
        case .disconnected:
            return RailwayTheme.statusDisconnected
        case .unavailable:
            return RailwayTheme.statusUnavailable
        }
    }
}

#Preview {
    MainView()
        .environment(AppViewModel())
}
