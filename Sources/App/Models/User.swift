//
//  File.swift
//  
//
//  Created by Petya Damyanova on 27.01.24.
//

import Foundation
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var password_hash: String
    
    @Field(key: "nightscout")
    var nightscout: String
    
    @Field(key: "birtDate")
    var birtDate: String
    
    @Field(key: "yearOfDiagnosis")
    var yearOfDiagnosis: String
    
    @Field(key: "pumpModel")
    var pumpModel: String
    
    @Field(key: "sensorModel")
    var sensorModel: String
    
    @Field(key: "insulinType")
    var insulinType: String
    
    @Children(for: \.$user)
        var meals: [Meal]
    
    @Children(for: \.$user)
        var glucometerBloodSugarTests: [GlucometerBloodSugarTest]
    
    init() { }

    init(id: UUID? = nil, username: String, email: String, nightscout: String, password_hash: String, birtDate: String, yearOfDiagnosis: String, pumpModel: String, sensorModel: String, insulinType: String) {
        self.id = id
        self.username = username
        self.email = email
        self.password_hash = password_hash
        self.nightscout = nightscout
        self.birtDate = birtDate
        self.yearOfDiagnosis = yearOfDiagnosis
        self.pumpModel = pumpModel
        self.sensorModel = sensorModel
        self.insulinType = insulinType
    }
}

extension User {
    struct Create: Content {
        var username: String
        var email: String
        var password: String
        var confirmPassword: String
        var nightscout: String
        var birtDate: String
        var yearOfDiagnosis: String
        var pumpModel: String
        var sensorModel: String
        var insulinType: String
    }
    
    // Add a new struct for representing login credentials
    struct Login: Content {
        var email: String
        var password: String
    }

    // Add a new struct for representing publicly exposed user details
    struct Public: Content {
        var id: UUID?
        var username: String
        var email: String
        var nightscout: String
        var birtDate: String
        var yearOfDiagnosis: String
        var pumpModel: String
        var sensorModel: String
        var insulinType: String
    }
    
    func toPublic() -> Public {
        // Convert the user to a Public struct for response
        return Public(
            id: id,
            username: username,
            email: email,
            nightscout: nightscout,
            birtDate: birtDate,
            yearOfDiagnosis: yearOfDiagnosis,
            pumpModel: pumpModel,
            sensorModel: sensorModel,
            insulinType: insulinType
        )
    }
    
    func addMeal(timestamp: Date, bloodSugar: Double, insulinDose: Double, carbsIntake: Double, foodType: String, on database: Database) -> EventLoopFuture<Void> {
        let meal = Meal(timestamp: timestamp, bloodSugar: bloodSugar, insulinDose: insulinDose, carbsIntake: carbsIntake, foodType: foodType, userID: self.id!)
        return meal.create(on: database)
    }
    
    func addGlucometerBloodSugarTest(timestamp: Date, bloodSugar: Double, userID: UUID, on database: Database) -> EventLoopFuture<Void> {
        let glucometerBloodSugarTest = GlucometerBloodSugarTest(timestamp: timestamp, bloodSugar: bloodSugar, userID: userID)
        return glucometerBloodSugarTest.create(on: database)
    }
    
    func updateUsername(to newUsername: String, on database: Database) -> EventLoopFuture<Void> {
        self.username = newUsername
        return self.save(on: database)
    }
}
