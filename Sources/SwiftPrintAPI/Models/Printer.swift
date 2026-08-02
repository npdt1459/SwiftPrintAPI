import Fluent
import struct Foundation.UUID
//
//  Printer.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 7/31/26.
//

final class Printer: Model, @unchecked Sendable {
    static let schema = "printers"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "area")
    var area: String
    
    @OptionalParent(key: "user_id")
    var user: User?


    init() { }

    init(id: UUID? = nil, title: String, area: String, user_id: User? = nil) {
        self.id = id
        self.title = title
        self.area = area
        self.user = user
    }
    
    func toDTO() -> TodoDTO {
        .init(
            id: self.id,
            title: self.$title.value
        )
    }
}

