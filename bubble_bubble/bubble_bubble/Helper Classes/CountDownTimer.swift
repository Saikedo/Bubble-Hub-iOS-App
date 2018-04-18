//
//  CountDownTimer.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 8/27/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.

import UIKit

// MARK: - Protocols
// ------------------------------------------------------------------------------------------------------------------------------

// Used to send time data to other ViewControllers
protocol CountdownTimerDelegate:class {
    func countdownTime(time: (hours: String, minutes:String, seconds:String))
}
// ------------------------------------------------------------------------------------------------------------------------------

class CountdownTimer {
    // MARK: - Global constants
    // ------------------------------------------------------------------------------------------------------------------------------

    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    weak var delegate: CountdownTimerDelegate?
    private var seconds = 0.0
    private var duration = 0.0
    private lazy var timer: Timer = {
        let timer = Timer()
        return timer
    }()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    public func start() {
        runTimer()
    }
    
    
    public func pause() {
        timer.invalidate()
    }
    
    
    public func stop() {
        timer.invalidate()
        duration = seconds
        delegate?.countdownTime(time: timeString(time: TimeInterval(ceil(duration))))
    }
    
    
    private func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    
    @objc private func updateTimer(){
        if duration < 0.0 {
            timer.invalidate()
            timerDone()
        } else {
            duration -= 0.01
            delegate?.countdownTime(time: timeString(time: TimeInterval(ceil(duration))))
        }
    }
    
    public func setTimer(hours:Int, minutes:Int, seconds:Int) {
        let hoursToSeconds = hours * 3600
        let minutesToSeconds = minutes * 60
        let secondsToSeconds = seconds
        
        let seconds = secondsToSeconds + minutesToSeconds + hoursToSeconds
        self.seconds = Double(seconds)
        self.duration = Double(seconds)
        
        delegate?.countdownTime(time: timeString(time: TimeInterval(ceil(duration))))
    }
    
    
    private func timeString(time:TimeInterval) -> (hours: String, minutes:String, seconds:String) {
        
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        return (hours: String(format:"%02i", hours), minutes: String(format:"%02i", minutes), seconds: String(format:"%02i", seconds))
    }
    
    private func timerDone() {
        timer.invalidate()
        duration = seconds
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
