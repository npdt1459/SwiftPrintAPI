//
//  PrintJobController.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/19/26.
//

import Vapor
import Fluent
import JWT

struct PrintJobController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let printjobs = routes.grouped("printJobs") // groups into /users/...
        let protected = printjobs.grouped(UserPayload.authenticator())
        protected.post("register", use: register) // /users/register
        protected.get(use: list)
        protected.get(":id", use: getOne)
        protected.patch(":id", use: patch)
        protected.delete(":id", use: delete)
    }

    func register(req: Request) async throws -> PrintJobDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(PrintJobCreateDTO.self)
        
        let userID = UUID(payload.subject.value)
        guard let user = try await User.find(userID, on: req.db)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let filament = try await Filament.query(on: req.db)
            .filter(\.$id == dto.filamentID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound)
        }

        guard let printer = try await Printer.query(on: req.db)
            .filter(\.$id == dto.printerID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound)
        }
        
        filament.weightGrams -= dto.weightGrams
        try await filament.save(on: req.db)

        printer.totalPrintMinutes += dto.duration
        try await printer.save(on: req.db)

        let cost = (dto.weightGrams / 1000) * filament.costPerKg
        
        let printjob = PrintJob(
            duration: dto.duration,
            weightGrams: dto.weightGrams,
            success: dto.success,
            cost: cost,
            user: user,
            printer: printer,
            filament: filament
        )
        
        try await printjob.save(on: req.db) // For Fluent to add ID & createdAt
        return printjob.toDTO() // Now we have enough info for output DTO
    }
    
    func list(req: Request) async throws -> [PrintJobDTO] {
        let payload = try req.auth.require(UserPayload.self)
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        let printjobs = try await PrintJob.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
        
        var PrintJobDTOs: [PrintJobDTO] = []
        for printjob in printjobs {
            PrintJobDTOs.append(printjob.toDTO())
        }
        return PrintJobDTOs
    }
    
    func getOne(req: Request) async throws -> PrintJobDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let printjobID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.badRequest)
        }
        
        guard let printjob = try await PrintJob.query(on: req.db)
            .filter(\.$id == printjobID)
            .filter(\.$user.$id == userID)
            .first()
        else{
            throw Abort(.notFound)
        }
        return printjob.toDTO()
    }
    
    func patch(req: Request) async throws -> PrintJobDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(PrintJobPatchDTO.self)
        
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let printjobID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.badRequest)
        }
        
        guard let printjob = try await PrintJob.query(on: req.db)
            .filter(\.$id == printjobID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            throw Abort(.notFound)
        }
        
        if let newWeightGrams = dto.weightGrams {
            let weightDelta = newWeightGrams - printjob.weightGrams
            
            guard let filament = try await Filament.find(printjob.$filament.id, on: req.db) else {
                throw Abort(.notFound)
            }
            filament.weightGrams -= weightDelta
            try await filament.save(on: req.db)
            
            printjob.weightGrams = newWeightGrams
            printjob.cost = (newWeightGrams / 1000) * filament.costPerKg
        }

        if let newDuration = dto.duration {
            let durationDelta = newDuration - printjob.duration
            
            guard let printer = try await Printer.find(printjob.$printer.id, on: req.db)
            else {
                throw Abort(.notFound)
            }
            printer.totalPrintMinutes += durationDelta
            try await printer.save(on: req.db)
            
            printjob.duration = newDuration
        }
        
        if let newSuccess = dto.success {
            printjob.success = newSuccess
        }
        
        try await printjob.save(on: req.db)
        return printjob.toDTO()
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let printjobID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.badRequest)
        }
        
        guard let printjob = try await PrintJob.query(on: req.db)
            .filter(\.$id == printjobID)
            .filter(\.$user.$id == userID)
            .with(\.$printer)
            .with(\.$filament)
            .first()
        else {
            throw Abort(.notFound)
        }

        printjob.printer.totalPrintMinutes -= printjob.duration
        try await printjob.printer.save(on: req.db)

        printjob.filament.weightGrams += printjob.weightGrams
        try await printjob.filament.save(on: req.db)
        
        try await printjob.delete(on: req.db)
        return .noContent
    }
    
}

