//
//  ContentView.swift
//  WindTunnel
//
//  Created by Mitch Chapman on 11/19/21.
//

import SwiftUI

// https://developer.apple.com/forums/thread/126949
extension HorizontalAlignment {
    private enum ControlLeadingEdgeAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center] // default is center, but could be anything really.
        }
    }
    static let controlLeadingEdge = HorizontalAlignment(ControlLeadingEdgeAlignment.self)
}

struct ContentView<SCM: SimControlModelInterface>: View {
    @ObservedObject var cfg: WorldConfig
    @ObservedObject var foilConfig: FoilConfig
    @ObservedObject var model: SCM
    
    private func leDrag(_ geom: GeometryProxy) -> some Gesture {
        return DragGesture()
            .onChanged { value in
                let xNew = 100.0 * value.location.x / geom.size.width
                let yNew = 100.0 * value.location.y / geom.size.height
                foilConfig.moveLeadingEdge(xPercent: xNew, yPercent: yNew)
            }
    }
    
    private func teDrag(_ geom: GeometryProxy) -> some Gesture {
        return DragGesture()
            .onChanged { value in
                foilConfig.moveTrailingEdge(toX: value.location.x, y: value.location.y, in: geom.frame(in: .local))
            }
    }
    
    private var foilSpecOverlay: some View {
        Text(String(format: """
X: %.0f%%  Y: %.0f%%  Width: %.0f%%
⍺: %.0f°
""",
                    foilConfig.xPercent, foilConfig.yPercent, foilConfig.widthPercent,
                    foilConfig.aoaDeg))
            .foregroundColor(Color.gray)
    }

    private var foilView: some View {
        GeometryReader { geom in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.98, blue: 1.0))
                
                foilSpecOverlay
                    .offset(x: 8.0, y: 8.0)

                FoilShape()
                    .transform(foilConfig.getTransform(for: geom.frame(in: .local)))
                    .fill(Color.gray)

                LeadingEdgeHandle(config: foilConfig)
                    .gesture(leDrag(geom))
                TrailingEdgeHandle(config: foilConfig)
                    .gesture(teDrag(geom))
            }
        }
        .aspectRatio(1280.0/720.0, contentMode: .fit)
        .frame(minWidth: 320, maxWidth: 480, minHeight: 180)
        .padding(10)
        .background(Color.white)
    }
    
    private var simSelectionView: some View {
        HStack {
            Picker("Simulation:", selection: $cfg.simulationModel) {
                ForEach(SimulationModel.allCases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .frame(minWidth: 240, maxWidth: 320)
            Spacer()
        }
    }
    
    var airConfigView: some View {
        Group {
            Slider(
                value: $cfg.temperature,
                in: -100.0...100.0,
                step: 10.0,
                label: { Text("°C:") },
                minimumValueLabel: { Text("-100") },
                maximumValueLabel: { Text("100") }
            )
            Slider(
                value: $cfg.windSpeed,
                in: 0.0...90.0,
                step: 10.0,
                label: { Text("Wind (m/s):") },
                minimumValueLabel: { Text("0") },
                maximumValueLabel: { Text("90") }
            )
            
            if cfg.simulationModel != .particles {
                Slider(
                    value: $cfg.viscosity,
                    in: 0.002...0.04,
                    step: 0.002,
                    label: { Text("Viscosity:") },
                    minimumValueLabel: { Text("0.002") },
                    maximumValueLabel: { Text("0.04") }
                )
            } else {
                // Preserve layout
                Slider(
                    value: $cfg.viscosity,
                    in: 0.004...0.02,
                    label: { Text("Viscosity:") }
                ).hidden()
            }
        }
    }

    var body: some View {
        VStack {
            foilView
            Divider()
            Form {
                simSelectionView
                Divider()
                airConfigView
            }
            .disabled(model.isRunning)
            .frame(maxWidth: 480.0)
            .padding(10)
            Divider()
            SimControlView(cfg: cfg, model: model)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject static var config = WorldConfig()
    @StateObject static var model = SimControlModel_Preview()

    static var previews: some View {
        ContentView(cfg: config, foilConfig: config.foilConfig, model: model)
    }
}
