//
//  FilePath.swift
//  码表助手
//
//  Created by Kyle on 2020/4/30.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Cocoa

//public let IS_TEST_MODE = true
public let IS_TEST_MODE = false

public let tempFileName = "WubiBuddy-Temp.wubibuddy"
public let backupFileName = "WubiBuddy-Backup.wubibuddy"


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
    
    // file that this app operate on
    public static var mainFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent("Rime.txt") : FilePath.rime.appendingPathComponent("wubi86_jidian_addition.dict.yaml")
    }
    public static var mainTempFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent(tempFileName) : FilePath.rime.appendingPathComponent(tempFileName)
    }
    
    // root dict.yaml file
    public static var rootFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent("Source.txt") : FilePath.rime.appendingPathComponent("wubi86_jidian.dict.yaml")
    }
    public static var rootTempFileURL:URL{
        return IS_TEST_MODE ? FilePath.desktop.appendingPathComponent(tempFileName) : FilePath.rime.appendingPathComponent(tempFileName)
    }
    
    // main invalid words output file
    public static var mainInvalidFileURL:URL{
        return FilePath.desktop.appendingPathComponent("鼠须管不规范的词条.txt")
    }
    public static var mainInvalidTempFileURL:URL{
        return FilePath.desktop.appendingPathComponent(tempFileName)
    }
    
    // root invalid words output file
    public static var rootInvalidFileURL:URL{
        return FilePath.desktop.appendingPathComponent("鼠须管(主码表)不规范的词条.txt")
    }
    public static var rootInvalidTempFileURL:URL{
        return FilePath.desktop.appendingPathComponent(tempFileName)
    }
    
}
