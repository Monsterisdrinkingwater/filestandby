import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: ShelfStore!
    private var shelfController: ShelfPanelController!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        store = ShelfStore()
        shelfController = ShelfPanelController(store: store)
        configureStatusItem()

        shelfController.showEdgeHandle()
        shelfController.showShelf()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = TransferBoxMarkImage.image(size: 16, style: .color)
            button.toolTip = "File Standby"
        }

        let menu = NSMenu()
        let toggleItem = NSMenuItem(
            title: "显示或收起文件架",
            action: #selector(toggleShelf),
            keyEquivalent: "s"
        )
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        toggleItem.target = self
        menu.addItem(toggleItem)

        let addItem = NSMenuItem(
            title: "添加文件…",
            action: #selector(chooseFiles),
            keyEquivalent: "o"
        )
        addItem.keyEquivalentModifierMask = [.command]
        addItem.target = self
        menu.addItem(addItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 File Standby",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc
    private func toggleShelf() {
        shelfController.toggleShelf()
    }

    @objc
    private func chooseFiles() {
        shelfController.showShelf()

        let panel = NSOpenPanel()
        panel.title = "选择要暂存的项目"
        panel.prompt = "加入文件架"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true

        panel.begin { [weak self] response in
            guard response == .OK else { return }
            self?.store.add(urls: panel.urls)
        }
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }
}
