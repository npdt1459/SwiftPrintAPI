//
//  UserDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/1/26.
//

import Fluent
import Vapor

struct UserDTO: Content {
    var id: UUID?
    var name: String
    var email: String
    var passwordHash: String
    
    func toModel() -> User {
        let model = User()
        
        model.id = self.id
        model.name = self.name
        model.email = self.email
        model.passwordHash = self.passwordHash
        return model
    }
}
