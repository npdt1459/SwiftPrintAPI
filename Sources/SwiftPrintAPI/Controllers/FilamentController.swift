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
        let filaments = routes.grouped("filaments") // groups into /filaments/...
        let protected = filaments.grouped(UserPayload.authenticator())
        protected.post("register", use: register)
        protected.get(use: list)
        protected.get(":id", use: getOne)
        protected.patch(":id", use: patch)
        protected.delete(":id", use: delete)
    }
    
    func register(req: Request) async throws -> FilamentDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(FilamentCreateDTO.self)
        
        let userID = UUID(payload.subject.value)
        guard let user = try await User.find(userID, on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        let filament = Filament(
            title: dto.title,
            color: dto.color,
            material: dto.material,
            weightGrams: dto.weightGrams,
            costPerKg: dto.costPerKg,
            user: user
        )
        
        try await filament.save(on: req.db)
        return filament.toDTO()
    }
    
    func list(req: Request) async throws -> [FilamentDTO] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        let filaments = try await Filament.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
        
        var printerDTOs: [FilamentDTO] = []
        for filament in filaments {
            printerDTOs.append(filament.toDTO())
        }
        return printerDTOs
    }
    
    func getOne(req: Request) async throws -> FilamentDTO {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let filamentID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.badRequest)
        }
        guard let filament = try await Filament.query(on: req.db)
            .filter(\.$id == filamentID)
            .filter(\.$user.$id == userID)
            .first()
        else{
            throw Abort(.notFound)
        }
        
        return filament.toDTO()
    }
    
    func patch(req: Request) async throws -> FilamentDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(FilamentPatchDTO.self)
        
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let filamentID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.badRequest)
        }
        
        guard let filament = try await Filament.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$id == filamentID)
            .first()
        else{
            throw Abort(.notFound)
        }
        
        if let newTitle = dto.title {
            filament.title = newTitle
        }
        if let newColor = dto.color {
            filament.color = newColor
        }
        if let newMaterial = dto.material {
            filament.material = newMaterial
        }
        if let newWeight = dto.weightGrams {
            filament.weightGrams = newWeight
        }
        if let newCost = dto.costPerKg {
            filament.costPerKg = newCost
        }
        
        try await filament.save(on: req.db)
        return filament.toDTO()
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)

        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        guard let filamentID = req.parameters.get("id", as: UUID.self)
        else{
            throw Abort(.badRequest)
        }
        
        guard let filament = try await Filament.query(on: req.db)
            .filter(\.$id == filamentID)
            .filter(\.$user.$id == userID)
            .first()
        else{
            throw Abort(.notFound)
        }
        
        try await filament.delete(on: req.db)
        
        return .noContent
    }
}
