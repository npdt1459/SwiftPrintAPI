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
    
    @Field(key: "Material")
    var material: String
    
    @Field(key: "weight")
    var weight: Double
    
    @OptionalParent(key: "user_id")
    var user: User?
    
    init() {}
    
    init(id: UUID? = nil, title: String, material: String, color: String, weight: Double, user: User? = nil) {
        self.id = id
        self.title = title
        self.color = color
        self.material = material
        self.weight = weight
        self.user = user
    }
    
    func toDTO() -> FilamentDTO {
        FilamentDTO(id: self.id, title: self.title, color: self.color, material: self.material, weight: self.weight, userID: self.$user.id)
    }
}
