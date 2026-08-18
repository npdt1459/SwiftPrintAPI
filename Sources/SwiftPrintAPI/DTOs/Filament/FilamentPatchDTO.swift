//
//  FilamentPatchDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/11/26.
//

import Fluent
import Vapor

struct FilamentPatchDTO: Content {
    var title: String?
    var color: String?
    var material: String?
    var weightGrams: Double?
    var costPerKg: Double?
}
