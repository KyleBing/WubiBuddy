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
    // MARK: - Outlet and Methods
    // Storyboard
    @IBOutlet weak var codeTextField: NSTextField!
    @IBOutlet weak var wordTextField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var wordCountLabel: NSTextField!
    @IBOutlet weak var selectedCountLabel: NSTextField!
    @IBOutlet weak var btnDelete: NSButton!
    @IBOutlet weak var btnInsert: NSButton!
    @IBOutlet weak var btnAdd: NSButton!
    
    // MARK: - Variables
    var headerMainFile = ""                     // 主配置字典头部
    var headerRootFile = ""                     // 根字典头部

    var substringInvalid: [String] = []         // 词组 - 不规范
    var mainDictionaries: [Phrase] = [] {       // 词组 - 主配置字典
        didSet {
            tableView.reloadData()
            updateLabels()
            updateButtonState()
        }
    }
    var rootDictionaries: [Phrase] = []         // 词组 - 根文件
    
    
    // MARK: - IBActions
    
    @IBAction func deleteWord(_ sender: NSButton) {
        var selectedItems :[Phrase] = []
        
        for itemIndex in tableView.selectedRowIndexes {
            selectedItems.append(mainDictionaries[itemIndex])
        }
        
        selectedItems.forEach { (item) in
            if let index = mainDictionaries.firstIndex(where: {$0 == item}){
                mainDictionaries.remove(at: index)
            }
        }
        writeMainFile()
    }
    
    @IBAction func addBtnPressed(_ sender: NSButton) {
        addWord()
    }
    
    @IBAction func sortDictionaries(_ sender: Any) {
        mainDictionaries.sort(by: {$0.code < $1.code})
        writeMainFile()
    }
    
    @IBAction func reloadFileContent(_ sender: Any) {
        mainDictionaries = []
        loadContent()
        validateInvalidSubstringExsit()
        updateButtonState()
    }
    
    @IBAction func showRootFileWindow(_ sender: AnyObject) {
      let storyboard = NSStoryboard(name: "Main", bundle: nil)
      let rootFileEditorWindowController = storyboard.instantiateController(withIdentifier: "RootEditorWindowController") as! NSWindowController
      
      if let rootFileEditorWindow = rootFileEditorWindowController.window{

        // 2
        let rootFileEditorVC = rootFileEditorWindow.contentViewController as! RootFileEditor
        rootFileEditorWindow.delegate = rootFileEditorVC
        
        // 3
        let application = NSApplication.shared
        application.runModal(for: rootFileEditorWindow)
        // 4
        rootFileEditorWindow.close()
      }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = FilePath.mainFileURL.path
        tableView.dataSource = self
        tableView.delegate = self
        codeTextField.delegate = self
        wordTextField.delegate = self
        
        tableView.allowsMultipleSelection = true
        loadContent()
        updateLabels()
    }
    
    override func viewWillAppear() {
        // set window name
        view.window?.title = String(FilePath.mainFileURL.path.split(separator: "/").last!)
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
        mainDictionaries.forEach { (item) in
            output.append("\(item.word)\t\(item.code)\n")
        }
        FileManager.default.createFile(atPath: FilePath.mainTempFileURL.path, contents: output.data(using: .utf8), attributes: nil)
        do {
            try _ = FileManager.default.replaceItemAt(FilePath.mainFileURL, withItemAt: FilePath.mainTempFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly)
        } catch {
            print("replace file fail")
        }
    }
    
    // 载入文件内容
    func loadContent() {
        if let fileContent = try? String(contentsOf: FilePath.mainFileURL, encoding: .utf8) {
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
            
            tempStrings.forEach { (item) in
                let current = String(item)
                // valid
                if current.contains("\t") && !current.contains("\t ") {
                    let tempSubstring = current.split(separator: "\t")
                    mainDictionaries.append(Phrase(code: String(tempSubstring[1]), word: String(tempSubstring[0])))
                }
                // invalid
                if !current.contains("\t") && NSPredicate(format: "SELF MATCHES %@", "^\\w+? {0,10}.+?$").evaluate(with: current) {
                    substringInvalid.append(current)
                }
            }

        } else {
            let alert = NSAlert()
            alert.messageText = "缺少: \(FilePath.mainFileURL.lastPathComponent) "
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
            for i in 0..<(substringInvalid.count<8 ? substringInvalid.count : 8) {
                invalidStringCombine.append("\(substringInvalid[i])\n")
            }
            let userInfo = [NSLocalizedDescriptionKey: "存在不规范词条"]
            let error =  NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: userInfo)
            let alert = NSAlert(error: error)
            alert.messageText = "存在不规范词条 \(substringInvalid.count) 条"
            alert.informativeText = """
                                    选择 [添加到词库]
                                    或者 [保存到文件]：
                                        ~/桌面/\(FilePath.rootInvalidFileURL.lastPathComponent)\n
                                    \(invalidStringCombine)
                                    """
            alert.addButton(withTitle: "添加到词库")
            alert.addButton(withTitle: "保存到文件")

            if let window = view.window {
                alert.beginSheetModal(for: window) {[unowned self] (response) in
                    switch response.rawValue {
                    case 1000: // 添加到词库
                        for item in self.substringInvalid {
                            do {
                                let regWord = try NSRegularExpression(pattern: "^.+(?=\\s[a-zA-Z]+$)", options: .useUnicodeWordBoundaries)
                                let regCode = try NSRegularExpression(pattern: "(?<=\\s)[a-zA-Z]+$", options: .useUnicodeWordBoundaries)
                                
                                let strRangeMax = NSMakeRange(0, item.count)
                                if let codeMatch = regCode.firstMatch(in: item, options: .reportCompletion, range: strRangeMax),
                                    let wordMatch = regWord.firstMatch(in: item, options: .reportCompletion, range: strRangeMax){
                                    let codeString = NSString(string: item).substring(with: codeMatch.range)
                                    let wordString = NSString(string: item).substring(with: wordMatch.range)
                                    self.mainDictionaries.append(Phrase(code: codeString, word: wordString))
                                    self.writeMainFile()
                                }
                            } catch {
                                print("Init regular expression fail")
                            }
                        }
                        self.writeMainFile()
                    case 1001: // 添加到桌面文件
                        var output = """
                                    # 原文件路径：\(FilePath.mainFileURL.path)
                                    # 这些是配置文件中格式不正确的词条，共\(self.substringInvalid.count)条：\n\n
                                    """ // 插入头部
                        self.substringInvalid.forEach { (item) in
                            output.append(item)
                        }
                        FileManager.default.createFile(atPath: FilePath.mainInvalidTempFileURL.path, contents: output.data(using: .utf8), attributes: nil)
                        do {
                            try _ = FileManager.default.replaceItemAt(FilePath.mainInvalidFileURL, withItemAt: FilePath.mainInvalidTempFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly)
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
            mainDictionaries.insert(Phrase(code: code, word: word), at: 0)
            // 重置输入区
            codeTextField.stringValue = ""
            wordTextField.stringValue = ""
            codeTextField.becomeFirstResponder()
            writeMainFile()
        }
    }
    
    // 更新删除按钮状态
    func updateButtonState() {
        if tableView.selectedRowIndexes.count > 0{
            btnDelete.isEnabled = true
            btnInsert.isEnabled = true
        } else {
            btnDelete.isEnabled = false
            btnInsert.isEnabled = false
        }
    }
    
    // 更新界面中的Label
    func updateLabels(){
        let formatStringWordCount = NSLocalizedString("共 %d 条", comment: "总共多少条的输出字符串")
        wordCountLabel.stringValue = String.localizedStringWithFormat(formatStringWordCount, mainDictionaries.count)
        let formatStringSelectionCount = NSLocalizedString("已选 %d 条", comment: "选择多少条")
        selectedCountLabel.stringValue = String.localizedStringWithFormat(formatStringSelectionCount, tableView.selectedRowIndexes.count)
    }
    
    
    // 将选中的词条插入到根字典文件中
    @IBAction func insertIntoRootFile(_ sender: Any){
        if rootDictionaries.count == 0 {
            if let fileContent = try? String(contentsOf: FilePath.rootFileURL, encoding: .utf8) {
                // 1. get header
                let nsFileContent = NSString(string: fileContent)
                
                let headerRange = nsFileContent.range(of: "...")
                // 2. if lack of "..."line, exit(0)
                if headerRange.length == 0 {
                    let alert = NSAlert()
                    alert.messageText = "文件中缺少必要分隔行"
                    alert.informativeText = """
                    \(FilePath.rootFileURL.path)
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
                
                tempStrings.forEach { (item) in
                    let current = String(item)
                    // valid
                    if current.contains("\t") && !current.contains("\t ") {
                        let tempSubstring = current.split(separator: "\t")
                        rootDictionaries.append(Phrase(code: String(tempSubstring[1]), word: String(tempSubstring[0])))
                    }
                    // invalid
                    // TODO: deal with invalid
                }
            } else {
                let alert = NSAlert()
                alert.messageText = "缺少: \(FilePath.mainFileURL.lastPathComponent) "
                alert.informativeText = "请前往 https://github.com/KyleBing/rime-wubi86-jidian 下载最新配置文件，再重试"
                alert.runModal()
                exit(0)
            }
        }
        
        
        
        // 3. locate and insert to sourceDic
        for itemIndex in tableView.selectedRowIndexes {
            let currentItem = mainDictionaries[itemIndex]
            if rootDictionaries.count == 0{
                rootDictionaries.append(currentItem)
                /// `$0.code > currentItem.code` 插入到找到的位置之后
                /// `$0.code >= currentItem.code` 插入到找到的位置之前
            } else if let index = rootDictionaries.firstIndex(where: { $0.code > currentItem.code }){
                print("\(currentItem.word): \(index)")
                rootDictionaries.insert(currentItem, at: index)
            } else {
                rootDictionaries.append(currentItem)
            }
        }

        // 4. generate output string
        var output = headerRootFile + "...\n\n"
        
        rootDictionaries.forEach {output.append("\($0.word)\t\($0.code)\n")}
        // 5. write to new temp file
        FileManager.default.createFile(atPath: FilePath.rootTempFileURL.path, contents: output.data(using: .utf8), attributes: nil)

        // 6. replace source file with temp file
        do {
            if let _ = try FileManager.default.replaceItemAt(FilePath.rootFileURL, withItemAt: FilePath.rootTempFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly) {
                deleteWord(NSButton()) // 7. if successfully save root file delete selected items
            }
        } catch {
            print("replace file:\(FilePath.rootFileURL.path) fail")
        }
    }
    
}



// MARK: - Table Datasource and Delegate

extension BuddyVC: NSTableViewDataSource, NSTableViewDelegate {
    // Table Datasource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return mainDictionaries.count
    }
    
    //Table Delegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CellNormal"), owner: self) as? NSTableCellView{
            switch tableColumn {
            case tableView.tableColumns[0]:
                cell.textField?.stringValue = mainDictionaries[row].code
            case tableView.tableColumns[1]:
                cell.textField?.stringValue = mainDictionaries[row].word
            default: break
            }
            return cell
        } else {
            return nil
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtonState()
        updateLabels()
    }
}


// MARK: - Keyboard Event

extension BuddyVC: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        // 当检测到按键是 Enter 回车键时，对应的其它按键可以去 NSResponder 中查看
        case #selector(NSResponder.insertNewline(_:)):
            addWord()                               // 去执行添加用户词的方法
            return true
        default:
            return false
        }
    }
}
