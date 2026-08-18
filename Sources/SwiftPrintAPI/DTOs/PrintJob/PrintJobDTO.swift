//
//  PrintJobDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/18/26.
//

import Fluent
import Vapor

struct PrintJobDTO: Content {
    var id: UUID?
    var duration: Double
    var weightGrams: Double
    var success: Bool
    var cost: Double
    var createdAt: Date?
    var userID: UUID
    var printerID: UUID
    var filamentID: UUID
}
