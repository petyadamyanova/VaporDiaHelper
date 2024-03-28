//
//  File.swift
//  
//
//  Created by Petya Damyanova on 28.03.24.
//

import Foundation
import Fluent
import Vapor

final class Appointment: Model, Content {
    static let schema = "appointments"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "label")
    var label: String
    
    @Field(key: "doctor")
    var doctor: String
    
    @Field(key: "date")
    var date: String
    
    @Field(key: "place")
    var place: String

    // Reference to the user
    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, label: String, doctor: String, date: String, place: String, userID: UUID) {
        self.id = id
        self.label = label
        self.doctor = doctor
        self.date = date
        self.place = place
        self.$user.id = userID
    }
}

extension Appointment {
    struct Create: Content {
        var label: String
        var doctor: String
        var date: String
        var place: String
    }
}
