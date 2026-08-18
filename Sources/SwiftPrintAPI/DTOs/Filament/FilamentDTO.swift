//
//  FilamentDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/10/26.
//

import Fluent
import Vapor

struct FilamentDTO: Content {
    var id: UUID?
    var title: String
    var color: String
    var material: String
    var weightGrams: Double
    var costPerKg: Double
    var userID: UUID?
}
