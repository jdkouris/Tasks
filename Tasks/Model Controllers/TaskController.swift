//
//  TaskController.swift
//  Tasks
//
//  Created by John Kouris on 10/7/19.
//  Copyright © 2019 John Kouris. All rights reserved.
//

import Foundation

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
                
                // TODO: Implement a way to update all tasks using the data we received
                
                completion(nil)
            } catch {
                print("Error decoding task representations: \(error)")
                completion(error)
                return
            }
        }.resume()
    }
    
}
