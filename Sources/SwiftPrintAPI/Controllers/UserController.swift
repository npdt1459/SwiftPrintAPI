//
//  UserController.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/3/26.
//

import Vapor
import Fluent
import JWT

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users") // groups into /users/...
        let protected = users.grouped(UserPayload.authenticator())
        users.post("register", use: register) // /users/register
        users.post("login", use: login) // /users/login
        protected.patch(use: patch)
    }

    func register(req: Request) async throws -> UserDTO {
        let dto = try req.content.decode(UserCreateDTO.self)
        
        let passwordHash = try Bcrypt.hash(dto.password)
        
        let user = User(
            name: dto.name,
            email: dto.email,
            passwordHash: passwordHash
        )
        try await user.save(on: req.db) // For Fluent to add ID & createdAt
        return user.toDTO() // Now we have enough info for output DTO
    }
    
    func login(req: Request) async throws -> String {
        let dto = try req.content.decode(UserLoginDTO.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == dto.email)
            .first()
        else{
            throw Abort(.notFound)
        }
        
        if try Bcrypt.verify(dto.password, created: user.passwordHash) {
            let payload = UserPayload(
                subject: SubjectClaim(value: user.id!.uuidString), // value = str(UUID)
                expiration: ExpirationClaim(value: Date().addingTimeInterval(3600))
            )
            return try await req.jwt.sign(payload)
        } else{
            throw Abort(.unauthorized)
        }
    }
    
    func patch(req: Request) async throws -> UserDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(UserPatchDTO.self)
        
        guard let userID = UUID(payload.subject.value)
        else{
            throw Abort(.unauthorized)
        }
        
        guard let user = try await User.find(userID, on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        if let newEmail = dto.email {
            user.email = newEmail
        }
        if let newPassword = dto.password {
            let newPasswordHash = try Bcrypt.hash(newPassword)
            user.passwordHash = newPasswordHash
        }
        
        try await user.save(on: req.db)
        return user.toDTO()
    }
}
