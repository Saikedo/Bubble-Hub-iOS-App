//
//  CustomCell.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 8/27/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit

// Provides a custom cell for listView on HomeScreen
class CustomCell: UITableViewCell {

    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var tableViewImage: UIImageView!
    @IBOutlet var tableViewText: UILabel!
    // ------------------------------------------------------------------------------------------------------------------------------
    
   
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func awakeFromNib() {
        super.awakeFromNib()
        tableViewText.textColor = UIColor.white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
