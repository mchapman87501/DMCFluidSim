import SwiftUI

class SimControlModel: SimControlModelInterface {
    @Published var isRunning = false
    @Published var isComplete = false
    @Published var snapshot = defaultImage()
    @Published var fractionDone = 0.0
    
    private var simController: SimulationController? = nil

    private var cancelRequested = false
    private let movieSeconds = 45
    private let framesPerSecond = 30
    private var stepsPerFrame = 10
    
    // TODO let the UI specify this...
    private static let snapshotAspectRatio = 1280.0 / 720.0
    private static let snapshotHeight = 180.0
    private static let snapshotWidth = snapshotAspectRatio * snapshotHeight
    private static let snapshotSize = NSSize(width: snapshotWidth, height: snapshotHeight)
    
    private static func defaultImage() -> NSImage {
        return NSImage(size: snapshotSize, flipped: false) { rect in
            // TODO let the UI specify the default color.
            NSColor(calibratedRed: 0.95, green: 0.98, blue: 1.0, alpha: 1.0).setFill()
            NSBezierPath.fill(rect)
            return true
        }
    }
    
    func run(with config: WorldConfig) {
        isRunning = true
        isComplete = false
        fractionDone = 0.0
        cancelRequested = false
        
        updateProgress(seconds: 0, duration: movieSeconds)
        clearSnapshot()

        runAsync(config: config)
    }
    
    private func runAsync(config: WorldConfig) {
        DispatchQueue.global(qos: .utility).async {
            self.simController = self.makeSimController(config: config)
            let sps = self.simController!.idealStepsPerSecond()
            self.stepsPerFrame = max(1, Int(round(sps / Double(self.framesPerSecond))))
            
            self.simController!.prepare {
                self.updateSnapshot()
                return self.cancelRequested
            }
            self.recordMovie()

            do {
                try self.simController!.finish()
            } catch {
                NSLog("Error finishing simulation: \(error)")
            }
            // Whether cancelled or run to completion, we should have saved
            // a valid movie.
            if config.showWhenComplete {
                self.openMovie()
            }
            self.notifyComplete()
        }
    }
    
    private func clearSnapshot() {
        snapshot = Self.defaultImage()
    }
    
    private func makeSimController(config: WorldConfig) -> SimulationController {
        switch config.simulationModel {
        case .particles:
            return ParticleSimController(config: config)
        case .latticeBoltzmannD2Q9:
            return LBMSimController(config: config)
        }
    }
    
    private enum AlphaRamp {
        case rampUp
        case opaque
        case rampDown
    }
    
    private func recordMovie() {
        try? simController!.writeTitle()
        self.updateSnapshot()
        updateProgress(seconds:0, duration: movieSeconds)
        
        for sec in 1...movieSeconds {
            let alphaRamp: AlphaRamp = (sec == 1) ? .rampUp : ((sec == movieSeconds) ? .rampDown : .opaque)
            stepOneSecond(alphaRamp: alphaRamp)
            updateProgress(seconds: sec, duration: movieSeconds)
            if cancelRequested {
                return
            }
            
            updateSnapshot()
        }
    }
    
    private func stepOneSecond(alphaRamp: AlphaRamp) {
        var alpha = 1.0
        var dAlpha = 0.0
        switch alphaRamp {
        case .rampUp:
            alpha = 0.0
            dAlpha = 1.0 / Double(framesPerSecond)
        case .rampDown:
            alpha = 1.0
            dAlpha = -1.0 / Double(framesPerSecond)
        case .opaque:
            alpha = 1.0
            dAlpha = 0.0
        }
        
        for _ in 1...framesPerSecond {
            stepOneFrame()
            if cancelRequested {
                return
            }
            do {
                try simController!.saveFrame(alpha: alpha)
            } catch {
                NSLog("Error saving frame: \(error)")
                return 
            }
            alpha += dAlpha
        }
    }
    
    private func stepOneFrame() {
        for _ in 0..<stepsPerFrame {
            simController!.step()
            if cancelRequested {
                return
            }
        }
    }

    private func updateProgress(seconds: Int, duration: Int) {
        DispatchQueue.main.async {
            self.fractionDone = Double(seconds) / Double(duration)
        }
    }
    
    private func notifyComplete() {
        DispatchQueue.main.async {
            self.isRunning = false
            self.isComplete = true
        }
    }
    
    private func updateSnapshot() {
        DispatchQueue.main.async {
            let newImage = self.simController!.snapshotImage(size: Self.snapshotSize)
            self.snapshot = newImage
        }
    }
    
    func stop() {
        cancelRequested = true
    }
    
    func openMovie() {
        NSWorkspace.shared.open(simController!.movieURL())
    }
}
