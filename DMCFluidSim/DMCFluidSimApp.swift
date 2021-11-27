//
//  WindTunnelApp.swift
//  WindTunnel
//
//  Created by Mitch Chapman on 11/19/21.
//

import SwiftUI
import AppKit

@main
struct DMCFluidSimApp: App {
    private let willTermPub = NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
    
    @StateObject var config = WorldConfig.load()
    @StateObject var model = SimControlModel()
    
    var body: some Scene {
        WindowGroup {
            // Pass foil config separately.  Else expect foil shape to fail to update.
            ContentView(cfg: config, foilConfig: config.foilConfig, model: model)
                .onReceive(willTermPub) {_ in
                    config.save()
                }
        }
    }
}
