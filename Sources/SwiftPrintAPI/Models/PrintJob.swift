//
//  PrintJob.swift
//  SwiftPrintAPI
//
//  Created by Nathan Andrei Pascale on 8/11/26.
//

import Fluent
import Foundation


final class PrintJob: Model, @unchecked Sendable {
    static let schema = "printJobs"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "printer_id")
    var printer: Printer
    
    @Parent(key: "filament_id")
    var filament: Filament
    
    @Field(key: "duration")
    var duration: Double
    
    @Field(key: "weightGrams")
    var weightGrams: Double
    
    @Field(key: "success")
    var success: Bool
    
    @Field(key: "cost")
    var cost: Double
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, duration: Double, weightGrams: Double, success: Bool, cost: Double, user: User, printer: Printer, filament: Filament) {
        self.id = id
        self.duration = duration
        self.weightGrams = weightGrams
        self.success = success
        self.cost = cost
        self.$user.id = user.id!
        self.$printer.id = printer.id!
        self.$filament.id = filament.id!
    }

    func toDTO() -> PrintJobDTO {
        PrintJobDTO(
            id: self.id,
            duration: self.duration,
            weightGrams: self.weightGrams,
            success: self.success,
            cost: self.cost,
            createdAt: self.createdAt,
            userID: self.$user.id,
            printerID: self.$printer.id,
            filamentID: self.$filament.id
        )
    }
    
}
