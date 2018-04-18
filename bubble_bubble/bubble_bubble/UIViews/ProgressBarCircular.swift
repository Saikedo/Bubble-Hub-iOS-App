//
//  ProgressBarCircular.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 9/14/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit


class ProgressBarCircular: UIView, CAAnimationDelegate {
    
    // MARK: - Global Constatnts
    // ------------------------------------------------------------------------------------------------------------------------------
      let STROKE_WIDTH: CGFloat = 8.0
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global Variables
    // ------------------------------------------------------------------------------------------------------------------------------
    private var animation = CABasicAnimation()
    private var animationDidStart = false
    private var timerDuration = 0
    
    lazy var fgProgressLayer: CAShapeLayer = {
        let fgProgressLayer = CAShapeLayer()
        return fgProgressLayer
    }()
    
    lazy var bgProgressLayer: CAShapeLayer = {
        let bgProgressLayer = CAShapeLayer()
        return bgProgressLayer
    }()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    // MARK: - Delegate/protocol listener methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Gets called when the animation is finished
    internal func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        stopAnimation()
    }
    
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Used in ViewControllers to load the foreground and background circular progress bar layers
    func loadProgressBar(){
        loadBgProgressBar()
        loadFgProgressBar()
    }
    
    
    // Loads foreground layer
    private func loadFgProgressBar() {
        let startAngle = CGFloat(-Double.pi / 2)
        let endAngle = CGFloat(3 * Double.pi / 2)
        let centerPoint = CGPoint(x: frame.width/2 , y: frame.height/2)
        let gradientMaskLayer = gradientMask()
        fgProgressLayer.path = UIBezierPath(arcCenter:centerPoint, radius: min((frame.width/2), (frame.height/2)) - (STROKE_WIDTH/2), startAngle:startAngle, endAngle:endAngle, clockwise: true).cgPath
        fgProgressLayer.backgroundColor = UIColor.clear.cgColor
        fgProgressLayer.fillColor = nil
        fgProgressLayer.strokeColor = UIColor.black.cgColor
        fgProgressLayer.lineWidth = STROKE_WIDTH
        fgProgressLayer.strokeStart = 0.0
        fgProgressLayer.strokeEnd = 0.0
        
        gradientMaskLayer.mask = fgProgressLayer
        layer.addSublayer(gradientMaskLayer)
    }
    
    // Loads background layer
    private func loadBgProgressBar() {
        
        let startAngle = CGFloat(-Double.pi / 2)
        let endAngle = CGFloat(3 * Double.pi / 2)
        let centerPoint = CGPoint(x: frame.width/2 , y: frame.height/2)
        let gradientMaskLayer = gradientMaskBg()
        bgProgressLayer.path = UIBezierPath(arcCenter:centerPoint, radius: min((frame.width/2), (frame.height/2)) - (STROKE_WIDTH/2), startAngle:startAngle, endAngle:endAngle, clockwise: true).cgPath
        bgProgressLayer.backgroundColor = UIColor.clear.cgColor
        bgProgressLayer.fillColor = nil
        bgProgressLayer.strokeColor = UIColor.black.cgColor
        bgProgressLayer.lineWidth = STROKE_WIDTH
        bgProgressLayer.strokeStart = 0.0
        bgProgressLayer.strokeEnd = 1.0
        
        gradientMaskLayer.mask = bgProgressLayer
        layer.addSublayer(gradientMaskLayer)
    }
    
    // Foreground gradient mask
    private func gradientMask() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.locations = [0.0, 1.0]
        let colorTop: AnyObject = GlobalColors.lime.cgColor
        let colorBottom: AnyObject = GlobalColors.summerSky.cgColor
        let arrayOfColors: [AnyObject] = [colorTop, colorBottom]
        gradientLayer.colors = arrayOfColors
        
        return gradientLayer
    }
    
    // Background gradient mask
    private func gradientMaskBg() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.locations = [0.0, 1.0]
        let colorTop: AnyObject = GlobalColors.flipside.cgColor
        let colorBottom: AnyObject = GlobalColors.flipside.cgColor
        let arrayOfColors: [AnyObject] = [colorTop, colorBottom]
        gradientLayer.colors = arrayOfColors
        
        return gradientLayer
    }
    
    
    // Sets progress bar progress ammount
    public func setProgressBar(hours:Int, minutes:Int, seconds:Int) {
        let hoursToSeconds = hours * 3600
        let minutesToSeconds = minutes * 60
        let totalSeconds = seconds + minutesToSeconds + hoursToSeconds
        timerDuration = totalSeconds
    }
    
    
    // Starts or resumes the progress bar animation
    public func start() {
        if !animationDidStart {
            startAnimation()
        }else{
            resumeAnimation()
        }
    }
    
    
    // Pauses the progress bar animation
    public func pause() {
        pauseAnimation()
    }
    
    
    public func stop() {
        stopAnimation()
    }
    
    
    // Starts progress bar animation
    private func startAnimation() {
        resetAnimation()
        
        fgProgressLayer.strokeEnd = 0.0
        animation.keyPath = "strokeEnd"
        animation.fromValue = CGFloat(0.0)
        animation.toValue = CGFloat(1.0)
        animation.duration = CFTimeInterval(timerDuration)
        animation.delegate = self
        animation.isRemovedOnCompletion = false
        animation.isAdditive = true
        animation.fillMode = kCAFillModeForwards
        fgProgressLayer.add(animation, forKey: "strokeEnd")
        animationDidStart = true
    }
    
    
    // reset progress bar animation
    private func resetAnimation() {
        fgProgressLayer.speed = 1.0
        fgProgressLayer.timeOffset = 0.0
        fgProgressLayer.beginTime = 0.0
        fgProgressLayer.strokeEnd = 0.0
        animationDidStart = false
    }
    
    
    // Stop progress bar animation
    private func stopAnimation() {
        fgProgressLayer.speed = 1.0
        fgProgressLayer.timeOffset = 0.0
        fgProgressLayer.beginTime = 0.0
        fgProgressLayer.strokeEnd = 0.0
        fgProgressLayer.removeAllAnimations()
        animationDidStart = false
    }
    
    
    // Pause progress bar animation
    private func pauseAnimation(){
        let pausedTime = fgProgressLayer.convertTime(CACurrentMediaTime(), from: nil)
        fgProgressLayer.speed = 0.0
        fgProgressLayer.timeOffset = pausedTime
        
    }
    
    
    // Resume progress bar animation
    private func resumeAnimation(){
        let pausedTime = fgProgressLayer.timeOffset
        fgProgressLayer.speed = 1.0
        fgProgressLayer.timeOffset = 0.0
        fgProgressLayer.beginTime = 0.0
        let timeSincePause = fgProgressLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        fgProgressLayer.beginTime = timeSincePause
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}

