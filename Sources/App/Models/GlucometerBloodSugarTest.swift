//
//  GlucometerBloodSugarTest.swift
//
//
//  Created by Petya Damyanova on 5.02.24.
//

import Foundation
import Fluent
import Vapor

final class GlucometerBloodSugarTest: Model, Content {
    static let schema = "glucometer_blood_sugar_tests"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "timestamp")
    var timestamp: Date
    
    @Field(key: "bloodSugar")
    var bloodSugar: Double
    
    // Reference to the user
    @Parent(key: "user_id")
    var user: User
    
    init() { }

    init(id: UUID? = nil, timestamp: Date, bloodSugar: Double, userID: UUID) {
        self.id = id
        self.timestamp = timestamp
        self.bloodSugar = bloodSugar
        self.$user.id = userID
    }
}

extension GlucometerBloodSugarTest {
    struct Create: Content {
        var timestamp: Date
        var bloodSugar: Double
    }
}
