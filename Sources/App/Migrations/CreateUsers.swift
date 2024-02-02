//
//  File.swift
//  
//
//  Created by Petya Damyanova on 27.01.24.
//

import Foundation
import Fluent

struct CreateUsers: Migration {
    func prepare(on database: FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        return database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("nightscout", .string, .required)
            .field("birtDate", .string, .required)
            .field("yearOfDiagnosis", .string, .required)
            .field("pumpModel", .string, .required)
            .field("sensorModel", .string, .required)
            .field("insulinType", .string, .required)
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}
