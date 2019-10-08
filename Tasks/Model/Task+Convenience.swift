//
//  Task+Convenience.swift
//  Tasks
//
//  Created by John Kouris on 10/1/19.
//  Copyright © 2019 John Kouris. All rights reserved.
//

import Foundation
import CoreData

enum TaskPriority: Int16, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    var name: String {
        switch self {
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
    
    init(stringName: String) {
        switch stringName {
        case "low":
            self = .low
        case "normal":
            self = .normal
        case "high":
            self = .high
        case "critical":
            self = .critical
        default:
            self = .normal
        }
    }
}

extension Task {
    
    convenience init(name: String, notes: String? = nil, priority: TaskPriority = .normal, identifier: UUID = UUID(), context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.name = name
        self.notes = notes
        self.priority = priority.rawValue
        self.uuid = identifier
    }
    
    // Retrieving a task from a server
    convenience init?(taskRepresentation: TaskRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        guard let priority = TaskPriority(rawValue: taskRepresentation.priority),
            let identifierString = taskRepresentation.identifier,
            let identifier = UUID(uuidString: identifierString) else { return nil }
        
        self.init(name: taskRepresentation.name, notes: taskRepresentation.notes, priority: priority, identifier: identifier, context: context)
    }
    
    // Sending a task to a server
    var taskRepresentation: TaskRepresentation? {
        guard let name = name else { return nil }
        return TaskRepresentation(name: name, notes: notes, priority: priority, identifier: uuid?.uuidString ?? "")
    }
    
}
