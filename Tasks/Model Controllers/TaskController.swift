//
//  TaskController.swift
//  Tasks
//
//  Created by John Kouris on 10/7/19.
//  Copyright © 2019 John Kouris. All rights reserved.
//

import Foundation
import CoreData

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

class TaskController {
    
    typealias CompletionHandler = (Error?) -> Void
    
    let baseURL = URL(string: "http://tasks-3f211.firebaseio.com/")!
    
    func fetchTasksFromServer(completion: @escaping CompletionHandler = { _ in }) {
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                print("Error fetching tasks: \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                print("No data returned by data task")
                completion(nil)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // Attempting to decode our data (from our HTTP response) into a dictionary of TaskRepresentation objects keyed by String values (UUIDs)
                let dictionaryOfTasks = try decoder.decode([String: TaskRepresentation].self, from: data)
                // Create an array of just the values from TaskRepresentations and discarding the keys ([TaskRepresentation])
                let taskRepresentations = Array(dictionaryOfTasks.values)
                
                try self.updateTasks(with: taskRepresentations)
                
                completion(nil)
            } catch {
                print("Error decoding task representations: \(error)")
                completion(error)
                return
            }
        }.resume()
    }
    
    func put(task: Task, completion: @escaping CompletionHandler = { _ in }) {
        let uuid = task.uuid ?? UUID()
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.put.rawValue
        
        do {
            // Convert managed object to codable conforming struct
            guard var representation = task.taskRepresentation else {
                completion(nil)
                return
            }
            
            representation.identifier = uuid.uuidString
            task.uuid = uuid
            
            try saveToPersistentStore()
            
            request.httpBody = try JSONEncoder().encode(representation)
            
        } catch {
            print("Error encoding task (or saving to persistent store): \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                print("Error PUTing task to server: \(error)")
                completion(error)
                return
            }
            completion(nil)
        }.resume()
    }
    
    private func updateTasks(with representations: [TaskRepresentation]) throws {
//        let tasksWithID = representations.filter { (taskRepresentation) -> Bool in
//            return taskRepresentation.identifier != nil
//        }
        // The code below is shorthand for the code above
        let tasksWithID = representations.filter({ $0.identifier != nil })
        let identifiersToFetch = tasksWithID.compactMap({ UUID(uuidString: $0.identifier!) })
        
        // Creating a dictionary of TaskRepresentation objects keyed by UUID
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, tasksWithID))
        
        // Running log of all the tasks we need to do something with (either update existing tasks or create new ones)
        var tasksToCreate = representationsByID
        
        // Fetch the objects from CoreData that have a UUID contained in the identifiersToFetch array
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid IN %@", identifiersToFetch)
        
        let context = CoreDataStack.shared.mainContext
        
        do {
            let existingTasks = try context.fetch(fetchRequest)
            
            // Updating existing Tasks
            for task in existingTasks {
                guard let id = task.uuid,
                    let representation = representationsByID[id] else {
                        continue
                }
                self.update(task: task, with: representation)
                
                // Remove the object that we just updated from our running log
                tasksToCreate.removeValue(forKey: id)
            }
            
            // Create new Tasks for all remaining server Tasks
            for representation in tasksToCreate.values {
                let _ = Task(taskRepresentation: representation, context: context)
            }
        } catch {
            print("Error fetching tasks for UUIDs: \(error)")
        }
        
        try saveToPersistentStore()
    }
    
    func update(task: Task, with representation: TaskRepresentation) {
        let priority = TaskPriority(stringName: representation.priority) ?? TaskPriority.normal
        task.name = representation.name
        task.notes = representation.notes
        task.priority = priority.rawValue
    }
    
    func saveToPersistentStore() throws {
        try CoreDataStack.shared.mainContext.save()
    }
    
}
