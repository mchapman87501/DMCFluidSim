import SwiftUI

struct TrailingEdgeHandle: Shape {
    @ObservedObject var config: FoilConfig
    
    private let radiusPercent = 1.0
    
    func path(in rect: CGRect) -> Path {
        let transform = config.getTransform(for: rect)
        // Trailing edge handle, in normed coords, lands at (1.0, 0.0) on a unit airfoil.
        let origin = CGPoint(x: 1.0, y: 0.0).applying(transform)
        
        let minExtent = min(rect.width, rect.height)
        let idealRadius = radiusPercent * minExtent / 100.0
        let radius = max(4.0, idealRadius)
        let diameter = 2.0 * radius
        let pathRect = CGRect(x: origin.x - radius, y: origin.y - radius, width: diameter, height: diameter)
        return Path(ellipseIn: pathRect)
    }
}
