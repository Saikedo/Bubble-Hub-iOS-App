//
//  Data.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/9/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit

//Extends Data. Used in String extension to allow us to convert HTML text to String
extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}
