import SwiftUI

struct DevSimulatorView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        RailwayCard(cornerRadius: RailwayTheme.radiusPanel) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Dev Simulator")
                    .font(RailwayTheme.displayRegular(22))
                    .foregroundStyle(RailwayTheme.ink)
                    .tracking(-0.3)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("RPM")
                            .font(RailwayTheme.captionMedium)
                            .foregroundStyle(RailwayTheme.inkSecondary)
                        Spacer()
                        Text("\(Int(viewModel.simulatorRPM))")
                            .font(RailwayTheme.bodyMedium)
                            .foregroundStyle(RailwayTheme.ink)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.simulatorRPM, in: 500...7000, step: 50)
                        .tint(RailwayTheme.primary)
                        .onChange(of: viewModel.simulatorRPM) { _, _ in
                            viewModel.syncSimulatorProvider()
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Throttle")
                            .font(RailwayTheme.captionMedium)
                            .foregroundStyle(RailwayTheme.inkSecondary)
                        Spacer()
                        Text("\(Int(viewModel.simulatorThrottle))%")
                            .font(RailwayTheme.bodyMedium)
                            .foregroundStyle(RailwayTheme.ink)
                            .monospacedDigit()
                    }
                    Slider(value: $viewModel.simulatorThrottle, in: 0...100, step: 1)
                        .tint(RailwayTheme.primary)
                        .onChange(of: viewModel.simulatorThrottle) { _, _ in
                            viewModel.syncSimulatorProvider()
                        }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Scenarios")
                        .font(RailwayTheme.captionMedium)
                        .foregroundStyle(RailwayTheme.inkSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(SimulatorScenario.allCases.filter { $0 != .stoplight }) { scenario in
                            Button(scenario.displayName) {
                                viewModel.simulatorProviderAccess.applyScenario(scenario)
                            }
                            .buttonStyle(RailwayGhostButtonStyle())
                        }

                        Button(SimulatorScenario.stoplight.displayName) {
                            viewModel.simulatorProviderAccess.applyScenario(.stoplight)
                        }
                        .buttonStyle(RailwayGhostButtonStyle())
                        .gridCellColumns(2)
                    }
                }
            }
        }
        .onAppear {
            viewModel.syncSimulatorProvider()
        }
    }
}

#Preview {
    ZStack {
        RailwayBackground()
        DevSimulatorView()
            .environment(AppViewModel())
            .padding()
    }
}
