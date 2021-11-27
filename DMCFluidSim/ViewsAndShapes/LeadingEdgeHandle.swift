import SwiftUI

struct LeadingEdgeHandle: Shape {
    @ObservedObject var config: FoilConfig
    
    private let radiusPercent = 1.0
    
    func path(in rect: CGRect) -> Path {
        let x = config.xPercent * rect.width / 100.0
        let y = config.yPercent * rect.height / 100.0
        let minExtent = min(rect.width, rect.height)
        let idealRadius = radiusPercent * minExtent / 100.0
        let radius = max(4.0, idealRadius)
        let diameter = 2.0 * radius
        let pathRect = CGRect(x: x - radius, y: y - radius, width: diameter, height: diameter)
        return Path(ellipseIn: pathRect)
    }
}
