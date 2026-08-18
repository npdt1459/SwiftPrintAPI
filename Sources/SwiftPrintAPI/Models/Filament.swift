//
//  Filament.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/10/26.
//

import Fluent
import struct Foundation.UUID

final class Filament: Model, @unchecked Sendable {
    static let schema = "filaments"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "color")
    var color: String
    
    @Field(key: "material")
    var material: String
    
    @Field(key: "weightGrams")
    var weightGrams: Double
    
    @Field(key: "costPerKg")
    var costPerKg: Double
    
    @OptionalParent(key: "user_id")
    var user: User?
    
    init() {}
    
    init(id: UUID? = nil, title: String, color: String, material: String, weightGrams: Double, costPerKg: Double, user: User? = nil) {
        self.id = id
        self.title = title
        self.color = color
        self.material = material
        self.weightGrams = weightGrams
        self.costPerKg = costPerKg
        self.$user.id = user?.id
    }
    
    func toDTO() -> FilamentDTO {
        FilamentDTO(id: self.id, title: self.title, color: self.color, material: self.material, weightGrams: self.weightGrams, costPerKg: self.costPerKg, userID: self.$user.id)
    }
}
