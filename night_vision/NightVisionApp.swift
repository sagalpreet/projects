import SwiftUI
import AppKit
import ScreenCaptureKit

@main
struct NightVisionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var screenMonitor = ScreenAnalyzer.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        OverlayManager.shared.setupPanels()
        screenMonitor.startWatching()
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye.slash.fill", accessibilityDescription: "Night Vision")
        }
        
        constructMenu()
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Night Vision: Active", action: #selector(toggleActive(_:)), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        
        // Sensitivity Submenu
        let sensitivityMenu = NSMenu()
        sensitivityMenu.addItem(NSMenuItem(title: "Low (Less aggressive)", action: #selector(setSensitivityLow), keyEquivalent: ""))
        sensitivityMenu.addItem(NSMenuItem(title: "Medium", action: #selector(setSensitivityMedium), keyEquivalent: ""))
        sensitivityMenu.addItem(NSMenuItem(title: "High (More aggressive)", action: #selector(setSensitivityHigh), keyEquivalent: ""))
        
        let sensitivityItem = NSMenuItem(title: "Flash Sensitivity", action: nil, keyEquivalent: "")
        sensitivityItem.submenu = sensitivityMenu
        menu.addItem(sensitivityItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Check Permissions...", action: #selector(checkPermissions), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleActive(_ sender: NSMenuItem) {
        screenMonitor.isEnabled.toggle()
        sender.title = screenMonitor.isEnabled ? "Night Vision: Active" : "Night Vision: Paused"
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: screenMonitor.isEnabled ? "eye.slash.fill" : "eye.fill", accessibilityDescription: "Night Vision")
        }
    }
    
    @objc func setSensitivityLow() { screenMonitor.sensitivity = 0.5 }
    @objc func setSensitivityMedium() { screenMonitor.sensitivity = 0.3 }
    @objc func setSensitivityHigh() { screenMonitor.sensitivity = 0.1 }
    
    @objc func checkPermissions() {
        // Trigger ScreenCaptureKit permission prompt if not already granted
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Screen Recording Permission Required"
                alert.informativeText = "Please allow 'Night Vision' to record your screen in System Settings > Privacy & Security > Screen Recording to detect flashes."
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Cancel")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
