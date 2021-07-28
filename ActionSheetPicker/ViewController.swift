//
//  ViewController.swift
//  ActionSheetPicker
//
//  Created by MacBook Pro on 20/07/2021.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Custom Pickers"
        
    }
    
    @IBAction func showDateTimePickerButtonAction(_ sender: Any) {
        var options: [String] = []
        for x in 0...10 {
            options.append("Option \(x + 1)")
        }
        
        CustomPicker(title: "Select Date")
            .configureForDatePicker(selectedDate: Date(), minDate: nil, maxDate: nil)
            .addCancelAction {
                print("Cancel Pressed")
            }
            .addDoneAction(callBack: { selection in
                print("Selection: \(selection)")
            })
            .show(presenter: self)
    }
    
    @IBAction func showSingleSelectPickerButtonAction(_ sender: Any) {
        var options: [String] = []
        for x in 0..<10 {
            options.append("Option \(x + 1)")
        }
        
        CustomPicker(title: "Single Select")
            .configureForList(options: options, selections: ["Option 2"], selectionType: .Single)
            .addCancelAction {
                print("Cancel Pressed")
            }
            .addDoneAction(callBack: { selection in
                print("Selection: \(selection)")
            })
            .show(presenter: self)
    }
    @IBAction func showMultiSelectButtonAction(_ sender: Any) {
        var options: [String] = []
        for x in 0..<10 {
            options.append("Option \(x + 1)")
        }
        
        CustomPicker(title: "Multi Select")
            .configureForList(options: options, selections: ["Option 2"], selectionType: .Multi)
            .addCancelAction {
                print("Cancel Pressed")
            }
            .addDoneAction(callBack: { selection in
                print("Selection: \(selection)")
            })
            .show(presenter: self)
    }
}
