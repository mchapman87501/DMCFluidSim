import AppKit
import DMCWingWorks
import DMCWingWorksRender

final class ParticleSimController: SimulationController {
    private let movieWidth = 1280
    private let movieHeight = 720
    private let world: World
    private let worldWriter: WorldWriter
    private let _movieURL: URL
    private let title: String

    init(config: WorldConfig) {
        let worldWidth = Double(movieWidth) / 15.0
        let worldHeight = Double(movieHeight) / 15.0
        
        let foilConfig = config.foilConfig
        let xFoil = worldWidth * foilConfig.xPercent / 100.0
        let yFoil = worldHeight * (100.0 - foilConfig.yPercent) / 100.0
        let widthFoil = worldWidth * foilConfig.widthPercent / 100.0
        let aoaRad = foilConfig.aoaDeg * .pi / 180.0
        let airfoil = AirFoil(x: xFoil, y: yFoil, width: widthFoil, alphaRad: aoaRad)

        
        // Approximate ratio of random speed vs. wind speed, to mimic sea-level atmosphere at 20C
        // vs. an aircraft takeoff-ish speed near 36 m/s: 400:36
        let K = 1.0 / 8000.0
        let maxParticleSpeed = sqrt(config.temperature / K)
        let windSpeed = config.windSpeed
        let dsdtMax = 1.2
        let maxSpecifiedSpeed = max(maxParticleSpeed, windSpeed)
        let speedScale = dsdtMax / maxSpecifiedSpeed
        let scaledMaxPartSpeed = speedScale * maxParticleSpeed
        let scaledWindSpeed = speedScale * windSpeed

        let world = World(
            airfoil: airfoil, width: worldWidth, height: worldHeight, maxParticleSpeed: scaledMaxPartSpeed, windSpeed: scaledWindSpeed)

        let title = String(format: """
Temperature: %.0f°C
Wind speed: %.0f m/s
⍺: %.0f°
""", config.temperature, config.windSpeed, foilConfig.aoaDeg)

        let movieURL = Self.formatMovieURL(for: config)
        let worldWriter = try? WorldWriter(world: world, writingTo: movieURL, width: movieWidth, height: movieHeight, title: title)
        // Offer a diagnostic before crashing :)
        if worldWriter == nil {
            NSLog("Could not create world writer.")
        }

        self.world = world
        self.worldWriter = worldWriter!
        self._movieURL = movieURL
        self.title = title
    }
    
    private static func formatMovieURL(for config: WorldConfig) -> URL {
        let foilInfo = config.foilConfig
        let foilSpec = String(
            format: "%.0f_%.0f_%.0f_%.0f",
            foilInfo.xPercent, foilInfo.yPercent, foilInfo.widthPercent, foilInfo.aoaDeg
        )
        let airSpec = String(
            format: "%.0f_%.0f",
            config.temperature, config.windSpeed
        )
        let dirURL = try! FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let pathStr = "particles_\(foilSpec)_\(airSpec).mov"
        let result = dirURL.appendingPathComponent(pathStr)
        return result
    }

    func prepare(_ cancelRequested: Predicate) {
    }

    func writeTitle() throws {
//        worldWriter.showTitle(title)
    }

    func step() {
        world.step()
    }
    
    func saveFrame(alpha: Double) throws {
        try worldWriter.writeNextFrame(alpha: alpha)
    }
    
    func finish() throws {
        try worldWriter.finish()
    }
    
    func movieURL() -> URL {
        return _movieURL
    }

    func idealStepsPerSecond() -> Double {
        return 30 // ideal frames/second * 1 steps/frame
    }

    func snapshotImage(size: NSSize) -> NSImage {
        return worldWriter.getNextFrame(width: size.width)
    }
}
