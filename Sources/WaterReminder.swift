import Cocoa
import ServiceManagement

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var countdownTimer: Timer?
    var lastDrinkTime = Date()
    var lastCheckTime = Date()
    var currentInterval: TimeInterval = 0
    var isFirstSnooze = true
    var alertOpen = false

    // UserDefaults keys
    let kBaseInterval = "baseInterval"
    let kFirstSnooze = "firstSnoozeInterval"
    let kMinInterval = "minInterval"
    let kSoundEnabled = "soundEnabled"
    let kLaunchAtLogin = "launchAtLogin"
    let kSleepThreshold: TimeInterval = 300

    var baseInterval: TimeInterval {
        get { UserDefaults.standard.double(forKey: kBaseInterval).clamped(min: 60) }
        set { UserDefaults.standard.set(newValue, forKey: kBaseInterval) }
    }
    var firstSnoozeInterval: TimeInterval {
        get { UserDefaults.standard.double(forKey: kFirstSnooze).clamped(min: 10) }
        set { UserDefaults.standard.set(newValue, forKey: kFirstSnooze) }
    }
    var minInterval: TimeInterval {
        get { UserDefaults.standard.double(forKey: kMinInterval).clamped(min: 5) }
        set { UserDefaults.standard.set(newValue, forKey: kMinInterval) }
    }
    var soundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: kSoundEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: kSoundEnabled) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaults()
        currentInterval = baseInterval

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Use a small water droplet image for the icon
            let iconSize = NSSize(width: 18, height: 18)
            let img = NSImage(size: iconSize)
            img.lockFocus()
            let str = "💧" as NSString
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13)]
            let strSize = str.size(withAttributes: attrs)
            str.draw(at: NSPoint(
                x: (iconSize.width - strSize.width) / 2,
                y: (iconSize.height - strSize.height) / 2
            ), withAttributes: attrs)
            img.unlockFocus()
            img.isTemplate = false
            button.image = img
            button.imagePosition = .imageLeft
            button.title = " 30:00"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        }
        buildMenu()
        updateMenuBarTitle()

        // 1-second timer for countdown
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(countdownTimer!, forMode: .common)

        // Wake from sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            kBaseInterval: 1800.0,
            kFirstSnooze: 600.0,
            kMinInterval: 15.0,
            kSoundEnabled: true,
            kLaunchAtLogin: false
        ])
    }

    // MARK: - Menu

    func buildMenu() {
        let menu = NSMenu()

        let infoItem = NSMenuItem(title: "Next reminder: --:--", action: nil, keyEquivalent: "")
        infoItem.tag = 100
        infoItem.isEnabled = false
        menu.addItem(infoItem)

        menu.addItem(NSMenuItem.separator())

        let drankItem = NSMenuItem(title: "I Drank Water ✓", action: #selector(drankWater), keyEquivalent: "d")
        drankItem.target = self
        menu.addItem(drankItem)

        let snoozeItem = NSMenuItem(title: "Snooze", action: #selector(snoozeFromMenu), keyEquivalent: "s")
        snoozeItem.tag = 101
        snoozeItem.target = self
        menu.addItem(snoozeItem)

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let quitItem = NSMenuItem(title: "Quit Water Reminder", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func updateMenuBarTitle() {
        let remaining = max(0, currentInterval - Date().timeIntervalSince(lastDrinkTime))
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        statusItem.button?.title = String(format: " %d:%02d", mins, secs)

        // Update info item in menu
        if let menu = statusItem.menu, let infoItem = menu.item(withTag: 100) {
            infoItem.title = String(format: "Next reminder in %d:%02d", mins, secs)
        }

        // Update snooze label
        if let menu = statusItem.menu, let snoozeItem = menu.item(withTag: 101) {
            snoozeItem.title = "Snooze (\(formatNextSnooze()))"
        }
    }

    // MARK: - Timer Logic

    func tick() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastDrinkTime)

        updateMenuBarTitle()

        if !alertOpen && elapsed >= currentInterval {
            if elapsed >= 60 {
                let mins = Int(elapsed) / 60
                showReminder("It's been \(mins) min since your last water. Drink up!")
            } else {
                showReminder("Drink water! You keep snoozing!")
            }
        }
    }

    @objc func didWake(_ notification: Notification) {
        let gap = Date().timeIntervalSince(lastCheckTime)
        if gap >= kSleepThreshold {
            isFirstSnooze = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showReminder("Welcome back! Have some water after your break.")
            }
        }
        lastCheckTime = Date()
    }

    // MARK: - Reminder

    func showReminder(_ msg: String) {
        guard !alertOpen else { return }
        alertOpen = true

        if soundEnabled { NSSound.beep() }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "💧 Drink Water!"
        alert.informativeText = msg
        alert.alertStyle = .informational

        // Load icon
        let iconPath = Bundle.main.resourcePath.map { $0 + "/applet.icns" } ?? ""
        if let icon = NSImage(contentsOfFile: iconPath) {
            alert.icon = icon
        }

        let snoozeInfo = formatNextSnooze()
        alert.addButton(withTitle: "I Drank Water ✓")
        alert.addButton(withTitle: "Snooze (\(snoozeInfo))")

        // Auto-dismiss timer (2 min)
        var dismissed = false
        let autoTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: false) { _ in
            if !dismissed {
                dismissed = true
                NSApp.abortModal()
            }
        }
        RunLoop.current.add(autoTimer, forMode: .common)

        let response = alert.runModal()
        dismissed = true
        autoTimer.invalidate()

        if response == .alertFirstButtonReturn {
            doAck()
        } else {
            doSnooze()
        }

        alertOpen = false
        lastCheckTime = Date()
    }

    // MARK: - Actions

    func doAck() {
        lastDrinkTime = Date()
        currentInterval = baseInterval
        isFirstSnooze = true
        updateMenuBarTitle()
    }

    func doSnooze() {
        if isFirstSnooze {
            currentInterval = firstSnoozeInterval
            isFirstSnooze = false
        } else {
            currentInterval = max(currentInterval / 2, minInterval)
        }
        lastDrinkTime = Date()
        updateMenuBarTitle()
    }

    @objc func drankWater() {
        doAck()
    }

    @objc func snoozeFromMenu() {
        doSnooze()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Preferences

    var prefsWindow: NSWindow?

    @objc func openPreferences() {
        if let w = prefsWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 310),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        w.title = "Water Reminder Preferences"
        w.center()
        w.isReleasedWhenClosed = false

        let view = NSView(frame: w.contentView!.bounds)
        view.autoresizingMask = [.width, .height]

        var y: CGFloat = 260

        // Base interval
        let baseLabel = makeLabel("Reminder interval (minutes):", x: 20, y: y)
        view.addSubview(baseLabel)
        let baseField = NSTextField(frame: NSRect(x: 250, y: y, width: 80, height: 24))
        baseField.doubleValue = baseInterval / 60.0
        baseField.tag = 1
        view.addSubview(baseField)
        y -= 40

        // First snooze
        let snoozeLabel = makeLabel("First snooze (minutes):", x: 20, y: y)
        view.addSubview(snoozeLabel)
        let snoozeField = NSTextField(frame: NSRect(x: 250, y: y, width: 80, height: 24))
        snoozeField.doubleValue = firstSnoozeInterval / 60.0
        snoozeField.tag = 2
        view.addSubview(snoozeField)
        y -= 40

        // Min interval
        let minLabel = makeLabel("Minimum snooze floor (seconds):", x: 20, y: y)
        view.addSubview(minLabel)
        let minField = NSTextField(frame: NSRect(x: 250, y: y, width: 80, height: 24))
        minField.doubleValue = minInterval
        minField.tag = 3
        view.addSubview(minField)
        y -= 40

        // Sound toggle
        let soundCheck = NSButton(checkboxWithTitle: "Play sound on reminder", target: nil, action: nil)
        soundCheck.frame = NSRect(x: 20, y: y, width: 300, height: 24)
        soundCheck.state = soundEnabled ? .on : .off
        soundCheck.tag = 4
        view.addSubview(soundCheck)
        y -= 40

        // Launch at login
        let loginCheck = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
        loginCheck.frame = NSRect(x: 20, y: y, width: 300, height: 24)
        loginCheck.state = UserDefaults.standard.bool(forKey: kLaunchAtLogin) ? .on : .off
        loginCheck.tag = 5
        view.addSubview(loginCheck)
        y -= 50

        // Save button
        let saveBtn = NSButton(frame: NSRect(x: 140, y: y, width: 100, height: 32))
        saveBtn.title = "Save"
        saveBtn.bezelStyle = .rounded
        saveBtn.target = self
        saveBtn.action = #selector(savePreferences(_:))
        saveBtn.keyEquivalent = "\r"
        view.addSubview(saveBtn)

        w.contentView = view
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        prefsWindow = w
    }

    @objc func savePreferences(_ sender: NSButton) {
        guard let view = sender.superview else { return }

        for sub in view.subviews {
            if let field = sub as? NSTextField {
                switch field.tag {
                case 1: baseInterval = max(field.doubleValue * 60, 60)
                case 2: firstSnoozeInterval = max(field.doubleValue * 60, 10)
                case 3: minInterval = max(field.doubleValue, 5)
                default: break
                }
            }
            if let check = sub as? NSButton {
                switch check.tag {
                case 4: soundEnabled = (check.state == .on)
                case 5:
                    let enabled = (check.state == .on)
                    UserDefaults.standard.set(enabled, forKey: kLaunchAtLogin)
                    setLoginItem(enabled: enabled)
                default: break
                }
            }
        }

        // Reset timer with new base interval
        currentInterval = baseInterval
        lastDrinkTime = Date()
        isFirstSnooze = true
        updateMenuBarTitle()

        prefsWindow?.close()
    }

    func setLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                // Silently handle — user can manage in System Settings
            }
        }
    }

    func makeLabel(_ text: String, x: CGFloat, y: CGFloat) -> NSTextField {
        let label = NSTextField(frame: NSRect(x: x, y: y, width: 220, height: 24))
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.isSelectable = false
        return label
    }

    // MARK: - Helpers

    func formatNextSnooze() -> String {
        let secs: TimeInterval
        if isFirstSnooze {
            secs = firstSnoozeInterval
        } else {
            secs = max(currentInterval / 2, minInterval)
        }

        if secs >= 60 {
            let m = secs / 60.0
            if secs.truncatingRemainder(dividingBy: 60) == 0 {
                return "\(Int(m)) min"
            } else {
                return String(format: "%.1f min", m)
            }
        } else {
            return "\(Int(secs)) sec"
        }
    }
}

// MARK: - Helpers

extension Double {
    func clamped(min minVal: Double) -> Double {
        return self < minVal ? minVal : self
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // hides from Dock
app.run()
