//
//  CreateFilament.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/10/26.
//

import Fluent

struct CreateFilament: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("filaments")
            .id()
            .field("title", .string, .required)
            .field("color", .string, .required)
            .field("material", .string, .required)
            .field("weightGrams", .double, .required)
            .field("costPerKg", .double, .required)
            .field("user_id", .uuid, .references("users", "id"))
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("filaments").delete()
    }
}
