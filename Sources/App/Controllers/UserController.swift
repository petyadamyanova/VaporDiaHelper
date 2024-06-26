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
import JWTKit

struct UserController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
        users.post(use: create)
        users.post("login", use: login)
        
        let protectedRoutes = users.grouped(JWTAuthenticationMiddleware())

        protectedRoutes.put(":userId", "update-username", use: updateUsername)
        protectedRoutes.put(":userId", "update-email", use: updateEmail)
        protectedRoutes.put(":userId", "update-nightscout", use: updateNightscout)
        protectedRoutes.put(":userId", "update-birthdate", use: updateBirthDate)
        protectedRoutes.put(":userId", "update-year-of-diagnosis", use: updateYearOfDiagnosis)
        protectedRoutes.put(":userId", "update-pump-model", use: updatePumpModel)
        protectedRoutes.put(":userId", "update-sensor-model", use: updateSensorModel)
        protectedRoutes.put(":userId", "update-insulin-type", use: updateInsulinType)
        
        let mealController = MealController()
        try routes.register(collection: mealController)
        
        let glucometerBloodSugarTestController = GlucometerBloodSugarTestController()
        try routes.register(collection: glucometerBloodSugarTestController)
        
        let startTimesController = StartTimesController()
        try routes.register(collection: startTimesController)
        
        let appointmentController = AppointmentController()
        try routes.register(collection: appointmentController)
        
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
    
    func login(req: Request) async throws -> UserLoginResponse {
        do {
            let login = try req.content.decode(User.Login.self)
            
            guard let user = try await User.query(on: req.db)
                .filter(\.$email == login.email)
                .first() else {
                throw LoginError.userNotFound
            }
            
            do {
                if try Bcrypt.verify(login.password, created: user.password_hash) {
                    //return user.toPublic()
                    let expirationInterval: TimeInterval = 14 * 24 * 60 * 60 // 14 days in seconds
                    let expirationDate = Date().addingTimeInterval(expirationInterval)
                    
                    let payload = TestPayload(
                        subject: SubjectClaim(value: user.id!.uuidString),
                        expiration: .init(value: expirationDate)
                    )
                    
                    let token = try req.jwt.sign(payload)
                    
                    return UserLoginResponse(token: token, user: user.toPublic())
                } else {
                    throw LoginError.invalidPassword
                }
            } catch {
                throw Abort(.internalServerError, reason: "Error verifying password")
            }
        } catch LoginError.invalidPassword {
            throw LoginError.invalidPassword
        } catch LoginError.userNotFound {
            throw LoginError.userNotFound
        } catch {
            throw Abort(.badRequest, reason: "Invalid request body")
        }

    }
    
    func updateUsername(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdateUsernameRequest.self)
            
            print("UserId: \(userIdParam), NewUsername: \(updateRequest.newUsername)")
            
            // Verifing the JWT token
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }
            
            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updateUsername(to: updateRequest.newUsername, on: req.db)
                        .map {
                            print("Username updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating username: \(error)")
            throw error
        }
    }
    
    func updateEmail(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdateEmailRequest.self)
            
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }

            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updateEmail(to: updateRequest.newEmail, on: req.db)
                        .map {
                            print("Email updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating email: \(error)")
            throw error
        }
    }
    
    func updateNightscout(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdateNightscoutRequest.self)
            
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }

            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updateNightscout(to: updateRequest.newNightscout, on: req.db)
                        .map {
                            print("Nightscout updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating nightscout: \(error)")
            throw error
        }
    }
    
    func updateBirthDate(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdateBirthDateRequest.self)
            
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }

            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updateBirthDate(to: updateRequest.newBirthDate, on: req.db)
                        .map {
                            print("BirthDate updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating birthDate: \(error)")
            throw error
        }
    }
    
    func updateYearOfDiagnosis(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdateYearOfDiagnosisRequest.self)
            
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }

            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updateYearOfDiagnosis(to: updateRequest.newYearOfDiagnosis, on: req.db)
                        .map {
                            print("Year of Diagnosis updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating year of diagnosis: \(error)")
            throw error
        }
    }

    func updatePumpModel(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdatePumpModelRequest.self)
            
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }

            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updatePumpModel(to: updateRequest.newPumpModel, on: req.db)
                        .map {
                            print("Pump Model updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating pump model: \(error)")
            throw error
        }
    }

    func updateSensorModel(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdateSensorModelRequest.self)
            
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }

            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updateSensorModel(to: updateRequest.newSensorModel, on: req.db)
                        .map {
                            print("Sensor Model updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating sensor model: \(error)")
            throw error
        }
    }

    func updateInsulinType(req: Request) throws -> EventLoopFuture<User> {
        do {
            let userIdParam = try req.parameters.require("userId", as: UUID.self)
            let updateRequest = try req.content.decode(UpdateInsulinTypeRequest.self)
            
            let jwtPayload = try req.jwt.verify(as: TestPayload.self)
            
            guard jwtPayload.subject.value == userIdParam.uuidString else {
                throw Abort(.unauthorized)
            }

            return User.find(userIdParam, on: req.db)
                .unwrap(or: Abort(.notFound, reason: "User not found"))
                .flatMap { user in
                    return user.updateInsulinType(to: updateRequest.newInsulinType, on: req.db)
                        .map {
                            print("Insulin Type updated successfully")
                            return user
                        }
                }
        } catch {
            print("Error updating insulin type: \(error)")
            throw error
        }
    }

    
}

struct TestPayload: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
    }

    var subject: SubjectClaim

    var expiration: ExpirationClaim

    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

struct JWTAuthenticationMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            // extracting the JWT token from the request's headers
            guard let token = request.headers.bearerAuthorization?.token else {
                throw Abort(.unauthorized)
            }

            // Verifing the JWT token
            let jwt = try request.jwt.verify(token, as: TestPayload.self)

            return next.respond(to: request)

        } catch {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
    }
}


struct UserLoginResponse: Content {
    let token: String
    let user: User.Public
}

struct UpdateUsernameRequest: Content {
    var newUsername: String
}

struct UpdateEmailRequest: Content {
    var newEmail: String
}

struct UpdateNightscoutRequest: Content {
    var newNightscout: String
}

struct UpdateBirthDateRequest: Content {
    var newBirthDate: String
}

struct UpdateYearOfDiagnosisRequest: Content {
    var newYearOfDiagnosis: String
}

struct UpdatePumpModelRequest: Content {
    var newPumpModel: String
}

struct UpdateSensorModelRequest: Content {
    var newSensorModel: String
}

struct UpdateInsulinTypeRequest: Content {
    var newInsulinType: String
}

enum LoginError: Error {
    case userNotFound
    case invalidPassword
}

