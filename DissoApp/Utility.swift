//
//  Utility.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 15/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import Foundation
// Utility.swift
class Utility {
    static    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let empty = [Int](repeating:0, count: s2.count)
        var last = [Int](0...s2.count)

        for (i, char1) in s1.enumerated() {
            var cur = [i + 1] + empty
            for (j, char2) in s2.enumerated() {
                cur[j + 1] = char1 == char2 ? last[j] : Swift.min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last!
    }
}
