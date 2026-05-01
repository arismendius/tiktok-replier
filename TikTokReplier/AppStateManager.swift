import Foundation
import Combine

@MainActor
class AppStateManager: ObservableObject {
    @Published var engine = ReplyEngine()
    @Published var config = ConfigStore.shared.config
    var onStatusChange: ((String) -> Void)?
    private var ca
