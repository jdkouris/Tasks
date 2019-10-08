//
//  TaskController.swift
//  Tasks
//
//  Created by John Kouris on 10/7/19.
//  Copyright © 2019 John Kouris. All rights reserved.
//

import Foundation
import CoreData

class TaskController {
    
    let baseURL = URL(string: "http://tasks-3f211.firebaseio.com/")!
    
    func fetchTasksFromServer(completion: @escaping (Error?) -> Void = { _ in }) {
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
    
    private func updateTasks(with representations: [TaskRepresentation]) throws {
//        let tasksWithID = representations.filter { (taskRepresentation) -> Bool in
//            return taskRepresentation.identifier != nil
//        }
        // The code below is shorthand for the code above
        let tasksWithID = representations.filter({ $0.identifier != nil })
        let identifiersToFetch = tasksWithID.compactMap({ UUID(uuidString: $0.identifier!) })
        
        // Creating a dictionary of TaskRepresentation objects keyed by UUID
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, tasksWithID))
        
        var tasksToCreate = representationsByID
        
        // Fetch the objects from CoreData that have a UUID contained in the identifiersToFetch array
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid IN %@", identifiersToFetch)
        
        let context = CoreDataStack.shared.mainContext
        
        do {
            let existingTasks = try context.fetch(fetchRequest)
            for task in existingTasks {
                guard let id = task.uuid,
                    let representation = representationsByID[id] else {
                        continue
                }
                self.update(task: task, with: representation)
                tasksToCreate.removeValue(forKey: id)
            }
            
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
