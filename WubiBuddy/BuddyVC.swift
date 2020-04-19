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
    
    // CONST Values
    let IS_TEST_MODE = false
    let tempFileName = "WubiBuddy-Temp.wubibuddy"
    let backupFileName = "WubiBuddy-Backup.wubibuddy"

    // MARK: - Outlet and Methods
    // Storyboard
    @IBOutlet weak var codeTextField: NSTextField!
    @IBOutlet weak var wordTextField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var wordCountLabel: NSTextField!
    @IBOutlet weak var selectedCountLabel: NSTextField!
    @IBOutlet weak var btnDelete: NSButton!
    @IBOutlet weak var btnAdd: NSButton!
    
    @IBAction func deleteWord(_ sender: NSButton) {
        tableView.selectedRowIndexes.forEach { (indexSet) in
            dictionaries.remove(at: indexSet)
        }
        tableView.reloadData()
        updateLabels()
        updateDeleteBtnState()
        writeFile()
    }
    @IBAction func addWord(_ sender: NSButton) {
        let code = codeTextField.stringValue.trimmingCharacters(in: .whitespaces)
        let word = wordTextField.stringValue
        if code.count == 0 || word.count == 0{
            codeTextField.becomeFirstResponder()
        } else {
            dictionaries.append((code: code, word: word))
            // 重置输入区
            codeTextField.stringValue = ""
            wordTextField.stringValue = ""
            codeTextField.becomeFirstResponder()
            
            tableView.reloadData()
            updateLabels()
            writeFile()
        }
    }
    
    @IBAction func reloadFileContent(_ sender: Any) {
        dictionaries = []
        loadContent()
        validateInvalidSubstringExsit()
        tableView.reloadData()
        updateLabels()
        updateDeleteBtnState()
    }
    
    
    let TextDidChangeNotification = Notification(name: Notification.Name.init("TextDidChange"))
    
    // MARK: - Variables
    var mainFileURL:URL{
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
    var dictionaries: [(code:String, word: String)] = [] {
        didSet{
            dictionaries.sort(by: <)
        }
    }
    var fileHeader:String = ""

    var substringInvalid: [String] = []
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = mainFileURL.path
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
        view.window?.title = String(mainFileURL.path.split(separator: "/").last!)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        validateInvalidSubstringExsit()
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
        var newFileURL = mainFileURL
        newFileURL.deleteLastPathComponent()
        newFileURL = newFileURL.appendingPathComponent(tempFileName)
        FileManager.default.createFile(atPath:newFileURL.path, contents: output.data(using: .utf8), attributes: nil)
        do {
            try _ = FileManager.default.replaceItemAt(mainFileURL, withItemAt: newFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly)
        } catch {
            print("replace file fail")
        }
    }
    
    // 载入文件内容
    func loadContent() {
        if let fileContent = try? String(contentsOf: mainFileURL, encoding: .utf8) {
            // 根据 ... 的位置获取文件头部
            let nsFileContent = NSString(string: fileContent)
            
            let headerRange = nsFileContent.range(of: "...")
            // 如果文件中缺少 ... 这行，退出
            if headerRange.length == 0 {
                let alert = NSAlert()
                alert.messageText = "文件中缺少必要分隔行"
                alert.informativeText = """
                                        请确保文件中存在 【 ... 】 三个点这一行
                                        请手动添加，再打开程序重试
                                        点击确定退出程序
                                        """
                alert.runModal()
                exit(0)
            }
            fileHeader = nsFileContent.substring(to: headerRange.lowerBound)
            let fileContent = nsFileContent.substring(from: headerRange.upperBound)
            
            let tempStrings = fileContent.split(separator: "\n")
            let substringAll = tempStrings.map {String($0)}
            let substringValid = substringAll.filter {$0.contains("\t")}
            substringInvalid = substringAll.filter {!$0.contains("\t") && NSPredicate(format: "SELF MATCHES %@", "^\\w+? {0,10}.+?$").evaluate(with: $0)}

            for str in substringValid {
                let tempSubstring = str.split(separator: "\t")
                dictionaries.append((code: String(tempSubstring[1]), word: String(tempSubstring[0])))
            }
            wordCountLabel.stringValue = "共\(dictionaries.count)条"
        } else {
            print("FileManager: get 'wubi_jidian_addition.dict.yaml' file content fail")
        }
    }
    
    // 不规范词条操作
    func validateInvalidSubstringExsit(){
        // if invalid string exsit: alert about it
        if !substringInvalid.isEmpty {
            var invalidStringCombine = ""
            for item in substringInvalid {
                invalidStringCombine = invalidStringCombine + (item + "\n")
            }
            let userInfo = [NSLocalizedDescriptionKey: "存在不规范词条"]
            let error =  NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: userInfo)
            let alert = NSAlert(error: error)
            alert.messageText = "存在不规范词条，添加到词库中？"
            alert.informativeText = """
                                    【 添加 】：保存到当前词库中
                                    【 取消 】：保存在桌面“Rime不规范的词条.txt”文件中
                                    -----------------------------\n
                                    \(invalidStringCombine)
                                    -----------------------------
                                    """
            alert.addButton(withTitle: "添加")
            alert.addButton(withTitle: "取消")

            if let window = view.window {
                alert.beginSheetModal(for: window) {[unowned self] (response) in
                    switch response.rawValue {
                    case 1000: // 添加到词库
                        for item in self.substringInvalid {
                            do {
                                let regWord = try NSRegularExpression(pattern: "^\\w+(?=\\s+)", options: .useUnicodeWordBoundaries)
                                let regCode = try NSRegularExpression(pattern: "(?<=\\s)[a-zA-Z]+$", options: .useUnicodeWordBoundaries)
                                
                                let strRangeMax = NSMakeRange(0, item.count)
                                if let codeMatch = regCode.firstMatch(in: item, options: .reportCompletion, range: strRangeMax),
                                    let wordMatch = regWord.firstMatch(in: item, options: .reportCompletion, range: strRangeMax){
                                    let codeString = NSString(string: item).substring(with: codeMatch.range)
                                    let wordString = NSString(string: item).substring(with: wordMatch.range)
                                    self.dictionaries.append((code: codeString, word: wordString))
                                }
                            } catch {
                                print("Init regular expression fail")
                            }
                        }
                        self.tableView.reloadData()
                        self.writeFile()
                    case 1001: // 添加到桌面文件
                        var output = """
                                    # 原文件路径：\(self.mainFileURL.path)
                                    # 这些是配置文件中格式不正确的词条：\n\n
                                    """ // 插入头部
                        for item in self.substringInvalid {
                            output = output + item + "\n"
                        }
                        let fileName = "Rime不规范的词条.txt"
                        let filePath = "Desktop/" + fileName
                        let pathHome = FileManager.default.homeDirectoryForCurrentUser
                        let invalidWordsFileURL = pathHome.appendingPathComponent(filePath)
                        var newFileURL = invalidWordsFileURL
                        newFileURL.deleteLastPathComponent()
                        newFileURL = newFileURL.appendingPathComponent(self.tempFileName)
                        FileManager.default.createFile(atPath:newFileURL.path, contents: output.data(using: .utf8), attributes: nil)
                        do {
                            try _ = FileManager.default.replaceItemAt(invalidWordsFileURL, withItemAt: newFileURL, backupItemName: self.backupFileName, options: .usingNewMetadataOnly)
                        } catch {
                            print("FileManager: replace invalid words file fail")
                        }
                        self.writeFile()
                    default: break
                    }
                }
            }
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
