import Foundation
import ScreenCaptureKit
import CoreGraphics
import VideoToolbox

class ScreenAnalyzer: NSObject, SCStreamOutput {
    static let shared = ScreenAnalyzer()
    
    private var stream: SCStream?
    private var lastLuminance: Double = 0.5
    private var currentLuminance: Double = 0.5
    
    // Configurable thresholds
    var sensitivity: Double = 0.3 // 0.1 to 1.0 (0.1 is most sensitive)
    var isEnabled: Bool = true {
        didSet {
            if isEnabled { startWatching() } else { stopWatching() }
        }
    }
    
    override init() {
        super.init()
    }
    
    func monitorScreen() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return }
            
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            
            // Optimize for performance: Low resolution and frame rate
            config.width = 320
            config.height = 180
            config.minimumFrameInterval = CMTime(value: 1, timescale: 15) // 15 fps
            config.pixelFormat = kCVPixelFormatType_32BGRA
            
            stream = SCStream(filter: filter, configuration: config, delegate: nil)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
            
            try await stream?.startCapture()
        } catch {
            print("Failed to start screen capture: \(error.localizedDescription)")
        }
    }
    
    func stopWatching() {
        stream?.stopCapture()
        stream = nil
    }
    
    func startWatching() {
        Task {
            await monitorScreen()
        }
    }
    
    // SCStreamOutput callback
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Calculate average luminance
        let avgLuminance = calculateAverageLuminance(from: pixelBuffer)
        
        // Process results on main thread
        DispatchQueue.main.async {
            self.processLuminance(avgLuminance)
        }
    }
    
    private func calculateAverageLuminance(from pixelBuffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 0.5 }
        
        var totalLuma: Double = 0
        let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Sampling for speed (every 10th pixel)
        let step = 10
        var count: Double = 0
        
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * 4
                // BGRA format
                let b = Double(ptr[offset])
                let g = Double(ptr[offset + 1])
                let r = Double(ptr[offset + 2])
                
                // Rec. 601 Luma formula: Y = 0.299R + 0.587G + 0.114B
                let luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                totalLuma += luma
                count += 1
            }
        }
        
        return totalLuma / count
    }
    
    private func processLuminance(_ luma: Double) {
        let delta = luma - lastLuminance
        
        // Flash detection: Sharp increase in brightness
        if delta > (0.4 * sensitivity) {
            // Flash detected!
            OverlayManager.shared.triggerFlashSmoothing(opacity: 0.6, duration: 0.3)
        }
        
        // Adaptive Dark Mode: Base dimming for very bright screens
        // If luma > 0.7, start dimming (max dimming at 1.0)
        let adaptiveDimming = max(0, (luma - 0.7) * 0.5)
        OverlayManager.shared.updateBaseDimming(to: adaptiveDimming)
        
        lastLuminance = luma
    }
}
