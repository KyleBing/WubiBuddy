//
//  BuddyVC.swift
//  WubiBuddy
//
//  Created by Kyle on 2020/4/1.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Cocoa
import UserNotifications

class BuddyVC: NSViewController {
    
    dynamic var newCode: String = "ggtt"
    dynamic var newWord: String = "五笔"
    // CONST Values
    let IS_TEST_MODE = false
    let tempFileName = "WubiBuddy-Temp.wubibuddy"

    // Storyboard
    @IBOutlet weak var codeTextField: NSTextField!
    @IBOutlet weak var wordTextField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var wordCountLabel: NSTextField!
    @IBOutlet weak var selectedCountLabel: NSTextField!
    @IBOutlet weak var btnDelete: NSButton!
    @IBOutlet weak var btnAdd: NSButton!
    
    @IBAction func delete(_ sender: NSButton) {
        tableView.selectedRowIndexes.forEach { (indexSet) in
            dictionaries.remove(at: indexSet)
        }
        tableView.reloadData()
        updateLabels()
        updateDeleteBtnState()
        writeFile()
    }
    @IBAction func addWord(_ sender: NSButton) {
        let code = codeTextField.stringValue
        let word = wordTextField.stringValue
        if code.count == 0 || word.count == 0{
            // alert
        } else {
            dictionaries.append((code: code, word: word))
            tableView.reloadData()
            updateLabels()
            writeFile()
        }
    }
    
    @IBAction func reloadFileContent(_ sender: Any) {
        dictionaries = []
        loadContent()
        tableView.reloadData()
        updateLabels()
        updateDeleteBtnState()
    }
    
    
    let TextDidChangeNotification = Notification(name: Notification.Name.init("TextDidChange"))
    
    
    var demoURL:URL{
        var filePath = ""
        if (IS_TEST_MODE) {
            let fileName = "Rime.txt"
            filePath = "Desktop/" + fileName
            
        } else {
            let fileName = "wubi86_jidian_addition.dict.yaml"
            filePath = "Library/Rime/" + fileName
        }
        let pathHome = FileManager.default.homeDirectoryForCurrentUser
        let userDictUrl = pathHome.appendingPathComponent(filePath)
        return userDictUrl
    }
    
    var substrings:[String] = []
    var dictionaries: [(code:String, word: String)] = [] {
        didSet{
            dictionaries.sort(by: <)
        }
    }
    var fileHeader:String = ""

    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = demoURL.path
        tableView.dataSource = self
        tableView.delegate = self
//        tableView.allowsMultipleSelection = true
        updateDeleteBtnState()
        updateAddBtnState()
        loadContent()
        tableView.reloadData()
        updateLabels()
    }
    
    override func viewWillAppear() {
        // set window name
        view.window?.title = String(demoURL.path.split(separator: "/").last!)
    }

    override var representedObject: Any? {
        didSet {}
    }

    
    // MARK: - User methods
    // 创建文件
    func writeFile() {
        var output = fileHeader + "\n...\n\n" // 插入头部
        for item in dictionaries{
            output = output + "\(item.word)\t\(item.code)" + "\n"
        }
        var newFileURL = demoURL
        newFileURL.deleteLastPathComponent()
        newFileURL = newFileURL.appendingPathComponent(tempFileName)
        FileManager.default.createFile(atPath:newFileURL.path, contents: output.data(using: .utf8), attributes: nil)
        do {
            try _ = FileManager.default.replaceItemAt(demoURL, withItemAt: newFileURL, backupItemName: "WubiBuddy-Backup.wubibuddy", options: .usingNewMetadataOnly)
        } catch {
            print("replace file fail")
        }
    }
    
    // 载入文件内容
    func loadContent() {
        if let fileContent = try? String(contentsOf: demoURL, encoding: .utf8) {
            
            // 根据 ... 的位置获取文件头部
            let nsFileContent = NSString(string: fileContent)
            let headerRange = nsFileContent.range(of: "...")
            fileHeader = String(fileContent.prefix(headerRange.lowerBound))
            
            let tempStrings = fileContent.split(separator: "\n")
            substrings = tempStrings.map {String($0)}
            substrings = substrings.filter {$0.contains("\t")}
        
            for str in substrings {
                let tempSubstring = str.split(separator: "\t")
                dictionaries.append((code: String(tempSubstring[1]), word: String(tempSubstring[0])))
            }
            wordCountLabel.stringValue = "共\(dictionaries.count)条"
        } else {
            print("get file content fail")
        }
    }
    
    // 更新删除按钮状态
    func updateDeleteBtnState() {
        if tableView.selectedRowIndexes.count > 0{
             btnDelete.isEnabled = true
        } else {
             btnDelete.isEnabled = false
        }
    }
    
    // 更新添加按钮状态
    func updateAddBtnState() {
//        if codeTextField.stringValue == "" || wordTextField.stringValue == "" {
//             btnAdd.isEnabled = false
//        } else {
//             btnAdd.isEnabled = true
//        }
    }
    
    // 更新界面中的Label
    func updateLabels(){
        wordCountLabel.stringValue = "共\(dictionaries.count)条"
        selectedCountLabel.stringValue = "已选\(tableView.selectedRowIndexes.count)条"
    }
}

// MARK: - Table Datasource and Delegate
extension BuddyVC: NSTableViewDataSource, NSTableViewDelegate {
    // Table Datasource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dictionaries.count
    }
    
    //Table Delegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CellNormal"), owner: self) as? NSTableCellView{
            switch tableColumn {
            case tableView.tableColumns[0]:
                cell.textField?.stringValue = dictionaries[row].code
            case tableView.tableColumns[1]:
                cell.textField?.stringValue = dictionaries[row].word
            default: break
            }
            return cell
        } else {
            return nil
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateDeleteBtnState()
        updateLabels()
    }
}

extension BuddyVC: NSControlTextEditingDelegate{
    func controlTextDidChange(_ obj: Notification) {
        print(obj.description)
        print("text did change")
    }
}
