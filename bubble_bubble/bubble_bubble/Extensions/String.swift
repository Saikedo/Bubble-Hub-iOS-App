//
//  String.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/9/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit

// Extends String to allow us to convert HTML text to String
extension String {
    
    // MARK: - Global Variables
    // ------------------------------------------------------------------------------------------------------------------------------
    var html2AttributedString: NSAttributedString? {
        return Data(utf8).html2AttributedString
    }
    
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
