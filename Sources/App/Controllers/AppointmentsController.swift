//
//  File.swift
//  
//
//  Created by Petya Damyanova on 28.03.24.
//

import Foundation
import Vapor
import Fluent

struct AppointmentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let appointments = routes.grouped("users", ":userId", "appointments")
        appointments.post(use: createAppointment)
        appointments.get(use: getAllAppointments)
        appointments.delete(":appointmentId", use: deleteAppointment)
    }
    
    func createAppointment(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        let appointmentData: Appointment.Create = try req.content.decode(Appointment.Create.self)
        
        // Check if the user exists
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                // Create an appointment associated with the user
                let appointment = Appointment(label: appointmentData.label, doctor: appointmentData.doctor, date: appointmentData.date, place: appointmentData.place, userID: user.id!)
                return appointment.save(on: req.db)
                    .transform(to: .created)
            }
    }
    
    
    func getAllAppointments(req: Request) throws -> EventLoopFuture<[Appointment]> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)

        // Check if the user exists
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                // Fetch all appointments associated with the user
                return Appointment.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .all()
            }
    }
    
    func deleteAppointment(req: Request) throws -> EventLoopFuture<HTTPStatus> {
           let userIdParam = try req.parameters.require("userId", as: UUID.self)
           let appointmentIdParam = try req.parameters.require("appointmentId", as: UUID.self)

           // Check if the user exists
           return User.find(userIdParam, on: req.db)
               .unwrap(or: Abort(.notFound, reason: "User not found"))
               .flatMap { user in
                   // Find the appointment associated with the user and appointmentId
                   return Appointment.query(on: req.db)
                       .filter(\.$id == appointmentIdParam)
                       .filter(\.$user.$id == user.id!)
                       .first()
                       .unwrap(or: Abort(.notFound, reason: "Appointment not found"))
                       .flatMap { appointment in
                           // Delete the appointment
                           return appointment.delete(on: req.db)
                               .transform(to: .noContent)
                       }
               }
       }
}
