//
//  Phrase.swift
//  码表助手
//
//  Created by Kyle on 2020/4/26.
//  Copyright © 2020 Cyan Maple. All rights reserved.
//

import Foundation
struct Phrase {
    var code: String
    var word: String
    
    static func == (lhs: Phrase, rhs: Phrase) -> Bool {
        return lhs.code == rhs.code && lhs.word == rhs.word
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(word)
    }
}
