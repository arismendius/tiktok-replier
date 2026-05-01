import Foundation
import Combine

@MainActor
class AppStateManager: ObservableObject {
    @Published var engine = ReplyEngine()
    @Published var config = ConfigStore.shared.config
    var onStatusChange: ((String) -> Void)?
    private var cancellables = Set<AnyCancellable>()

    init() {
        engine.$currentStatus.sink { [weak self] s in self?.onStatusChange?(s) }.store(in: &cancellables)
        $config.dropFirst().sink { ConfigStore.shared.config = $0 }.store(in: &cancellables)
    }
}
