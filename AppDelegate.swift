import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel?
    private var panelHosting: NSHostingView<PopoverView>?
    private var eventMonitor: Any?
    private var alertPanel: NSPanel?
    private var alertDismissTimer: Timer?
    private var reminderTimer: Timer?
    private var countdownTimer: Timer?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var nextReminderDate: Date?
    private var pausedRemainingInterval: TimeInterval?
    private var cancellables = Set<AnyCancellable>()

    let appState = AppState()


    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPanel()
        startReminderTimer()
        startCountdownTimer()

        appState.$isStanding.sink  { [weak self] _ in self?.refreshStatusButton() }.store(in: &cancellables)
        appState.$isRunning.sink   { [weak self] _ in self?.refreshStatusButton() }.store(in: &cancellables)
        appState.$standingIcon.sink { [weak self] _ in self?.refreshStatusButton() }.store(in: &cancellables)
        appState.$sittingIcon.sink  { [weak self] _ in self?.refreshStatusButton() }.store(in: &cancellables)
    }


    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = appState.currentIcon
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func refreshStatusButton() {
        DispatchQueue.main.async {
            self.statusItem.button?.title = self.appState.isRunning
                ? self.appState.currentIcon
                : "⏸"
        }
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: appState.isRunning ? "Pause" : "Resume",
            action: #selector(toggleReminders),
            keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }


    private func setupPanel() {
        let view = PopoverView(
            appState: appState,
            onToggle:    { [weak self] in self?.toggleReminders() },
            onRemindNow: { [weak self] in self?.remindNow() },
            onSettings:  { [weak self] in self?.openSettings() },
            onAbout:     { [weak self] in self?.openAbout() },
            onQuit:      { NSApplication.shared.terminate(nil) }
        )

        let hosting = NSHostingView(rootView: view)
        hosting.frame.size = hosting.fittingSize

        let p = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.contentView = hosting
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.level = .popUpMenu
        p.isReleasedWhenClosed = false
        p.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        p.animationBehavior = .utilityWindow

        panel = p
        panelHosting = hosting
    }

    private func togglePanel() {
        guard let panel else { return }
        panel.isVisible ? hidePanel() : showPanel()
    }

    private func showPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window,
              let panel, let hosting = panelHosting else { return }

        let size = hosting.fittingSize
        panel.setContentSize(size)

        let btnRect = button.convert(button.bounds, to: nil)
        let screen  = buttonWindow.convertToScreen(btnRect)

        let x = (screen.midX - size.width / 2).rounded()
        panel.setFrameTopLeftPoint(NSPoint(x: x, y: screen.minY))
        panel.makeKeyAndOrderFront(nil)

        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in self?.hidePanel() }
    }

    func hidePanel() {
        panel?.orderOut(nil)
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
    }

    func startReminderTimer() {
        reminderTimer?.invalidate()
        appState.isRunning = true

        let delay = pausedRemainingInterval ?? appState.currentInterval
        pausedRemainingInterval = nil
        nextReminderDate = Date().addingTimeInterval(delay)

        reminderTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.fireReminder()
            self.scheduleNextReminder()
        }
        refreshStatusButton()
    }

    func stopReminderTimer() {
        if let next = nextReminderDate {
            let remaining = next.timeIntervalSinceNow
            pausedRemainingInterval = remaining > 0 ? remaining : nil
        }
        reminderTimer?.invalidate()
        reminderTimer = nil
        nextReminderDate = nil
        appState.isRunning = false
        appState.countdownText = ""
        refreshStatusButton()
    }

    @objc func toggleReminders() {
        appState.isRunning ? stopReminderTimer() : startReminderTimer()
    }

    @objc func remindNow() {
        fireReminder()
        if appState.isRunning {
            reminderTimer?.invalidate()
            scheduleNextReminder()
        }
    }

    private func scheduleNextReminder() {
        let interval = appState.currentInterval
        nextReminderDate = Date().addingTimeInterval(interval)
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.fireReminder()
            self.scheduleNextReminder()
        }
    }

    private func fireReminder() {
        let prevMins = Int(appState.currentInterval / 60)
        appState.isStanding.toggle()

        let title = appState.isStanding ? "Time to Stand Up!" : "Time to Sit Down!"
        let body  = appState.isStanding
            ? "You've been sitting for \(prevMins) minutes — time to stand!"
            : "You've been standing for \(prevMins) minutes — take a seat!"

        appState.playSound(forStanding: appState.isStanding)

        if appState.showVisualAlert {
            showVisualAlert(icon: appState.currentIcon, title: title, subtitle: body)
        } else {
            let t = title.replacingOccurrences(of: "\"", with: "\\\"")
            let b = body.replacingOccurrences(of: "\"", with: "\\\"")
            NSAppleScript(source: "display notification \"\(b)\" with title \"\(t)\"")?.executeAndReturnError(nil)
        }

        refreshStatusButton()
    }


    private func startCountdownTimer() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.appState.updateCountdown(nextDate: self?.nextReminderDate)
        }
    }


    private func showVisualAlert(icon: String, title: String, subtitle: String) {
        alertDismissTimer?.invalidate()
        alertPanel?.orderOut(nil)

        let view = AlertOverlayView(icon: icon, title: title, subtitle: subtitle)
        let hosting = NSHostingView(rootView: view)
        hosting.frame.size = hosting.fittingSize

        let p: NSPanel = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.contentView = hosting
        p.backgroundColor = NSColor.clear
        p.isOpaque = false
        p.hasShadow = true
        p.level = NSWindow.Level.floating
        p.isReleasedWhenClosed = false
        p.collectionBehavior = NSWindow.CollectionBehavior([.canJoinAllSpaces, .ignoresCycle])

        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            let x = f.maxX - hosting.frame.width - 12
            let y = f.maxY - hosting.frame.height - 8
            p.setFrameOrigin(NSPoint(x: x, y: y))
        }

        alertPanel = p
        p.alphaValue = 0
        p.makeKeyAndOrderFront(nil as AnyObject?)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            p.animator().alphaValue = 1
        }

        alertDismissTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            guard let p = self?.alertPanel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.4
                p.animator().alphaValue = 0
            }, completionHandler: { p.orderOut(nil) })
        }
    }


    func openAbout() {
        hidePanel()

        if aboutWindow == nil {
            let view = AboutView { [weak self] in self?.aboutWindow?.orderOut(nil) }
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "About"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            aboutWindow = window
        }

        aboutWindow?.center()
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }


    func openSettings() {
        hidePanel()

        if settingsWindow == nil {
            let view = SettingsView(appState: appState) { [weak self] in
                guard let self else { return }
                self.settingsWindow?.orderOut(nil)
                if self.appState.isRunning { self.startReminderTimer() }
                self.refreshStatusButton()
            }
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Ascend — Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
