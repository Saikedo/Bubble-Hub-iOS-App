//
//  ConnectionIndicatorVIewController.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/15/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit

class ConnectionIndicatorVIewController: UIViewController {

    
    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    var alertTitleText = "Title"
    var alertMessageText = "Message"
    // ------------------------------------------------------------------------------------------------------------------------------
    


    
    
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var viewBody: UIView!
    
    
    @IBOutlet var alertTitle: UILabel!
    
    
    @IBOutlet var alertMessage: UILabel!
    
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    

    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        viewBody.layer.cornerRadius = 10
        viewBody.layer.borderWidth = 2
        viewBody.layer.borderColor = GlobalColors.black.cgColor
        
        alertTitle.text! = alertTitleText
        alertMessage.text! = alertMessageText
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
       
    }
    
    
    // gets called when navigation bar back button is pressed
    override func viewWillDisappear(_ animated: Bool) {
     
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    func setTitle(title: String) {
        alertTitleText = title
        
        if(self.alertTitle != nil) {
            if(self.alertTitle.text != nil) {
                alertTitle.text! = alertTitleText
            }
        }
    }
    
    func setMessage(message: String) {
     
        alertMessageText = message
  
        if(self.alertMessage != nil) {
            if(self.alertMessage.text != nil) {
                 alertMessage.text! = alertMessageText
            }
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
