//
//  GlucometerBloodSugarTestController.swift
//  
//
//  Created by Petya Damyanova on 5.02.24.
//

import Foundation
import Vapor
import Fluent

struct GlucometerBloodSugarTestController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")

        let protected = users.grouped(JWTAuthenticationMiddleware())
            
        let tests = protected.grouped(":userId", "glucometer-tests")
        tests.post(use: createTest)
        tests.get(use: getAllTests)
        tests.delete(":testId", use: deleteTest)
    }
    
    func createTest(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        
        let testData: GlucometerBloodSugarTest.Create = try req.content.decode(GlucometerBloodSugarTest.Create.self)
        
        do {
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or missing authentication token")
        }
        
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                let test = GlucometerBloodSugarTest(timestamp: testData.timestamp, bloodSugar: testData.bloodSugar, userID: user.id!)
                return test.save(on: req.db)
                    .transform(to: .created)
            }
    }
    
    func getAllTests(req: Request) throws -> EventLoopFuture<[GlucometerBloodSugarTest]> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        
        do {
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or missing authentication token")
        }
        
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                return GlucometerBloodSugarTest.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .all()
            }
    }
    
    func deleteTest(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        let testIdParam = try req.parameters.require("testId", as: UUID.self)
        
        do {
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or missing authentication token")
        }

        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                return GlucometerBloodSugarTest.query(on: req.db)
                    .filter(\.$id == testIdParam)
                    .filter(\.$user.$id == user.id!)
                    .first()
                    .unwrap(or: Abort(.notFound, reason: "Glucometer test not found"))
                    .flatMap { test in
                        return test.delete(on: req.db)
                            .transform(to: .noContent)
                    }
            }
    }
}
