import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        RailwayGlassStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Settings")
                        .font(RailwayTheme.display(30))
                        .foregroundStyle(RailwayTheme.ink)
                        .tracking(-0.6)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        RailwaySectionHeader(title: "Data Source")
                        RailwayCard {
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
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        RailwaySectionHeader(title: "Developer")
                        RailwayCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle(isOn: $viewModel.devModeEnabled) {
                                    Text("Dev Mode (Simulator Controls)")
                                        .font(RailwayTheme.body)
                                        .foregroundStyle(RailwayTheme.ink)
                                }
                                .tint(RailwayTheme.primary)

                                if viewModel.selectedProfile.isSynthesized {
                                    NavigationLink {
                                        SynthTunerView()
                                    } label: {
                                        HStack {
                                            Text("Synth Tuner")
                                                .font(RailwayTheme.body)
                                                .foregroundStyle(RailwayTheme.ink)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(RailwayTheme.caption)
                                                .foregroundStyle(RailwayTheme.inkTertiary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        RailwaySectionHeader(title: "About")
                        RailwayCard {
                            VStack(spacing: 12) {
                                aboutRow("Sound Pack", "Tundra TRD")
                                Divider().overlay(RailwayTheme.border)
                                aboutRow("Profiles", "\(viewModel.soundProfiles.count)")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            RailwayBackground()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .railwayClearNavigationBackground()
        .preferredColorScheme(.dark)
        .tint(RailwayTheme.primary)
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
