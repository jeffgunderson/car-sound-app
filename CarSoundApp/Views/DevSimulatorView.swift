import SwiftUI

struct DevSimulatorView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 16) {
            Text("Dev Simulator")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("RPM: \(Int(viewModel.simulatorRPM))")
                    .font(.subheadline)
                    .monospacedDigit()
                Slider(value: $viewModel.simulatorRPM, in: 500...7000, step: 50)
                    .onChange(of: viewModel.simulatorRPM) { _, _ in
                        viewModel.syncSimulatorProvider()
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Throttle: \(Int(viewModel.simulatorThrottle))%")
                    .font(.subheadline)
                    .monospacedDigit()
                Slider(value: $viewModel.simulatorThrottle, in: 0...100, step: 1)
                    .onChange(of: viewModel.simulatorThrottle) { _, _ in
                        viewModel.syncSimulatorProvider()
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Scenarios")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(SimulatorScenario.allCases.filter { $0 != .stoplight }) { scenario in
                        Button(scenario.displayName) {
                            viewModel.simulatorProviderAccess.applyScenario(scenario)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(SimulatorScenario.stoplight.displayName) {
                        viewModel.simulatorProviderAccess.applyScenario(.stoplight)
                    }
                    .buttonStyle(.bordered)
                    .gridCellColumns(2)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            viewModel.syncSimulatorProvider()
        }
    }
}

#Preview {
    DevSimulatorView()
        .environment(AppViewModel())
        .padding()
}
