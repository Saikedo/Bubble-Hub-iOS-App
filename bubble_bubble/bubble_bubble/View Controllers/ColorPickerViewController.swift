//
//  ColorPickerViewController.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 10/15/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit

// MARK: - Protocols
// ------------------------------------------------------------------------------------------------------------------------------

// Used to send rgb color data to other ViewControllers
protocol ReceiveHueAndRGBColorDelegate{
    func receiveHueAndRGBColor(rgb: Int)
}
// ------------------------------------------------------------------------------------------------------------------------------

// Handles the displaying of custom color picker UIView and forwards color data from ColorPicker to other classes.
class ColorPickerViewController: UIViewController, ReceiveHueColorDelegate {

    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    private var receiveHueAndRGBColorDelegate: ReceiveHueAndRGBColorDelegate?
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var colorPicker: ColorPicker!
    @IBOutlet var button_close: CustomButtonIbDesignable!
    @IBOutlet var currentColorShowerView: UIView!
    @IBOutlet var colorPickerContainer: UIView!
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBActions
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBAction func button_close(_ sender: Any) {
        self.view.removeFromSuperview()
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        colorPickerContainer.layer.cornerRadius = 5
        colorPickerContainer.layer.borderWidth = 5
        colorPickerContainer.layer.borderColor = GlobalColors.black.cgColor
        colorPicker.setReceiveHueColorDelegate(incomingDelegate: self)
        
        currentColorShowerView.layer.cornerRadius = 5
        currentColorShowerView.layer.borderWidth = 5
        currentColorShowerView.layer.borderColor = GlobalColors.black.cgColor
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Delegate protocol methods
    // ------------------------------------------------------------------------------------------------------------------------------
    //receives color from ColorPicker and forwards it to other classes
    func receiveHueColor(hue: CGFloat) {
        let newColor:UIColor = UIColor.init(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        if let rgb = newColor.rgb() {
            currentColorShowerView.backgroundColor = UIColor(red: CGFloat((rgb >> 16) & 0x000000FF)/255.0, green: CGFloat((rgb >> 8) & 0x000000FF)/255.0, blue: CGFloat(rgb & 0x000000FF)/255.0, alpha: 1.0)
            
            receiveHueAndRGBColorDelegate?.receiveHueAndRGBColor(rgb: rgb)
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    func setReceiveHueAndRGBColorDelegate(incomingDelegate: ReceiveHueAndRGBColorDelegate){
        receiveHueAndRGBColorDelegate = incomingDelegate
    }
    
    func setColor(color: UIColor){
        colorPicker.setHueFromColor(color: color)
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
