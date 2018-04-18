//
//  MainPageHelpScreenViewController.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/2/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import WebKit

// Handles the displaying of help pages
class HelpPageViewController: UIViewController {
    
    // MARK: - Global constants
    // ------------------------------------------------------------------------------------------------------------------------------
    let CALLER_HOME_SCREEN = "net.california_design.bubble_hub.help_screen_view_controller.CALLER_HOME_SCREEN"
    let CALLER_BUBBLE_WALL = "net.california_design.bubble_hub.help_screen_view_controller.CALLER_BUBBLE_WALL"
    let CALLER_BUBBLE_PILLAR = "net.california_design.bubble_hub.help_screen_view_controller.CALLER_BUBBLE_PILLAR"
    let CALLER_BUBBLE_CENTERPIECE = "net.california_design.bubble_hub.help_screen_view_controller.CALLER_BUBBLE_CENTERPIECE"
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    var callerName: String = ""
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var helpPageBodyWebViewOutlet: WKWebView!
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var htmlFileName: String = ""
        
        // sets the correct HTML file to display based on which ViewController made the segue to this ViewController
        switch callerName {
        case CALLER_HOME_SCREEN:
            htmlFileName = "mainScreenHelpPageHTML"
        case CALLER_BUBBLE_WALL:
            htmlFileName = "bubbleWallHelpPageHTML"
        case CALLER_BUBBLE_PILLAR:
            htmlFileName = "bubblePillarHelpPageHTML"
        case CALLER_BUBBLE_CENTERPIECE:
            htmlFileName = "bubbleCenterpieceHelpPageHTML"
        default:
            htmlFileName = "missingHelpPageHTML"
        }
        
        // Load the HTML and show it in WebView
        let htmlFilePath = Bundle.main.path(forResource: htmlFileName, ofType: "html")
        let url = URL(fileURLWithPath: htmlFilePath!)
        let request = URLRequest(url: url)
        helpPageBodyWebViewOutlet.load(request)
    }
}
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    
    
    
    
    

