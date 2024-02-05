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
        let tests = routes.grouped("users", ":userId", "glucometer-tests")
        tests.post(use: createTest)
        tests.get(use: getAllTests)
    }
    
    func createTest(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        
        let testData: GlucometerBloodSugarTest.Create = try req.content.decode(GlucometerBloodSugarTest.Create.self)
        
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
        
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                return GlucometerBloodSugarTest.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .all()
            }
    }
}
