//
//  File.swift
//  
//
//  Created by Petya Damyanova on 27.01.24.
//

import Foundation
import Fluent
import Vapor
import BCrypt

struct UserController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
        users.post(use: create)
        users.post("login", use: login)
        
        let mealController = MealController()
        try routes.register(collection: mealController)
    }
    
    // Get request /users route
    func index(req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let create = try req.content.decode(User.Create.self)

            // Ensure that passwords match
            guard create.password == create.confirmPassword else {
                throw Abort(.badRequest, reason: "Passwords did not match")
            }

            // Hash the password using BCrypt
            let hashedPassword = try Bcrypt.hash(create.password)

            // Check if a user with the same email already exists
            return User.query(on: req.db)
                .filter(\.$email == create.email)
                .first()
                .flatMap { existingUser -> EventLoopFuture<HTTPStatus> in
                    if let existingUser = existingUser {
                        // A user with the same email already exists
                        let error = Abort(.badRequest, reason: "User with this email already exists")
                        return req.eventLoop.makeFailedFuture(error)
                    } else {
                        // Create a User model
                        let user = User(
                            username: create.username,
                            email: create.email,
                            nightscout: create.nightscout,
                            password_hash: hashedPassword,
                            birtDate: create.birtDate,
                            yearOfDiagnosis: create.yearOfDiagnosis,
                            pumpModel: create.pumpModel,
                            sensorModel: create.sensorModel,
                            insulinType: create.insulinType
                        )

                        // Save the user asynchronously
                        return user.save(on: req.db)
                            .map { _ in
                                return .ok
                            }
                    }
                }
        } catch {
            return req.eventLoop.makeFailedFuture(error)
        }
    }

    func login(req: Request) async throws -> User.Public {
        do {
            let login = try req.content.decode(User.Login.self)

            guard let user = try await User.query(on: req.db)
                .filter(\.$email == login.email)
                .first() else {
                    throw Abort(.unauthorized, reason: "User not found")
            }
            
            do {
                if try Bcrypt.verify(login.password, created: user.password_hash) {
                    return user.toPublic()
                } else {
                    throw Abort(.unauthorized, reason: "Invalid password")
                }
            } catch {
                throw Abort(.internalServerError, reason: "Error verifying password")
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw Abort(.badRequest, reason: "Error decoding request body")
        } catch {
            throw Abort(.badRequest, reason: "Invalid request body")
        }
    }


}
