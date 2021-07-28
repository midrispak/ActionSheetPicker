//
//  ActionSheetController.swift
//  ActionSheetPicker
//
//  Created by MacBook Pro on 23/07/2021.
//

import Foundation
import UIKit

enum SelectionType: Int {
    case Single
    case Multi
}

enum PickerType: Equatable {
    case List(selectionType: SelectionType)
    case DateTime
}

class CustomPicker: NSObject {
    
    private var pickerTitle: String? = nil
    private var pickerType: PickerType!
    
    private var pickerOptions: [Option] = [Option]()
    private var doneCompletionCallBack: ((Any) -> Void)? = nil
    
    private var alertContentController = UIViewController()
    private lazy var pickerContentView: PickerContentView = {
        PickerContentView(width: UIScreen.main.bounds.size.width - 16, barTintColor: .systemGray6, titleTextColor: .darkGray)
    }()
    
    private var alertController: UIAlertController!
    
    init(title: String? = nil, message: String? = nil) {
        super.init()
        
        self.pickerTitle = title
        
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.view.tintColor = .systemTeal
        alertController.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func addAction(title: String, style: UIAlertAction.Style, actionCallBack: (() -> Void)? = nil) -> Self {
        let action = UIAlertAction(title: title, style: style) { action in
            actionCallBack?()
        }
        self.alertController.addAction(action)
        return self
    }
    
    func addCancelAction(callBack: @escaping () -> Void) -> Self {
        return addAction(title: "Cancel", style: .cancel, actionCallBack: callBack)
    }
    
    func addDoneAction(callBack: @escaping (Any) -> Void) -> Self {
        doneCompletionCallBack = callBack
        
        if (pickerType != .List(selectionType: .Single)) {
            return addAction(title: "Done", style: .default) {
                if (self.pickerType == .DateTime) {
                    self.doneCompletionCallBack?(self.pickerContentView.selectedDate)
                }
                else {
                    self.doneCompletionCallBack?(self.pickerContentView.selections)
                }
            }
        }
        else {
            self.pickerContentView.setSingleSelectCallBack { selectedValue in
                self.doneCompletionCallBack?(selectedValue)
                self.alertController.dismiss(animated: true, completion: nil)
            }
        }
        return self
    }
    
    func configureForList(options: [String], selections: [String], selectionType: SelectionType) -> Self {
        
        // Prepare options from strings
        
        var temp = [Option]()
        for str in options {
            var anOption = Option(text: str, selected: false)
            anOption.selected = selections.contains(str)
            temp.append(anOption)
        }
        pickerOptions.removeAll()
        pickerOptions += temp
        
        pickerType = .List(selectionType: selectionType)
        
        var maxHeight = 0.65 * UIScreen.main.bounds.height
        maxHeight -= (selectionType == .Multi) ? 50.0 : 0.0
        
        pickerContentView.configureForTableView(title: pickerTitle ?? "Please Select", options: pickerOptions, selectionType: selectionType, maxHeight: maxHeight)
        
        alertContentController.preferredContentSize = pickerContentView.frame.size
        alertContentController.view = pickerContentView
        alertController.setValue(alertContentController, forKey: "contentViewController")
        return self
    }
    
    func configureForDatePicker(selectedDate: Date?, minDate: Date?, maxDate: Date?) -> Self {
        pickerType = .DateTime
        
        pickerContentView.configureForDateTimePicker(title: pickerTitle ?? "", selectedDate: selectedDate, minDate: minDate, maxDate: maxDate)
        alertContentController.preferredContentSize = pickerContentView.frame.size
        alertContentController.view = pickerContentView
        alertController.setValue(alertContentController, forKey: "contentViewController")
        
        return self
    }
    
    func show(presenter: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        presenter.present(alertController, animated: true) {
            self.pickerContentView.reloadTableView()
            completion?()
        }
    }
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        alertController.dismiss(animated: animated , completion: completion)
    }
}

let rowHeight: CGFloat = 56.0

struct Option {
    let text: String
    var selected: Bool
}

class PickerContentView: UIView {
    
    private var pickerOptions: [Option] = [Option]()
    private var singleSelectCallback: ((String) -> Void)? = nil
    private var selectionType: SelectionType? = .Single
    
