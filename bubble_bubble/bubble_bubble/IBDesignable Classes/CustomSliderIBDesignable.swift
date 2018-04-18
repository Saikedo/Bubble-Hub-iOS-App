//
//  CustomSliderIBDesignable.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/12/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import Foundation


// Creates a cutom slider with specified height thumb image and thumb image size
@IBDesignable
class CustomSliderIBDesignable: UISlider {
    
    // MARK: - IBInspectables
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBInspectable var trackHeight: CGFloat = 3.0 {
        didSet {
            self.setupSlider()
        }
    }
    
    @IBInspectable var thumbImage: UIImage? {
        didSet {
            self.setupSlider()
        }
    }
    
    @IBInspectable var thumbImageSize: CGFloat = 5.0 {
        didSet {
            self.setupSlider()
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSlider()
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupSlider()
    }
    
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        // Use properly calculated rect
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = trackHeight
        return newRect
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Makes changes to slider when one of the IBInspectibles are changed or view is initialized
    func setupSlider() {
        if(thumbImage != nil){
            //let thumbImage : UIImage = UIImage(named: "icon_sound_on")!
            let size = CGSize(width: thumbImageSize, height: thumbImageSize)
            let newImage: UIImage = resizeImage(image: thumbImage!, targetSize: size)
            self.setThumbImage(newImage, for: UIControlState.normal)
        }
    }
    
    
    // Given an image and size, resizes the image to meet the size
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio,height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0,y: 0,width: newSize.width,height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
