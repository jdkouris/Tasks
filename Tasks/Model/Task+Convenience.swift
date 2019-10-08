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
}

extension Task {
    
    convenience init(name: String, notes: String? = nil, priority: TaskPriority = .normal, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.name = name
        self.notes = notes
        self.priority = priority.rawValue
    }
    
    convenience init?(taskRepresentation: TaskRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        guard let priority = TaskPriority(rawValue: taskRepresentation.priority),
            let identifierString = taskRepresentation.identifier,
            let identifier = UUID(uuidString: identifierString) else { return nil }
        self.init(context: context)
    }
    
}
