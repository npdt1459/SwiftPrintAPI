import Fluent
import Foundation
//
//  User.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 7/31/26.
//

final class User: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "passwordHash")
    var passwordHash: String
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Children(for: \.$user)
    var printers: [Printer]
    
    @Children(for: \.$user)
    var filaments: [Filament]

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
    
    func toDTO() -> UserDTO {
        UserDTO(id: self.id, name: self.name, email: self.email, createdAt: self.createdAt)
    }
}
