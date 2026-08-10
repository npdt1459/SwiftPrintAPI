//
//  PrinterPatchDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/10/26.
//

import Fluent
import Vapor

struct PrinterPatchDTO: Content {
    var title: String?
    var areaString: String?
}
