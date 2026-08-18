//
//  CreatePrintJob.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/18/26.
//

import Fluent

struct CreatePrintJob: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("printJobs")
            .id()
            .field("duration", .double, .required)
            .field("weightGrams", .double, .required)
            .field("success", .bool, .required)
            .field("cost", .double, .required)
            .field("createdAt", .datetime)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("printer_id", .uuid, .required, .references("printers", "id"))
            .field("filament_id", .uuid, .required, .references("filaments", "id"))
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("printJobs").delete()
    }
}
