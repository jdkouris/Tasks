//
//  TaskDetailViewController.swift
//  Tasks
//
//  Created by John Kouris on 10/1/19.
//  Copyright © 2019 John Kouris. All rights reserved.
//

import UIKit

class TaskDetailViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var priorityControl: UISegmentedControl!
    
    var task: Task? {
        didSet {
            updateViews()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        // Stretch goal of diabling the save button
        guard let name = nameTextField.text,
            !name.isEmpty else { return }
        
        let priorityIndex = priorityControl.selectedSegmentIndex
        let priority = TaskPriority.allCases[priorityIndex]
        
        let notes = notesTextView.text
        
        if let task = task {
            // editing an existing task
            task.name = name
            task.priority = priority.rawValue
            task.notes = notes
        } else {
            let _ = Task(name: name, notes: notes, priority: priority)
        }
        
        do {
            let moc = CoreDataStack.shared.mainContext
            try moc.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
        navigationController?.popViewController(animated: true)
    }
    
    func updateViews() {
        guard isViewLoaded else { return }
        title = task?.name ?? "Create Task"
        nameTextField.text = task?.name
        
        var priority: TaskPriority
        if let taskPriorityString = task?.priority, let taskPriority = TaskPriority(rawValue: taskPriorityString) {
            priority = taskPriority
        } else {
            priority = .normal
        }
        
        if let index = TaskPriority.allCases.firstIndex(of: priority) {
            priorityControl.selectedSegmentIndex = index
        }
        
        notesTextView.text = task?.notes
    }
    
    @IBAction func textFieldDidEdit(_ sender: Any) {
        if let name = nameTextField.text, !name.isEmpty {
            saveBarButtonItem.isEnabled = true
        } else {
            saveBarButtonItem.isEnabled = false
        }
    }
    
}
