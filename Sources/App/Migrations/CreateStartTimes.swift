//
//  CreateStartTimes.swift
//  
//
//  Created by Petya Damyanova on 15.02.24.
//

import Foundation
import Fluent

struct CreateStartTimes: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("start_times")
            .id()
            .field("sensorStartDateTime", .datetime)
            .field("pumpStartDateTime", .datetime)
            .field("insulinCanulaStartDateTime", .datetime)
            .field("glucometerCanulaStartDateTime", .datetime)
            .field("user_id", .uuid, .references("users", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("start_times").delete()
    }
}
