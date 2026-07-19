import Foundation

final class SessionHistoryStore {
    static let shared = SessionHistoryStore()

    private let key = "tanSessionHistory"
    private let maxEntries = 50

    private init() {}

    func load() -> [TanSession] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let sessions = try? JSONDecoder().decode([TanSession].self, from: data) else {
            return []
        }
        return sessions
    }

    func add(_ session: TanSession) {
        var sessions = load()
        sessions.insert(session, at: 0)
        if sessions.count > maxEntries {
            sessions = Array(sessions.prefix(maxEntries))
        }
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
