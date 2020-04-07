//
//  ViewController.swift
//  WubiBuddy
//
//  Created by Kyle on 2020/4/1.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var demoURL:URL{
        let userDictPath = "Library/Rime/wubi86_jidian_user.dict.yaml"
        let pathHome = FileManager.default.homeDirectoryForCurrentUser
        let userDictUrl = pathHome.appendingPathComponent(userDictPath)
        return userDictUrl
    }
    var substrings:[String] = []
    var dictionaries: [(key:String, value:String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = demoURL.path
        tableView.dataSource = self
        tableView.delegate = self
        loadContent()
        tableView.reloadData()
        createFile()
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    // MARK: - User methods
    // 创建文件
    func createFile() {
        var output = ""
        for str in substrings{
            output = output + str + "\n"
        }
        let fileManager = FileManager.default
        fileManager.createFile(atPath:"/Users/Kyle/Desktop/xcode-test/test.txt", contents: output.data(using: .utf8), attributes: nil)
    }
    
    // 载入文件内容
    func loadContent() {
        if let fileContent = try? String(contentsOf: demoURL, encoding: .utf8) {
            let tempStrings = fileContent.split(separator: "\n")
            substrings = tempStrings.map {String($0)}
            substrings = substrings.filter {$0.contains("\t")}
        
            for str in substrings {
                let tempSubstring = str.split(separator: "\t")
                dictionaries.append(( String(tempSubstring[1]), String(tempSubstring[0])))
            }
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

