//
//  PrinterController.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/3/26.
//

import Vapor
import Fluent
import JWT

struct PrinterController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let printers = routes.grouped("printers") // groups into /printers/...
        let protected = printers.grouped(UserPayload.authenticator())
        protected.post("register", use: register) // /printers/register
        protected.get(use: list)
        protected.get(":id", use: getOne)
        protected.patch(":id", use: patch)
        protected.delete(":id", use: delete)
    }

    func register(req: Request) async throws -> PrinterDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(PrinterCreateDTO.self)
        
        let userID = UUID(payload.subject.value)
        guard let user = try await User.find(userID, on: req.db)
        else{
            throw Abort(.unauthorized)
        }
        
        let printer = Printer(
            title: dto.title,
            areaString: dto.areaString,
            user: user
        )
        
        try await printer.save(on: req.db) // For Fluent to add ID
        return printer.toDTO() // Now we have enough info for output DTO
    }
    
    func list(req: Request) async throws -> [PrinterDTO] {
        let payload = try req.auth.require(UserPayload.self)
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.notFound)
        }
        
        let printers = try await Printer.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
        
        var printerDTOs: [PrinterDTO] = []
        for printer in printers {
            printerDTOs.append(printer.toDTO())
        }
        return printerDTOs
    }
    
    func getOne(req: Request) async throws -> PrinterDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let printerID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.notFound)
        }
        
        guard let printer = try await Printer.query(on: req.db)
            .filter(\.$id == printerID)
            .filter(\.$user.$id == userID)
            .first()
        else{
            throw Abort(.notFound)
        }

        return printer.toDTO()
    }
    
    func patch(req: Request) async throws -> PrinterDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(PrinterPatchDTO.self)
        
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.notFound)
        }
        
        guard let printerID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.notFound)
        }
        
        guard let printer = try await Printer.query(on: req.db)
            .filter(\.$id == printerID)
            .filter(\.$user.$id == userID)
            .first()
        else{
            throw Abort(.notFound)
        }
        
        if let newTitle = dto.title {
            printer.title = newTitle
        }
        if let newArea = dto.areaString {
            printer.areaString = newArea
        }
        try await printer.save(on: req.db)
        
        return printer.toDTO()
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)

        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        guard let printerID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.badRequest)
        }
        
        guard let printer = try await Printer.query(on: req.db)
            .filter(\.$id == printerID)
            .filter(\.$user.$id == userID)
            .first()
        else{
            throw Abort(.notFound)
        }
        
        try await printer.delete(on: req.db)
        
        return .noContent
    }
}
