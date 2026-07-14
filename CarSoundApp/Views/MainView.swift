import SwiftUI

struct MainView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedProfileID: String = SoundPackCatalog.defaultProfile.id

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                RailwayBackground()

                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    profileCarousel
                        .frame(height: 220)

                    Spacer(minLength: 28)

                    connectionLine
                        .padding(.bottom, 28)

                    if let audioErrorMessage = viewModel.audioErrorMessage {
                        Text(audioErrorMessage)
                            .font(RailwayTheme.caption)
                            .foregroundStyle(RailwayTheme.statusUnavailable)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 20)
                    }

                    playButton
                        .padding(.bottom, 36)

                    volumeSection(volume: $viewModel.masterVolume)
                        .padding(.horizontal, 40)

                    Spacer(minLength: 48)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(RailwayTheme.inkSecondary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .railwayClearNavigationBackground()
            .onAppear {
                selectedProfileID = viewModel.selectedProfile.id
            }
            .onChange(of: viewModel.selectedProfile.id) { _, newID in
                if selectedProfileID != newID {
                    selectedProfileID = newID
                }
            }
            .onChange(of: selectedProfileID) { _, newID in
                guard newID != viewModel.selectedProfile.id,
                      let profile = viewModel.soundProfiles.first(where: { $0.id == newID }) else {
                    return
                }
                viewModel.selectProfile(profile)
            }
        }
        .preferredColorScheme(.dark)
        .tint(RailwayTheme.primary)
    }

    private var profileCarousel: some View {
        TabView(selection: $selectedProfileID) {
            ForEach(viewModel.soundProfiles) { profile in
                VStack(spacing: 12) {
                    Text(profile.name)
                        .font(RailwayTheme.display(34))
                        .foregroundStyle(RailwayTheme.ink)
                        .tracking(-0.8)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)

                    Text(profile.selectionSubtitle)
                        .font(RailwayTheme.caption)
                        .foregroundStyle(RailwayTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(profile.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }

    private var connectionLine: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(viewModel.connectionBadgeText)
                .font(RailwayTheme.caption)
                .foregroundStyle(RailwayTheme.inkSecondary)
        }
    }

    private var playButton: some View {
        Button {
            viewModel.togglePlayback()
        } label: {
            Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                .offset(x: viewModel.isPlaying ? 0 : 2)
        }
        .buttonStyle(RailwayCircularPlayButtonStyle(isPlaying: viewModel.isPlaying))
        .accessibilityLabel(viewModel.isPlaying ? "Stop" : "Play")
    }

    private func volumeSection(volume: Binding<Float>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RailwayTheme.inkTertiary)
                Slider(value: volume, in: 0...1)
                    .tint(RailwayTheme.ink)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RailwayTheme.inkTertiary)
            }

            Text("\(Int(volume.wrappedValue * 100))%")
                .font(RailwayTheme.micro)
                .foregroundStyle(RailwayTheme.inkTertiary)
                .monospacedDigit()
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
