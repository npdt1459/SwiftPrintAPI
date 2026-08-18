//
//  PrinterDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/1/26.
//

import Fluent
import Vapor

struct PrinterDTO: Content {
    var id: UUID?
    var title: String
    var areaString: String
    var totalPrintMinutes: Double
    var userID: UUID?
}
