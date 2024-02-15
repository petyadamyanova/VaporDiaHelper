//
//  StartTimes.swift
//
//
//  Created by Petya Damyanova on 15.02.24.
//

import Foundation
import Fluent
import Vapor

final class StartTimes: Model, Content {
    static let schema = "start_times"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "sensorStartDateTime")
    var sensorStartDateTime: String?

    @Field(key: "pumpStartDateTime")
    var pumpStartDateTime: String?

    @Field(key: "insulinCanulaStartDateTime")
    var insulinCanulaStartDateTime: String?

    @Field(key: "glucometerCanulaStartDateTime")
    var glucometerCanulaStartDateTime: String?

    // Reference to the user
    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, sensorStartDateTime: String?, pumpStartDateTime: String?, insulinCanulaStartDateTime: String?, glucometerCanulaStartDateTime: String?, userId: UUID) {
        self.id = id
        self.sensorStartDateTime = sensorStartDateTime
        self.pumpStartDateTime = pumpStartDateTime
        self.insulinCanulaStartDateTime = insulinCanulaStartDateTime
        self.glucometerCanulaStartDateTime = glucometerCanulaStartDateTime
        self.$user.id = userId
    }
}

extension StartTimes {
    struct Create: Content {
        var sensorStartDateTime: String?
        var pumpStartDateTime: String?
        var insulinCanulaStartDateTime: String?
        var glucometerCanulaStartDateTime: String?
    }
}
