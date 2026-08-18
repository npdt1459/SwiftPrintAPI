//
//  UserPatchDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/11/26.
//

import Fluent
import Vapor

struct UserPatchDTO: Content {
    var email: String?
    var password: String?
}
