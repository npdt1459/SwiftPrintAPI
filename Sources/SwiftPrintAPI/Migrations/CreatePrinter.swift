//
//  CreatePrinter.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/1/26.
//
import Fluent

struct CreatePrinter: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("printers")
            .id()
            .field("title", .string, .required)
            .field("area", .string, .required)
            .field("user_id", .uuid, .references("users", "id"))
            .field("totalPrintMinutes", .double, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("printers").delete()
    }
}

