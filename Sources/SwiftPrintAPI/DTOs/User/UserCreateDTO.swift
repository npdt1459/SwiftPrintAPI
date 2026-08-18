//
//  UserCreateDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/2/26.
//

import Fluent
import Vapor

struct UserCreateDTO: Content {
    var name: String
    var email: String
    var password: String
}
