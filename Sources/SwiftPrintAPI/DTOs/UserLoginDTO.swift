//
//  UserLoginDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/4/26.
//

import Fluent
import Vapor

struct UserLoginDTO: Content {
    var email: String
    var password: String
}
