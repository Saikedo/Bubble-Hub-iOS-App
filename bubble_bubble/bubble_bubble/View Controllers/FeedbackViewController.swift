//
//  FeedbackViewController.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/8/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import MessageUI

// Handles bug report/feedback sumission
class FeedbackViewController: UIViewController, MFMailComposeViewControllerDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    private var receiveHueAndRGBColorDelegate: ReceiveHueAndRGBColorDelegate?
    private var deviceInfo: String = ""
    private var messageBody: String = ""
    private var attachedFilesArray = [Data]()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var popupView: UIView!
    @IBOutlet var feedbackTextOutlet: UITextView!
    @IBOutlet var numberOfAttachmentsLabelOutlet: UILabel!
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBActions
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBAction func attachImageButtonAction(_ sender: Any) {
        pickImage()
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButtonAction(_ sender: Any) {
        let mailComposeViewController = configureMailCOmposeViewController()
        if(MFMailComposeViewController.canSendMail()) { // If the phone is able to send e-mail
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
        else { // show error telling the user that they need to setup their e-mail
            showSendMailErrorAlert()
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupView.layer.cornerRadius = 10
        popupView.layer.borderWidth = 2
        popupView.layer.borderColor = GlobalColors.black.cgColor
        
        feedbackTextOutlet.layer.cornerRadius = 10
        feedbackTextOutlet.layer.borderWidth = 2
        feedbackTextOutlet.layer.borderColor = GlobalColors.black.cgColor
        feedbackTextOutlet.delegate = self
        
        deviceInfo = gatherDeviceInfo()
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    
    // MARK: - Delegate/protocol listener methods
    // ------------------------------------------------------------------------------------------------------------------------------

    // Called when user presses return key on keyboard.
    // Assigns the text in textView to message body variable.
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            messageBody = textView.text!
            return false
        }
        return true
    }
    
    
    // Result of the mail sender application is sent here
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case MFMailComposeResult.cancelled:
            print("Mail cancelled")
        case MFMailComposeResult.saved:
            print("Mail saved")
        case MFMailComposeResult.sent:
            print("Mail sent")
            dismiss(animated: true, completion: nil)
        case MFMailComposeResult.failed:
            print("Mail sent failure: \(error!.localizedDescription)")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // Image that was picked in gallery is received here.
    // We convert the image into Data and store it in imageData array.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let imageData = UIImagePNGRepresentation(image)!
            attachedFilesArray.append(imageData)
            numberOfAttachmentsLabelOutlet.isHidden = false
            numberOfAttachmentsLabelOutlet.text = GlobalStrings.NUMBER_OF_ATTACHMENTS + String(attachedFilesArray.count)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // ------------------------------------------------------------------------------------------------------------------------------
    
    

    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Aquires device os version and device name and returns it as a string
    func gatherDeviceInfo() -> String {
        let systemVersion = UIDevice.current.systemVersion
        let phoneVersion = UIDevice.current.modelName
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        return "\n\n------------------------------\n" + "Application Version: " + appVersion! + "\n" +
            "Phone Version: " + phoneVersion + "\n" + "iOS Version: " + systemVersion + "\n"
    }
    
    
    // MFMailComposeViewController configuration is done here
    func configureMailCOmposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["BubbleHubFeedback@gmail.com"])
        mailComposerVC.setSubject("Bubble Hub bug report/feedback")
        mailComposerVC.setMessageBody(messageBody  + deviceInfo, isHTML: false)
        
        var imageIndex = 0
        for imageData in attachedFilesArray {
            if(!imageData.isEmpty) {
                mailComposerVC.addAttachmentData(imageData, mimeType: "image/png", fileName: "image " + String(imageIndex))
                imageIndex += 1
            }
        }
        
        return mailComposerVC
    }
    
    
    // Shows an alert telling that we were unable to send email and email need to be set up
    func showSendMailErrorAlert() {
        let alertController = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail. Please check e-mail configuration and try again.", preferredStyle: UIAlertControllerStyle.alert) //Replace
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // Opens the gallery so the user can pick an image to attach to email
    func pickImage() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        self.present(image, animated: true)
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}



