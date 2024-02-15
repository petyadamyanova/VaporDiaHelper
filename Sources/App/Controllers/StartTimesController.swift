//
//  File.swift
//  
//
//  Created by Petya Damyanova on 15.02.24.
//

import Foundation
import Vapor
import Fluent

struct StartTimesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let startTimes = routes.grouped("users", ":userId", "start-times")
        startTimes.post(use: createStartTime)
        startTimes.get(use: getAllStartTimes)
        startTimes.delete(":startTimeId", use: deleteStartTime)
    }
    
    func createStartTime(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        let startTimeData: StartTimes.Create = try req.content.decode(StartTimes.Create.self)
        
        // Check if the user exists
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                // Check if a start time already exists for the user
                return StartTimes.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .first()
                    .flatMap { existingStartTime in
                        if let existingStartTime = existingStartTime {
                            // Update existing start time
                            existingStartTime.sensorStartDateTime = startTimeData.sensorStartDateTime
                            existingStartTime.pumpStartDateTime = startTimeData.pumpStartDateTime
                            existingStartTime.insulinCanulaStartDateTime = startTimeData.insulinCanulaStartDateTime
                            existingStartTime.glucometerCanulaStartDateTime = startTimeData.glucometerCanulaStartDateTime
                            
                            return existingStartTime.save(on: req.db)
                                .transform(to: .ok)
                        } else {
                            // Create a new start time associated with the user
                            let startTime = StartTimes(
                                sensorStartDateTime: startTimeData.sensorStartDateTime,
                                pumpStartDateTime: startTimeData.pumpStartDateTime,
                                insulinCanulaStartDateTime: startTimeData.insulinCanulaStartDateTime,
                                glucometerCanulaStartDateTime: startTimeData.glucometerCanulaStartDateTime,
                                userId: user.id!
                            )
                            return startTime.save(on: req.db)
                                .transform(to: .created)
                        }
                    }
            }
    }
    
    
    func getAllStartTimes(req: Request) throws -> EventLoopFuture<[StartTimes]> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)

        // Check if the user exists
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                // Fetch all start times associated with the user
                return StartTimes.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .all()
            }
    }
    
    func deleteStartTime(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        let startTimeIdParam = try req.parameters.require("startTimeId", as: UUID.self)

        // Check if the user exists
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                // Find the start time associated with the user and startTimeId
                return StartTimes.query(on: req.db)
                    .filter(\.$id == startTimeIdParam)
                    .filter(\.$user.$id == user.id!)
                    .first()
                    .unwrap(or: Abort(.notFound, reason: "Start time not found"))
                    .flatMap { startTime in
                        // Delete the start time
                        return startTime.delete(on: req.db)
                            .transform(to: .noContent)
                    }
            }
    }
}
