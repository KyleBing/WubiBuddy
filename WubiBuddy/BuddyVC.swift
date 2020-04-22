//
//  BuddyVC.swift
//  WubiBuddy
//
//  Created by Kyle on 2020/4/1.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Cocoa
import UserNotifications

struct FilePath {
    public static var desktop: URL{
        let pathHome = FileManager.default.homeDirectoryForCurrentUser
        let filePath = pathHome.appendingPathComponent("Desktop/")
        return filePath
    }
    public static var rime: URL{
        let pathHome = FileManager.default.homeDirectoryForCurrentUser
        let filePath = pathHome.appendingPathComponent("Library/Rime/")
        return filePath
    }
}

class BuddyVC: NSViewController {
    
    // CONST Values
    let IS_TEST_MODE = true
    
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
    
    // MARK: - Variables
    
    // file that this app operate on
    var mainFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent("Rime.txt") : FilePath.rime.appendingPathComponent("wubi86_jidian_addition.dict.yaml")
    }
    var mainTempFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent(tempFileName) : FilePath.rime.appendingPathComponent(tempFileName)
    }
    
    // root dict.yaml file
    var rootFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent("Source.txt") : FilePath.rime.appendingPathComponent("wubi86_jidian.dict.yaml")
    }
    var rootTempFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent(tempFileName) : FilePath.rime.appendingPathComponent(tempFileName)
    }
    
    // invalid words output file
    var invalidFileURL:URL{
        return FilePath.desktop.appendingPathComponent("Rime不规范的词条.txt")
    }
    var invalidTempFileURL:URL{
        return FilePath.desktop.appendingPathComponent(tempFileName)
    }
    
    
    var headerMainFile = ""                                     // 主配置字典头部
    var headerRootFile = ""                                     // 根字典头部

    var substringInvalid: [String] = []                         // 词组 - 不规范
    var dictionaries: [(code:String, word: String)] = []        // 词组 - 主配置字典
    var rootDictionaries: [(code: String, word: String)] = []   // 词组 - 根文件
    
    
    // MARK: - IBActions
    
    @IBAction func deleteWord(_ sender: NSButton) {
        var selectedItems :[(code: String, word: String)] = []
        
        for itemIndex in tableView.selectedRowIndexes {
            selectedItems.append(dictionaries[itemIndex])
        }
        
        selectedItems.forEach { (item) in
            if let index = dictionaries.firstIndex(where: {$0 == item}){
                dictionaries.remove(at: index)
            }
        }
        tableView.reloadData()
        updateLabels()
        updateDeleteBtnState()
        writeMainFile()
    }
    
    @IBAction func addBtnPressed(_ sender: NSButton) {
        addWord()
    }
    
    @IBAction func sortDictionaries(_ sender: Any) {
        dictionaries.sort(by: {$0.code < $1.code})
        tableView.reloadData()
        writeMainFile()
    }
    
    @IBAction func reloadFileContent(_ sender: Any) {
        dictionaries = []
        loadContent()
        validateInvalidSubstringExsit()
        tableView.reloadData()
        updateLabels()
        updateDeleteBtnState()
    }
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = mainFileURL.path
        tableView.dataSource = self
        tableView.delegate = self
        codeTextField.delegate = self
        wordTextField.delegate = self
        
        tableView.allowsMultipleSelection = true
        updateDeleteBtnState()
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
    

    override var representedObject: Any? {didSet {}}

    
    
    // MARK: - User methods
    
    // 创建文件
    func writeMainFile() {
        var output = headerMainFile + "...\n\n" // 插入头部
        for item in dictionaries{
            output = output + "\(item.word)\t\(item.code)\n"
        }
        FileManager.default.createFile(atPath: mainTempFileURL.path, contents: output.data(using: .utf8), attributes: nil)
        do {
            try _ = FileManager.default.replaceItemAt(mainFileURL, withItemAt: mainTempFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly)
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
            headerMainFile = nsFileContent.substring(to: headerRange.lowerBound)
            let fileContent = nsFileContent.substring(from: headerRange.upperBound)
            
            let tempStrings = fileContent.split(separator: "\n")
            let substringAll = tempStrings.map {String($0)}
            let substringValid = substringAll.filter {$0.contains("\t")}
            substringInvalid = substringAll.filter {!$0.contains("\t") && NSPredicate(format: "SELF MATCHES %@", "^\\w+? {0,10}.+?$").evaluate(with: $0)}

            for str in substringValid {
                let tempSubstring = str.split(separator: "\t")
                dictionaries.append((code: String(tempSubstring[1]), word: String(tempSubstring[0])))
            }
            
        } else {
            let alert = NSAlert()
            alert.messageText = "缺少: \(mainFileURL.lastPathComponent) "
            alert.informativeText = "请前往 https://github.com/KyleBing/rime-wubi86-jidian 下载最新配置文件，再重试"
            alert.runModal()
            exit(0)
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
                        self.writeMainFile()
                    case 1001: // 添加到桌面文件
                        var output = """
                                    # 原文件路径：\(self.mainFileURL.path)
                                    # 这些是配置文件中格式不正确的词条：\n\n
                                    """ // 插入头部
                        for item in self.substringInvalid {
                            output = output + item + "\n"
                        }
                        FileManager.default.createFile(atPath: self.invalidTempFileURL.path, contents: output.data(using: .utf8), attributes: nil)
                        do {
                            try _ = FileManager.default.replaceItemAt(self.invalidFileURL, withItemAt: self.invalidTempFileURL, backupItemName: self.backupFileName, options: .usingNewMetadataOnly)
                        } catch {
                            print("FileManager: replace invalid words file fail")
                        }
                        self.writeMainFile()
                    default: break
                    }
                }
            }
        }
    }
    
    // 添加用户词
    func addWord(){
        let code = codeTextField.stringValue.trimmingCharacters(in: .whitespaces)
        let word = wordTextField.stringValue
        if code.count == 0 {
            codeTextField.becomeFirstResponder()
        } else if word.count == 0 {
            wordTextField.becomeFirstResponder()
        } else {
            dictionaries.append((code: code, word: word))
            // 重置输入区
            codeTextField.stringValue = ""
            wordTextField.stringValue = ""
            codeTextField.becomeFirstResponder()
            
            tableView.reloadData()
            updateLabels()
            writeMainFile()
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
    
    // 更新界面中的Label
    func updateLabels(){
        let formatStringWordCount = NSLocalizedString("共 %d 条", comment: "总共多少条的输出字符串")
        wordCountLabel.stringValue = String.localizedStringWithFormat(formatStringWordCount, dictionaries.count)
        let formatStringSelectionCount = NSLocalizedString("已选 %d 条", comment: "选择多少条")
        selectedCountLabel.stringValue = String.localizedStringWithFormat(formatStringSelectionCount, tableView.selectedRowIndexes.count)
    }
    
    

    // 将选中的词条插入到根字典文件中
    @IBAction func insertIntoRootFile(_ sender: Any){
        if let fileContent = try? String(contentsOf: rootFileURL, encoding: .utf8) {
            // 1. get header
            let nsFileContent = NSString(string: fileContent)
            
            let headerRange = nsFileContent.range(of: "...")
            // 2. if lack of "..."line, exit(0)
            if headerRange.length == 0 {
                let alert = NSAlert()
                alert.messageText = "文件中缺少必要分隔行"
                alert.informativeText = """
                \(rootFileURL.path)
                请确保文件中存在 【 ... 】 三个点这一行
                请手动添加，再打开程序重试
                点击确定退出程序
                """
                alert.runModal()
                exit(0)
            }
            headerRootFile = nsFileContent.substring(to: headerRange.lowerBound)
            let fileContent = nsFileContent.substring(from: headerRange.upperBound)
            
            let tempStrings = fileContent.split(separator: "\n")
            let substringAll = tempStrings.map {String($0)}
            let substringValid = substringAll.filter {$0.contains("\t")}
//            substringInvalid = substringAll.filter {!$0.contains("\t") && NSPredicate(format: "SELF MATCHES %@", "^\\w+? {0,10}.+?$").evaluate(with: $0)}
            
            for str in substringValid {
                let tempSubstring = str.split(separator: "\t")
                rootDictionaries.append((code: String(tempSubstring[1]), word: String(tempSubstring[0])))
            }
        } else {
            let alert = NSAlert()
            alert.messageText = "缺少: \(mainFileURL.lastPathComponent) "
            alert.informativeText = "请前往 https://github.com/KyleBing/rime-wubi86-jidian 下载最新配置文件，再重试"
            alert.runModal()
            exit(0)
        }
        
        
        // 3. locate and insert to sourceDic
        for itemIndex in tableView.selectedRowIndexes {
            let currentItem = dictionaries[itemIndex]
            if let index = rootDictionaries.firstIndex(where: {$0.code > currentItem.code}) {
                print(index)
                rootDictionaries.insert(currentItem, at: index)
            }
        }

        // 4. generate output string
        var output = headerRootFile + "...\n\n"
        rootDictionaries.forEach({output = output + "\($0.word)\t\($0.code)\n"})

        // 5. write to new temp file
        FileManager.default.createFile(atPath: rootTempFileURL.path, contents: output.data(using: .utf8), attributes: nil)

        // 6. replace source file with temp file
        do {
            if let _ = try FileManager.default.replaceItemAt(rootFileURL, withItemAt: rootTempFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly) {
                deleteWord(NSButton()) // 7. if successfully save root file delete selected items
            }
        } catch {
            print("replace file:\(rootFileURL.path) fail")
        }
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


// MARK: - Keyboard Event

extension BuddyVC: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        // 当检测到按键是 Enter 回车键时，对应的其它按键可以去 NSResponder 中查看
        case #selector(NSResponder.insertNewline(_:)):
            if let inputView =  control as? NSTextField {
                if inputView == codeTextField {
                    wordTextField.becomeFirstResponder()    // 光标移动到用户词输入框
                } else {
                    addWord()                               // 去执行添加用户词的方法
                }
            }
            return true
        default:
            return false
        }
    }
}
