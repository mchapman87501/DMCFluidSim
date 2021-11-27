import SwiftUI


private func normedFoilCoords() -> [(Double, Double)] {
    let vertexCoords: [(Double, Double)] = [
        (0.0000, 0.0000),
        (0.0092, 0.0188),
        (0.0403, 0.0373),
        (0.0920, 0.0543),
        (0.1622, 0.0679),
        (0.2478, 0.0766),
        (0.3447, 0.0792),
        (0.4480, 0.0758),
        (0.5531, 0.0681),
        (0.6557, 0.0573),
        (0.7512, 0.0448),
        (0.8356, 0.0318),
        (0.9053, 0.0198),

        (1.0001, 0.0013),

        (0.9037, -0.0080),
        (0.8335, -0.0128),
        (0.7488, -0.0184),
        (0.6534, -0.0245),
        (0.5514, -0.0306),
        (0.4474, -0.0360),
        (0.3463, -0.0399),
        (0.2522, -0.0422),
        (0.1686, -0.0417),
        (0.0990, -0.0375),
        (0.0462, -0.0292),
        (0.0126, -0.0166),
    ]
    let xvals = vertexCoords.map { (x, y) in x }
    let xmin = xvals.min()!
    let xmax = xvals.max()!
    let dx = xmax - xmin

    let yvals = vertexCoords.map { (x, y) in y }
    let y0 = yvals[0]
    
    // Transform to fit width in 0.0 ... 1.0, inverting y.
    let result: [(Double, Double)] = vertexCoords.map { (x, y) in
        let xOut = (x - xmin) / dx
        let yOut = (y0 - y) / dx // Same scale
        return (xOut, yOut)
    }
    return result
}

struct FoilShape: Shape {
    private static let normedCoords: [(Double, Double)] = normedFoilCoords()

    func path(in rect: CGRect) -> Path {
        let normedCoords = Self.normedCoords

        let vertexPoints = normedCoords.map { (x, y) in
            CGPoint(x: x, y: y)
        }

        var result = Path()
        result.addLines(vertexPoints)
        result.closeSubpath()
        return result
    }
}
