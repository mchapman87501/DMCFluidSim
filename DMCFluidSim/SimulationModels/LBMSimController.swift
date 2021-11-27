import AppKit
import DMCLatticeBoltzmann
import DMCLatticeBoltzmannRender
import DMCMovieWriter

final class LBMSimController: SimulationController {
    private let latticeWidth = 1280
    private let latticeHeight = 720
    private let lattice: Lattice
    private let movieWriter: DMCMovieWriter
    private let worldWriter: WorldWriter
    private let _movieURL: URL
    
    private let title: String
    
    private var settlePctRemaining = 0

    init(config: WorldConfig) {
        let omega = 1.0 / (3.0 * config.viscosity + 0.5)
        lattice = Lattice(
            width: latticeWidth, height: latticeHeight, omega: omega,
            temperature: config.temperature, windSpeed: config.windSpeed)!

        let foilConfig = config.foilConfig
        let x = foilConfig.xPercent * Double(latticeWidth) / 100.0
        let y = (100.0 - foilConfig.yPercent) * Double(latticeHeight) / 100.0
        let width = foilConfig.widthPercent * Double(latticeWidth) / 100.0
        let alphaRad = foilConfig.aoaDeg * .pi / 180.0
        let foil = AirFoil(x: x, y: y, width: width, alphaRad: alphaRad)

        lattice.addObstacle(shape: foil.shape)

        try! lattice.setBoundaryEdge(y: 0)
        try! lattice.setBoundaryEdge(y: latticeHeight - 1)
        try! lattice.setBoundaryEdge(x: 0)
        try! lattice.setBoundaryEdge(x: latticeWidth - 1)

        let title = String(format: """
Temperature: %.0f°C
Wind speed: %.0f m/s
⍺: %.0f°
Viscosity: %.4f St
""", config.temperature, config.windSpeed, foilConfig.aoaDeg, config.viscosity)
        let movieURL = Self.formatMovieURL(for: config)
        let movieWriter = try! DMCMovieWriter(
            outpath: movieURL, width: latticeWidth, height: latticeHeight)
        let worldWriter = try! WorldWriter(lattice: lattice, foil: foil, writingTo: movieWriter, title: title)

        self._movieURL = movieURL
        self.movieWriter = movieWriter
        self.worldWriter = worldWriter
        self.title = title
    }
    
    private static func formatMovieURL(for config: WorldConfig) -> URL {
        let foilInfo = config.foilConfig
        let foilSpec = String(
            format: "%.0f_%.0f_%.0f_%.0f",
            foilInfo.xPercent, foilInfo.yPercent, foilInfo.widthPercent, foilInfo.aoaDeg
        )
        let airSpec = String(
            format: "%.0f_%.0f_%.4f",
            config.temperature, config.windSpeed, config.viscosity
        )
        let dirURL = try! FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let pathStr = "lbm_\(foilSpec)_\(airSpec).mov"
        let result = dirURL.appendingPathComponent(pathStr)
        return result
    }

    func prepare(_ cancelRequested: Predicate) {
        // TODO render a title, perhaps.
        // Run lattice "settle" process.
        let settleCount = 15 * 30 * 10 // Roughly 15 seconds, assuming a frame rate and # steps per frame.
        settlePctRemaining = 100
        for i in 0..<settleCount {
            // Hm... should this not be a protected, atomic operation?
            settlePctRemaining = 100 * (settleCount - i) / settleCount
            lattice.step(disableTracers: true)
            if cancelRequested() {
                return
            }
        }
        // TODO Title fade in/out
    }

    func writeTitle() {
//        worldWriter.showTitle(title)
    }

    func step() {
        lattice.step()
    }
    
    func saveFrame(alpha: Double) throws {
        try worldWriter.writeNextFrame(alpha: alpha)
    }

    func finish() throws {
        try movieWriter.finish()
    }
    
    func movieURL() -> URL {
        return _movieURL
    }

    func idealStepsPerSecond() -> Double {
        return 30 * 10 // ideal frames/second * steps/frame
    }

    func snapshotImage(size: NSSize) -> NSImage {
        // Again, settleCountRemaining access should be atomic.
        if settlePctRemaining > 0 {
            return settlingImage(size: size)
        }

        return worldWriter.getCurrFrame(width: size.width)
    }
    
    private func settlingImage(size: NSSize) -> NSImage {
        let title = "Warming up... \(settlePctRemaining)"
        return NSImage(size: size, flipped: false) { rect in
            NSColor.white.setFill()
            NSBezierPath.fill(rect)

            // Solution from https://izziswift.com/how-to-use-nsstring-drawinrect-to-center-text/ inter alia
            let lineCharWidth = title.count

            let fontSize = (0.8 * rect.width) / Double(lineCharWidth)
            // https://stackoverflow.com/a/21940339/2826337
            let font = NSFont.systemFont(ofSize: fontSize)
            let attrs = [
                NSAttributedString.Key.font: font,
            ]
            let size = (title as NSString).size(withAttributes: attrs)
            let xPos = max(0.0, (rect.width - size.width) / 2.0)
            let yPos = max(0.0, (rect.height - size.height) / 2.0)

            (title as NSString).draw(
                at: NSPoint(x: rect.origin.x + xPos, y: rect.origin.y + yPos),
                withAttributes: attrs)
            return true
        }
    }
}
