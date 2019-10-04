//
//  Task+Convenience.swift
//  Tasks
//
//  Created by John Kouris on 10/1/19.
//  Copyright © 2019 John Kouris. All rights reserved.
//

import Foundation
import CoreData

enum TaskPriority: String {
    case low
    case normal
    case high
    case critical
}

extension Task {
    
    convenience init(name: String, notes: String? = nil, priority: TaskPriority = .normal, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.name = name
        self.notes = notes
        self.priority = priority.rawValue
    }
    
}
