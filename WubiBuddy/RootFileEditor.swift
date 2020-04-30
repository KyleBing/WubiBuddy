//
//  RootFileEditor.swift
//  WubiBuddy
//
//  Created by Kyle on 2020/4/29.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Cocoa
import UserNotifications


class RootFileEditor: NSViewController {
    // MARK: - Outlet and Methods
    // Storyboard
    @IBOutlet weak var codeTextField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var wordCountLabel: NSTextField!
    @IBOutlet weak var selectedCountLabel: NSTextField!
    @IBOutlet weak var btnDelete: NSButton!
    
    // MARK: - Variables
    
    var headerMainFile = ""                     // 主配置字典头部
    var headerRootFile = ""                     // 根字典头部

    var substringInvalid: [String] = []         // 词组 - 不规范
    var mainDictionaries: [Phrase] = []         // 词组 - 主配置字典
    var searchDictionies: [Phrase] = [] {       // 词组 - 搜索词条
        didSet {
            tableView.reloadData()
            updateLabels()
            updateButtonState()
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction func deleteWord(_ sender: NSButton) {
        var selectedItems :[Phrase] = []
        for itemIndex in tableView.selectedRowIndexes {
            selectedItems.append(searchDictionies[itemIndex])
        }
        
        selectedItems.forEach { (item) in
            if let index = mainDictionaries.firstIndex(where: {$0 == item}){
                mainDictionaries.remove(at: index)
            }
        }
        searchDictionies = mainDictionaries
        writeMainFile()
    }
    
    @IBAction func searchBtnPressed(_ sender: NSButton) {
        searchPhrases()
    }
    
//    @IBAction func sortDictionaries(_ sender: Any) {
//        mainDictionaries.sort(by: {$0.code < $1.code})
//        searchDictionies = mainDictionaries
//        writeMainFile()
//    }
    
    @IBAction func reloadFileContent(_ sender: Any) {
        mainDictionaries = []
        loadMainFileContent()
        validateInvalidSubstringExsit()
        updateLabels()
        updateButtonState()
    }
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = FilePath.rootFileURL.path
        tableView.dataSource = self
        tableView.delegate = self
        codeTextField.delegate = self
        
        
        tableView.allowsMultipleSelection = true
        updateButtonState()
        loadMainFileContent()
        updateLabels()
    }
    
    override func viewWillAppear() {
        // set window name
        view.window?.title = String(FilePath.rootFileURL.path.split(separator: "/").last!)
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
            try _ = FileManager.default.replaceItemAt(FilePath.rootFileURL, withItemAt: FilePath.mainTempFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly)
        } catch {
            print("replace file fail")
        }
    }
    
    // 载入文件内容
    func loadMainFileContent() {
        if let fileContent = try? String(contentsOf: FilePath.rootFileURL, encoding: .utf8) {
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
            searchDictionies = mainDictionaries
        } else {
            let alert = NSAlert()
            alert.messageText = "缺少: \(FilePath.rootFileURL.lastPathComponent) "
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
                        self.searchDictionies = self.mainDictionaries
                        self.writeMainFile()
                    case 1001: // 添加到桌面文件
                        var output = """
                                    # 原文件路径：\(FilePath.rootFileURL.path)
                                    # 这些是配置文件中格式不正确的词条：\n\n
                                    """ // 插入头部
                        for item in self.substringInvalid {
                            output.append("\(item)\n")
                        }
                        FileManager.default.createFile(atPath: FilePath.rootInvalidTempFileURL.path, contents: output.data(using: .utf8), attributes: nil)
                        do {
                            try _ = FileManager.default.replaceItemAt(FilePath.rootInvalidFileURL, withItemAt: FilePath.rootInvalidTempFileURL, backupItemName: backupFileName, options: .usingNewMetadataOnly)
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
    
    // 更新删除按钮状态
    func updateButtonState() {
        btnDelete.isEnabled = tableView.selectedRowIndexes.count > 0
    }
    
    // 更新界面中的Label
    func updateLabels(){
        let formatStringWordCount = NSLocalizedString("共 %d 条", comment: "总共多少条的输出字符串")
        wordCountLabel.stringValue = String.localizedStringWithFormat(formatStringWordCount, mainDictionaries.count)
        let formatStringSelectionCount = NSLocalizedString("已选 %d 条", comment: "选择多少条")
        selectedCountLabel.stringValue = String.localizedStringWithFormat(formatStringSelectionCount, tableView.selectedRowIndexes.count)
    }
    
    
    // 搜索筛选词条
    func searchPhrases(){
        let code = codeTextField.stringValue
        searchDictionies =  mainDictionaries.filter { (item) -> Bool in
            do {
                let regCode = try NSRegularExpression(pattern: "^\(code)\\w*$", options: .useUnicodeWordBoundaries)
                let strRangeMax = NSMakeRange(0, item.code.count)
                let serachResults = regCode.matches(in: item.code, options: [], range: strRangeMax)
                return serachResults.count > 0
            } catch {
                print("search reg code error")
                return false
            }
        }
    }
    
    // EOF: Editor
    
    
}



// MARK: - Table Datasource and Delegate

extension RootFileEditor: NSTableViewDataSource, NSTableViewDelegate {
    // Table Datasource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return searchDictionies.count
    }
    
    //Table Delegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CellNormal"), owner: self) as? NSTableCellView{
            switch tableColumn {
            case tableView.tableColumns[0]:
                cell.textField?.stringValue = searchDictionies[row].code
            case tableView.tableColumns[1]:
                cell.textField?.stringValue = searchDictionies[row].word
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

extension RootFileEditor: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        // 当检测到按键是 Enter 回车键时，对应的其它按键可以去 NSResponder 中查看
        case #selector(NSResponder.insertNewline(_:)):
            searchPhrases()
            return true
        default:
            return false
        }
    }
}


extension RootFileEditor: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let application = NSApplication.shared
        application.stopModal()
        return true
    }
}