    private var titleItem: UINavigationItem!
    private lazy var navigationBar: UINavigationBar = {
        let nb = UINavigationBar(frame: .zero)
        titleItem = UINavigationItem(title: "Please Select")
        nb.setItems([titleItem], animated: false)
        return nb
    }()
    
    private lazy var tableView: UITableView = {
        let tb = UITableView()
        tb.separatorInset = .zero
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.register(CustomPickerCell.self, forCellReuseIdentifier: CustomPickerCell.identifier)
        tb.delegate = self
        tb.dataSource = self
        
        return tb
    }()
    
    private lazy var dateTimePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.preferredDatePickerStyle = .wheels
        return dp
    }()
    
    private var container: UIView!
    
    var selectedDate: Date {
        return self.dateTimePicker.date
    }
    
    var selections: [String] {
        return self.pickerOptions.filter { $0.selected == true}.map { $0.text}
    }
    
    convenience init(width: CGFloat, barTintColor: UIColor = .white, titleTextColor: UIColor = .black) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        navigationBar.barTintColor = barTintColor
        navigationBar.titleTextAttributes = [.foregroundColor: titleTextColor]
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialSetup()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialSetup() {
        
        container = UIView(frame: self.bounds)
        self.addSubview(container)
        container.addSubview(navigationBar)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            container.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            container.widthAnchor.constraint(equalToConstant: self.bounds.width),
            container.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: container.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44.0)
        ])
    }
    
    func configureForDateTimePicker(title: String, selectedDate: Date? = nil, minDate: Date? = nil, maxDate: Date? = nil, pickerMode: UIDatePicker.Mode = .dateAndTime) {
        
        dateTimePicker.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.removeFromSuperview()
        dateTimePicker.removeFromSuperview()
        
        self.addSubview(dateTimePicker)
        
        self.titleItem.title = title
        dateTimePicker.date = selectedDate ?? Date()
        dateTimePicker.minimumDate = minDate
        dateTimePicker.maximumDate = maxDate
        dateTimePicker.datePickerMode = pickerMode
        
        NSLayoutConstraint.activate([
            dateTimePicker.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            dateTimePicker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dateTimePicker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            dateTimePicker.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }
    
    func configureForTableView(title: String, options: [Option], selectionType: SelectionType, maxHeight: CGFloat) {
        self.titleItem.title = title
        self.pickerOptions += options
        self.selectionType = selectionType
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.removeFromSuperview()
        dateTimePicker.removeFromSuperview()
        
        self.addSubview(tableView)
        
        let rowsCount = self.pickerOptions.count
        let calculatedHeight = CGFloat(rowsCount)  * rowHeight
        
        tableView.isScrollEnabled = calculatedHeight >= maxHeight
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            tableView.heightAnchor.constraint(equalToConstant: min(maxHeight, calculatedHeight))
        ])
    }
    
    func setSingleSelectCallBack(callBack: @escaping (String) -> Void) {
        self.singleSelectCallback = callBack
    }
    
    func reloadTableView() {
        tableView.reloadData()
    }
}

extension PickerContentView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pickerOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomPickerCell.identifier) as! CustomPickerCell
        let anOption = self.pickerOptions[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.text = "\(anOption.text)"
        cell.isSelected = anOption.selected
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var anOption = pickerOptions[indexPath.row]
        if self.selectionType == .Single {
            self.singleSelectCallback?(anOption.text)
        }
        else {
            anOption.selected = !anOption.selected
        }
        pickerOptions[indexPath.row] = anOption
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

class CustomPickerCell: UITableViewCell {
    
    static let identifier = "CustomPickerCellIdentifier"
    var container: UIView!
    override var isSelected: Bool {
        didSet(value) {
            self.contentView.backgroundColor = value ? .systemGray6 : .clear
            self.textLabel?.textColor = value ? .systemTeal : .black
            self.textLabel?.font = value ? UIFont.boldSystemFont(ofSize: 18.0) : UIFont.systemFont(ofSize: 17.0)
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        container = UIView(frame: .zero)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
        ])
        
        self.contentView.addSubview(contentView)
    }
}
