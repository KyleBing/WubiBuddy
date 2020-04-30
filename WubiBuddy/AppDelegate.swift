//
//  AppDelegate.swift
//  WubiBuddy
//
//  Created by Kyle on 2020/4/1.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Cocoa
import NotificationCenter

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // 关闭窗口时退出程序
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    


}

