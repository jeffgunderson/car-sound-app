import SwiftUI

@main
struct CarSoundAppApp: App {
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(viewModel)
                .preferredColorScheme(.dark)
                .tint(RailwayTheme.primary)
        }
    }
}
