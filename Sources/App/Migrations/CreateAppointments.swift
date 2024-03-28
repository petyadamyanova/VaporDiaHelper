//
//  CreateAppointments.swift
//
//
//  Created by Petya Damyanova on 28.03.24.
//

import Foundation
import Fluent

struct CreateAppointments: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("appointments")
            .id()
            .field("label", .string, .required)
            .field("doctor", .string, .required)
            .field("date", .string, .required)
            .field("place", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("appointments").delete()
    }
}
