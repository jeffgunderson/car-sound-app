import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var selectedProfileID: String = SoundPackCatalog.defaultProfile.id
    var devModeEnabled: Bool = true
    var masterVolume: Float = 0.8
    var dataSource: DataSource = .simulator
    var simulatorRPM: Double = 500
    var simulatorThrottle: Double = 0
}

enum AppSettingsStore {
    private static let key = "appSettings.v1"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    static func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
