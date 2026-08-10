//
//  FilamentCreateDTO.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/10/26.
//

import Fluent
import Vapor

struct FilamentCreateDTO: Content {
    var title: String
    var color: String
    var material: String
    var weight: Double
}
