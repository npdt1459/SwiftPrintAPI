//
//  Printer.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 7/31/26.
//

import Fluent
import struct Foundation.UUID

final class Printer: Model, @unchecked Sendable {
    static let schema = "printers"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "area")
    var areaString: String
    
    @OptionalParent(key: "user_id")
    var user: User?


    init() { }

    init(id: UUID? = nil, title: String, areaString: String, user: User? = nil) {
        self.id = id
        self.title = title
        self.areaString = areaString
        self.user = user
    }
    
    func toDTO() -> PrinterDTO {
        PrinterDTO(id: self.id, title: self.title, areaString: self.areaString, userID: self.$user.id)
    }
}

