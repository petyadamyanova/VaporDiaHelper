//
//  MealController.swift
//
//
//  Created by Petya Damyanova on 1.02.24.
//

import Foundation
import Vapor
import Fluent

struct MealController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let meals = routes.grouped("users", ":userId", "meals")
        meals.post(use: createMeal)
        meals.get(use: getAllMeals)
        meals.delete(":mealId", use: deleteMeal)
    }
    
    func createMeal(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        
        let userIdParam = try req.parameters.require("userId", as: UUID.self)
        
        let mealData: Meal.Create = try req.content.decode(Meal.Create.self)
        
        // Check if the user exists
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                // Create a meal associated with the user
                let meal = Meal(timestamp: mealData.timestamp, bloodSugar: mealData.bloodSugar, insulinDose: mealData.insulinDose, carbsIntake: mealData.carbsIntake, foodType: mealData.foodType, userID: user.id!)
                return meal.save(on: req.db)
                    .transform(to: .created)
            }
    }
    
    
    func getAllMeals(req: Request) throws -> EventLoopFuture<[Meal]> {
        let userIdParam = try req.parameters.require("userId", as: UUID.self)

        // Check if the user exists
        return User.find(userIdParam, on: req.db)
            .unwrap(or: Abort(.notFound, reason: "User not found"))
            .flatMap { user in
                // Fetch all meals associated with the user
                return Meal.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .all()
            }
    }
    
    func deleteMeal(req: Request) throws -> EventLoopFuture<HTTPStatus> {
           let userIdParam = try req.parameters.require("userId", as: UUID.self)
           let mealIdParam = try req.parameters.require("mealId", as: UUID.self)

           // Check if the user exists
           return User.find(userIdParam, on: req.db)
               .unwrap(or: Abort(.notFound, reason: "User not found"))
               .flatMap { user in
                   // Find the meal associated with the user and mealId
                   return Meal.query(on: req.db)
                       .filter(\.$id == mealIdParam)
                       .filter(\.$user.$id == user.id!)
                       .first()
                       .unwrap(or: Abort(.notFound, reason: "Meal not found"))
                       .flatMap { meal in
                           // Delete the meal
                           return meal.delete(on: req.db)
                               .transform(to: .noContent)
                       }
               }
       }
}
