//
//  CreateGlucometerBloodSugarTests.swift
//
//
//  Created by Petya Damyanova on 5.02.24.
//

import Foundation
import Fluent

struct CreateGlucometerBloodSugarTests: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("glucometer_blood_sugar_tests")
            .id()
            .field("timestamp", .datetime, .required)
            .field("bloodSugar", .double, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("glucometer_blood_sugar_tests").delete()
    }
}
