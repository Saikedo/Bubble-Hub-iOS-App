//
//  GradientViewIBDesignable.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 10/5/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//


import UIKit

// Creates a Gradient IBDesignable. Used for backgrounds.
@IBDesignable class GradientViewIBDesignable: UIView {
    
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
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override class var layerClass: AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------

    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    func updateView(){
        let layer = self.layer as! CAGradientLayer
        layer.colors = [firstColor.cgColor, secondColor.cgColor, thirdColor.cgColor]
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}

