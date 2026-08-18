

//
//  PrintJobCreate.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/18/26.
//

import Fluent
import Vapor

struct PrintJobCreateDTO: Content {
    var duration: Double
    var weightGrams: Double
    var success: Bool
    var cost: Double
    var printerID: UUID
    var filamentID: UUID
}
