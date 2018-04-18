//
//  customButtonIbDesignable.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 9/14/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import Foundation

// Creates a custom button with gradient background and borders
@IBDesignable class CustomButtonIbDesignable: UIButton {
    
    // MARK: - Global Constatnts
    // ------------------------------------------------------------------------------------------------------------------------------
    private let gradientLayer = CAGradientLayer()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBInspectables
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBInspectable var firstColor: UIColor = UIColor.clear {
        didSet {
            
            setupView()
        }
    }
    
    @IBInspectable var secondColor: UIColor = UIColor.clear {
        didSet {
            
            setupView()
        }
    }
    
    @IBInspectable var thirdColor: UIColor = UIColor.clear {
        didSet {
            
            setupView()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            setupView()
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Allows us to set the gradient background programmatically
    func setGradientBackground(firstColor: UIColor, secondColor: UIColor, thirdColor: UIColor) {
        self.firstColor = firstColor
        self.secondColor = secondColor
        self.thirdColor = thirdColor
        
        setupView()
    }
    
    
    func setupView() {
        self.layer.cornerRadius = self.cornerRadius
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.cgColor
        self.clipsToBounds = true
        
        self.contentEdgeInsets = UIEdgeInsetsMake(borderWidth,borderWidth,borderWidth,borderWidth)
        
        gradientLayer.frame = bounds
        gradientLayer.colors = [firstColor.cgColor, secondColor.cgColor, thirdColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y:0.0)
        gradientLayer.endPoint = CGPoint(x:1.0, y: 0.0)
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // ------------------------------------------------------------------------------------------------------------------------------
}
