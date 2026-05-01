import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    lazy var stateManager = AppStateManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🎵"
            button.action = #selector(togglePopover)
            button.target = self
        }
        popover = NSPopover()
        popover.contentSize = NSSize(width: 440, height: 560)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(state: stateManager)
        )
        stateManager.onStatusChange = { [weak self] status in
            DispatchQueue.main.async {
                let short = status.count > 25 ? String(status.prefix(25)) + "…" : status
                self?.statusItem.button?.title = short.isEmpty ? "🎵" : "🎵 \(short)"
            }
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
