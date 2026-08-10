//
//  FilamentController.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/10/26.
//

import Vapor
import Fluent
import JWT

struct FilamentController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let printers = routes.grouped("filaments") // groups into /filaments/...
        let protected = printers.grouped(UserPayload.authenticator())
    }
}
