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
    var createdAt: Date?
}
