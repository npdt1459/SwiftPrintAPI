//
//  PrinterController.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/3/26.
//

import Vapor
import Fluent

struct PrinterController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let printers = routes.grouped("printers") // groups into /printers/...
        printers.post("register", use: register) // /users/register
    }

    func register(req: Request) async throws -> PrinterDTO {
        let dto = try req.content.decode(PrinterCreateDTO.self)
        
        let printer = Printer(
            title: dto.title,
            areaString: dto.areaString
        )
        try await printer.save(on: req.db) // For Fluent to add ID
        return printer.toDTO() // Now we have enough info for output DTO
    }
}
