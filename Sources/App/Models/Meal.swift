//
//  Meal.swift
//
//
//  Created by Petya Damyanova on 1.02.24.
//

import Foundation
import Fluent
import Vapor

final class Meal: Model, Content {
    static let schema = "meals"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "timestamp")
    var timestamp: Date
    
    @Field(key: "bloodSugar")
    var bloodSugar: Double
    
    @Field(key: "insulinDose")
    var insulinDose: Double
    
    @Field(key: "carbsIntake")
    var carbsIntake: Double
    
    @Field(key: "foodType")
    var foodType: String

    // Reference to the user
    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, timestamp: Date, bloodSugar: Double, insulinDose: Double, carbsIntake: Double, foodType: String, userID: UUID) {
        self.id = id
        self.timestamp = timestamp
        self.bloodSugar = bloodSugar
        self.insulinDose = insulinDose
        self.carbsIntake = carbsIntake
        self.foodType = foodType
        self.$user.id = userID
    }
}

extension Meal {
    struct Create: Content {
        var timestamp: Date
        var bloodSugar: Double
        var insulinDose: Double
        var carbsIntake: Double
        var foodType: String
    }
}
