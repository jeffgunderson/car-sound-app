import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Settings")
                    .font(RailwayTheme.display(30))
                    .foregroundStyle(RailwayTheme.ink)
                    .tracking(-0.6)
                    .padding(.top, 8)

                settingsSection(title: "Data Source") {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Provider")
                            .font(RailwayTheme.captionMedium)
                            .foregroundStyle(RailwayTheme.inkSecondary)

                        Picker("Provider", selection: Binding(
                            get: { viewModel.dataSource },
                            set: { newSource in
                                viewModel.setDataSource(newSource)
                            }
                        )) {
                            ForEach(DataSource.allCases) { source in
                                Text(source.displayName).tag(source)
                            }
                        }
                        .pickerStyle(.segmented)

                        if viewModel.dataSource == .vLinker {
                            HStack {
                                Text("vLinker Device")
                                    .font(RailwayTheme.body)
                                    .foregroundStyle(RailwayTheme.ink)
                                Spacer()
                                Text("Not available yet")
                                    .font(RailwayTheme.caption)
                                    .foregroundStyle(RailwayTheme.inkTertiary)
                            }
                        }
                    }
                }

                settingsSection(title: "Developer") {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $viewModel.devModeEnabled) {
                            Text("Dev Mode")
                                .font(RailwayTheme.body)
                                .foregroundStyle(RailwayTheme.ink)
                        }
                        .tint(RailwayTheme.inkSecondary)

                        if viewModel.devModeEnabled {
                            if viewModel.selectedProfile.isSynthesized {
                                NavigationLink {
                                    SynthTunerView()
                                } label: {
                                    settingsRow(title: "Synth Tuner", showsChevron: true)
                                }
                            }

                            NavigationLink {
                                ScrollView {
                                    DevSimulatorView()
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                }
                                .scrollContentBackground(.hidden)
                                .background(RailwayBackground())
                                .navigationTitle("Simulator")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbarBackground(.hidden, for: .navigationBar)
                                .railwayClearNavigationBackground()
                            } label: {
                                settingsRow(title: "Simulator", showsChevron: true)
                            }
                        }
                    }
                }

                settingsSection(title: "About") {
                    VStack(spacing: 12) {
                        aboutRow("Sound Pack", "Tundra TRD")
                        Divider().overlay(RailwayTheme.border)
                        aboutRow("Profiles", "\(viewModel.soundProfiles.count)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RailwayBackground()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .railwayClearNavigationBackground()
        .preferredColorScheme(.dark)
        .tint(RailwayTheme.primary)
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RailwaySectionHeader(title: title)
            RailwayCard {
                content()
            }
        }
    }

    private func settingsRow(title: String, showsChevron: Bool) -> some View {
        HStack {
            Text(title)
                .font(RailwayTheme.body)
                .foregroundStyle(RailwayTheme.ink)
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(RailwayTheme.caption)
                    .foregroundStyle(RailwayTheme.inkTertiary)
            }
        }
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(RailwayTheme.body)
                .foregroundStyle(RailwayTheme.ink)
            Spacer()
            Text(value)
                .font(RailwayTheme.caption)
                .foregroundStyle(RailwayTheme.inkSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppViewModel())
    }
}
