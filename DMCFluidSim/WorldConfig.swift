//
//  WorldConfig.swift
//  WWWindTunnel
//
//  Created by Mitch Chapman on 11/18/21.
//

import Foundation
import AppKit

enum SimulationModel: String, CaseIterable, Identifiable {
    var id : String { self.rawValue }
    
    case particles = "Particles"
    case latticeBoltzmannD2Q9 = "Lattice-Boltzmann D2Q9"
}

final class WorldConfig: ObservableObject, Codable {
    @Published var foilConfig = FoilConfig()
    
    // The type of simulation to run.
    @Published var simulationModel = SimulationModel.particles
    
    // Whether to show simulation results when done.
    @Published var showWhenComplete = true
    
    // "Air" characteristics:
    // Celsius:
    @Published var temperature: Double = 20.0
    // meters/second
    @Published var windSpeed: Double = 40.0
    
    // When using a Lattice-Boltzmann model -- no idea of the units
    @Published var viscosity: Double = 0.004
    
    enum CodingKeys: String, CodingKey {
        case aoaDeg
        case xPercent
        case yPercent
        case widthPercent
        case simulationModel
        case temperature
        case windSpeed
        case viscosity
    }
    
    private var observers = [NSObjectProtocol]()
    
    init() {
    }

    init(from decoder: Decoder) {
        if let data = try? decoder.container(keyedBy: CodingKeys.self) {
            func double(_ key: CodingKeys) -> Double? {
                if let value = try? data.decode(Double.self, forKey: key) {
                    return value
                }
                return nil
            }
            foilConfig.aoaDeg = double(.aoaDeg) ?? 4.0
            foilConfig.xPercent = double(.xPercent) ?? 30.0
            foilConfig.yPercent = double(.yPercent) ?? 30.0
            foilConfig.widthPercent = double(.widthPercent) ?? 40.0
            
            if let v = try? data.decode(String.self, forKey: .simulationModel) {
                simulationModel = SimulationModel(rawValue: v) ?? .particles
            }
            
            temperature = double(.temperature) ?? 20.0
            windSpeed = double(.windSpeed) ?? 0.0
            viscosity = double(.viscosity) ?? 0.004
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // What verbosity...
        try container.encode(foilConfig.aoaDeg, forKey: .aoaDeg)
        try container.encode(foilConfig.xPercent, forKey: .xPercent)
        try container.encode(foilConfig.yPercent, forKey: .yPercent)
        try container.encode(foilConfig.widthPercent, forKey: .widthPercent)
        try container.encode(simulationModel.rawValue, forKey: .simulationModel)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(windSpeed, forKey: .windSpeed)
        try container.encode(viscosity, forKey: .viscosity)
    }


    public static func load() -> WorldConfig {
        if let data = UserDefaults().data(forKey: "worldConfigData") {
            let decoder = JSONDecoder()
            if let result = try? decoder.decode(WorldConfig.self, from: data) {
                return result
            }
        }
        return WorldConfig()
    }
    
    public func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self) {
            UserDefaults().set(data, forKey: "worldConfigData")
        }
    }

}
