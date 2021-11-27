//
//  SimControlView.swift
//  WindTunnel
//
//  Created by Mitch Chapman on 11/20/21.
//

import SwiftUI

struct SimControlView<SCM: SimControlModelInterface>: View {
    @ObservedObject var cfg: WorldConfig = WorldConfig()
    @ObservedObject var model: SCM

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    cfg.save()
                    model.run(with: cfg)
                }) {
                    Label("Run", systemImage: "play.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 16.0))
                }
                .disabled(model.isRunning)
                
                Button(action: model.stop) {
                    Label("Stop", systemImage: "stop.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 16.0))
                }
                .disabled(!model.isRunning)
                
                Spacer()

                // Instead of "Open Movie..."
                // how about a check button that says "Open when done" or
                // some such?
                Toggle("Open when done", isOn: $cfg.showWhenComplete)
                    .help("Automatically open the movie when the simulation completes")
                    .disabled(model.isRunning)
                Button(action: model.openMovie) {
                    Text("Open Movie...")
                }
                .disabled(!model.isComplete)
            }
            Image(nsImage: model.snapshot)
                .padding([.top, .bottom], 4)
            HStack {
                Spacer()
                    .frame(minWidth: 10.0)
                // TODO align leading edge with Run/Pause leading
                // edge, instead of faking it with spacers
                ProgressView(value: model.fractionDone)
                    .padding([.bottom], 10)
                Spacer()
                    .frame(minWidth: 10.0)
            }
        }
        .padding(10)
    }
}

class SimControlModel_Preview: SimControlModelInterface {
    @Published var isRunning: Bool = false
    @Published var isComplete: Bool = false
    @Published var snapshot = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!
    @Published var fractionDone: Double = 0.0
    @Published var movieURL: URL = URL(fileURLWithPath: "movie.mov")
    
    func run(with config: WorldConfig) {
        let dFract = 0.2
        if !isRunning {
            if fractionDone < (1.0 - dFract) {
                isRunning = true
                isComplete = false
                fractionDone += dFract
            } else {
                fractionDone = 1.0
                isComplete = true
            }
        } else {
            isRunning = false
        }
    }
    
    func stop() {
        isRunning = false
        // Mimic behavior: stop at any time, saving everything
        // recorded so far.
        isComplete = (fractionDone > 0.0)
        fractionDone = 0.0
    }
    
    func openMovie() {
        print("Pretend to open \(movieURL)")
    }
}

struct SimControlView_Previews: PreviewProvider {
    @StateObject static var config = WorldConfig()
    @StateObject static var model = SimControlModel_Preview()
    static var previews: some View {
        SimControlView(cfg: config, model: model)
    }
}
