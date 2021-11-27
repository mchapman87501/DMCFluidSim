import SwiftUI


protocol SimControlModelInterface: ObservableObject {
    var isRunning: Bool {get}
    var isComplete: Bool {get}
    
    var snapshot: NSImage {get}
    var fractionDone: Double {get}
    
    func run(with config: WorldConfig)
    func stop()
    func openMovie()
}
