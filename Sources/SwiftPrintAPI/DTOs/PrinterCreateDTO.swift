//
//  PrinterCreateDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/3/26.
//

import Fluent
import Vapor

struct PrinterCreateDTO: Content {
    var title: String
    var areaString: String
}
