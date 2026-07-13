import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            Section("Data Source") {
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

                if viewModel.dataSource == .vLinker {
                    LabeledContent("vLinker Device") {
                        Text("Not available yet")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Developer") {
                Toggle("Dev Mode (Simulator Controls)", isOn: $viewModel.devModeEnabled)

                if viewModel.selectedProfile.isSynthesized {
                    NavigationLink("Synth Tuner") {
                        SynthTunerView()
                    }
                }
            }

            Section("About") {
                LabeledContent("Sound Pack", value: "Tundra TRD")
                LabeledContent("Profiles", value: "\(viewModel.soundProfiles.count)")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppViewModel())
    }
}
