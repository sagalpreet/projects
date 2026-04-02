import Cocoa
import SwiftUI

class DimmingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    init(contentRect: NSRect, screen: NSScreen) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.level = .screenSaver
        self.backgroundColor = .black
        self.isOpaque = false
        self.alphaValue = 0.0
        self.ignoresMouseEvents = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    }
}

class OverlayManager: NSObject {
    static let shared = OverlayManager()
    
    private var overlayPanels: [NSPanel] = []
    private var baseOpacity: CGFloat = 0.0
    private var flashOpacity: CGFloat = 0.0
    
    override init() {
        super.init()
        setupPanels()
    }
    
    func setupPanels() {
        // Clear existing panels if any
        overlayPanels.forEach { $0.close() }
        overlayPanels.removeAll()
        
        for screen in NSScreen.screens {
            let panel = DimmingPanel(contentRect: screen.frame, screen: screen)
            panel.orderFrontRegardless()
            overlayPanels.append(panel)
        }
    }
    
    /// Updates the constant dimming (Adaptive Dark Mode)
    func updateBaseDimming(to value: CGFloat) {
        self.baseOpacity = value
        updateOpacity()
    }
    
    /// Updates temporary dimming (Flash smoothing)
    func triggerFlashSmoothing(opacity: CGFloat, duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.05 // Rapid onset
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.flashOpacity = opacity
            self.updateOpacity()
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration // Slower decay
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.flashOpacity = 0.0
                self.updateOpacity()
            }
        }
    }
    
    private func updateOpacity() {
        // Total opacity is the sum (or max) of both effects
        let totalOpacity = min(0.9, max(baseOpacity, flashOpacity))
        for panel in overlayPanels {
            panel.alphaValue = totalOpacity
        }
    }
}
