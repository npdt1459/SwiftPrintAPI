//
//  UserPayload.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/4/26.
//
import JWT
import Vapor
import Foundation

struct UserPayload: JWTPayload, Authenticatable {
    var subject: SubjectClaim
    var expiration: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
