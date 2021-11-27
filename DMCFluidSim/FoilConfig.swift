import SwiftUI

class FoilConfig: ObservableObject {
    @Published var aoaDeg: Double = 4.0
    @Published var xPercent: Double = 30.0
    @Published var yPercent: Double = 65.0
    @Published var widthPercent: Double = 40.0
    
    func getTransform(for rect: CGRect) -> CGAffineTransform {
        let xOffFract = xPercent / 100.0
        let yOffFract = yPercent / 100.0
        let widthFract = widthPercent / 100.0
        
        let xOffset = rect.width * xOffFract
        let yOffset = rect.height * yOffFract
        let widthScale = rect.width * widthFract
        let aoaRad = aoaDeg * .pi / 180.0
        
        return CGAffineTransform.identity
            .translatedBy(x: xOffset, y: yOffset)
            .scaledBy(x: widthScale, y: widthScale)
            .rotated(by: aoaRad)
    }
    
    func moveLeadingEdge(xPercent: Double, yPercent: Double) {
        self.xPercent = xPercent
        self.yPercent = yPercent
    }
    
    func moveTrailingEdge(toX: Double, y: Double, in rect: CGRect) {
        // Assume my shape has its leading edge at (xPercent, yPercent).
        // Assume my trailing edge is offset from leading edge by widthPercent,
        // rotated by aoaDeg.
        let currTransform = getTransform(for: rect)
        let currentLE = CGPoint(x: 0.0, y: 0.0).applying(currTransform)

        // getTransform considers only the rect.width when setting the widthScale.
        // Hence this nonsense for dyFract.
        let dxFract = (toX - currentLE.x) / rect.width
        let dyFract = (y - currentLE.y) / rect.width
        let newWidthPercent = 100.0 * sqrt(dxFract * dxFract + dyFract * dyFract)
        let newAoaDeg = atan2(dyFract, dxFract) * 180.0 / .pi
        self.widthPercent = newWidthPercent
        self.aoaDeg = newAoaDeg
    }
}
