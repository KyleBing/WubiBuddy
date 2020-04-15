//
//  BuddyVC.swift
//  WubiBuddy
//
//  Created by Kyle on 2020/4/1.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Cocoa

class BuddyVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    dynamic var newCode: String = "ggtt"
    dynamic var newWord: String = "五笔"
    
    @IBOutlet weak var codeTextField: NSTextField!
    @IBOutlet weak var wordTextField: NSTextField!
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var wordCountLabel: NSTextField!
    
    @IBAction func addWord(_ sender: NSButton) {
        let code = codeTextField.stringValue
        let word = wordTextField.stringValue
        if code.count == 0 || word.count == 0{
            // alert
        } else {
            dictionaries.append((key: code, value: word))
            tableView.reloadData()
            wordCountLabel.stringValue = String(dictionaries.count)
            createFile()
        }
    }
    var demoURL:URL{
        let fileName = "wubi86_jidian_extra_pro.dict.yaml"
//        let fileName = "/Users/Kyle/Desktop/Rime.txt"
        let filePath = "Library/Rime/" + fileName
        let pathHome = FileManager.default.homeDirectoryForCurrentUser
        let userDictUrl = pathHome.appendingPathComponent(filePath)
        return userDictUrl
    }
    var substrings:[String] = []
    var dictionaries: [(key:String, value:String)] = []
    var fileHeader:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = demoURL.path
        tableView.dataSource = self
        tableView.delegate = self
        loadContent()
        tableView.reloadData()
    }
    
    override func viewWillAppear() {
        // set window name
        view.window?.title = String(demoURL.path.split(separator: "/").last!)
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    
    // MARK: - User methods
    // 创建文件
    func createFile() {
        var output = fileHeader + "\n...\n" // 插入头部
        for item in dictionaries{
            output = output + "\(item.key)\t\(item.value)" + "\n"
        }
        let fileManager = FileManager.default
        fileManager.createFile(atPath:"/Users/Kyle/Desktop/Rime.txt", contents: output.data(using: .utf8), attributes: nil)
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
                dictionaries.append(( String(tempSubstring[1]), String(tempSubstring[0])))
            }
            wordCountLabel.stringValue = "共\(dictionaries.count)条"
        } else {
            // alert hasn't install github libray
        }
    }
    
    // MARK: - Table Datasource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dictionaries.count
    }
    
    
    // MARK: - Table Delegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CellNormal"), owner: self) as? NSTableCellView{
            switch tableColumn {
            case tableView.tableColumns[0]:
                cell.textField?.stringValue = dictionaries[row].key
            case tableView.tableColumns[1]:
                cell.textField?.stringValue = dictionaries[row].value
            default: break
            }
            return cell
        } else {
            return nil
        }
    }
}

