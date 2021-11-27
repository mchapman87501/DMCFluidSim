import AppKit

protocol SimulationController {
    init(config: WorldConfig)
    
    /// Perform any steps needed before beginning to step through the simulation.
    /// Periodically check for cancellation.
    typealias Predicate = () -> Bool
    func prepare(_ cancelRequested: Predicate)


    func writeTitle() throws
    func step()
    func saveFrame(alpha: Double) throws
    func finish() throws
    
    func movieURL() -> URL
    func idealStepsPerSecond() -> Double
    func snapshotImage(size: NSSize) -> NSImage

}
