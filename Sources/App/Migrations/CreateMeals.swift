//
//  File.swift
//  
//
//  Created by Petya Damyanova on 1.02.24.
//

import Foundation
import Fluent

struct CreateMeals: Migration {
    func prepare(on database: FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        return database.schema("meals")
            .id()
            .field("timestamp", .datetime, .required)
            .field("bloodSugar", .double, .required)
            .field("insulinDose", .double, .required)
            .field("carbsIntake", .double, .required)
            .field("foodType", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        return database.schema("meals").delete()
    }
}

