//
//  NavigationBarIBDesignable.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/11/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit

class NavigationBarIBDesignable: UIView {
    var contentView: UIView?
    
    // MARK: - IBInspectables
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBInspectable var firstColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var secondColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var thirdColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateView()
    }
    
    func updateView() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "Hello", bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    
    
    
    
    
    
    
    
    
    
}
