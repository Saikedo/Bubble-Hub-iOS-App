//
//  BubbleCenterpieceViewController.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 12/7/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

/*
 // MARK: - Initializer methods
 // ------------------------------------------------------------------------------------------------------------------------------
 func initializeDispatchWorkItems() {
 //If bluetooth  connection takes longer than 5 seconds, this is used to  just cancel the connection and go back to home screen
 aaa
 closeViewControllerIfBluetoothFailsToConnect = DispatchWorkItem{
 print("ViewControllerBubbleCenterpiece closeViewControllerIfBluetoothFailsToConnect: Bluetooth failed to establish connection in 5 seconds")
 
 if(self.backToHomeViewDelegate != nil){
 self.backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.BLUETOOTH_CONNECTION_LOST)
 }
 
 // I delay the dismiss call by 1 second because I was having trouble when dismiss was being called too fast and alert was not getting dismissed
 DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { self.alertController.dismiss(animated: true, completion: nil)})
 
 self.disconnectFromBt()
 self.navigationController?.popViewController(animated: true)
 }
 }
 // ------------------------------------------------------------------------------------------------------------------------------


*/




import UIKit
import CoreBluetooth

//Handles all the Bubble Centerpiece related controls.
class BubbleCenterpieceViewController: UIViewController,  ReceiveBluetoothIncomingDataDelegate, CountdownTimerDelegate, ReceiveHueAndRGBColorDelegate  {
    
    // MARK: - Global constants
    // ------------------------------------------------------------------------------------------------------------------------------
    private let SLEEP_TIMER_SECONDS: Int = 30
    private let countdownTimer = CountdownTimer()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    private var customColorRGB: Int = 0xFF0000 //Red
    var backToHomeViewDelegate: BackToHomeViewDelegate? = nil
    private var sendCustomColorData: DispatchWorkItem? = nil
    private var sendBrightnessData: DispatchWorkItem? = nil
    private var arduinoPowerStatus: Bool = false
    var btServices: BtServices? = nil
    private var hardwareVersionMajor: Int = 0
    private var hardwareVersionMinor: Int = 0
    private var brightness: Int32 = 255
    var bluetoothPeripheral: CBPeripheral?  = nil
    var goingForward = false
    private var customAlert: ConnectionIndicatorVIewController? = nil
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global enumerators
    // ------------------------------------------------------------------------------------------------------------------------------
    private enum btMessageOut: Int{
        case BT_MESSAGE_OUT_STATUS_REQUEST, BT_MESSAGE_OUT_VERSION_REQUEST, BT_MESSAGE_OUT_SYSTEM_OFF, BT_MESSAGE_OUT_SYSTEM_ON,
        BT_MESSAGE_OUT_SYSTEM_SLEEP, BT_MESSAGE_OUT_CANCEL_SLEEP, BT_MESSAGE_OUT_FADE_LIGHTS;
    }
    
    private enum btMessageIn: Int{
        case BT_MESSAGE_IN_SYSTEM_OFF, BT_MESSAGE_IN_SYSTEM_ON, BT_MESSAGE_IN_SLEEP_MODE_STARTED, Bt_MESSAGE_IN_SLEEP_ACHIEVED,
        BT_MESSAGE_IN_SLEEP_CANCELLED, BT_MESSAGE_IN_MANUAL_MODE, BT_MESSAGE_IN_FADE_LIGHTS, BT_MESSAGE_IN_CUSTOM_LIGHTS;
    }
    // ------------------------------------------------------------------------------------------------------------------------------

    
    
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var countDownTimerSecondsLabel: UILabel!
    @IBOutlet var brightnessLabel: UILabel!
    @IBOutlet var brightnessSlider: UISlider!
    @IBOutlet var countDownTimerProgressBar: ProgressBarCircular!
    @IBOutlet var button_on_off: CustomButtonIbDesignable!
    @IBOutlet var button_lights_custom_color: CustomButtonIbDesignable!
    @IBOutlet var button_sleep: CustomButtonIbDesignable!
    @IBOutlet var button_lights_fade: CustomButtonIbDesignable!
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBActions
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBAction func helpPageButtonAction(_ sender: Any) {
        goingForward = true
        performSegue(withIdentifier: "bubbleCenterpieceToHelpPageSegue", sender: self)
    }
    
    @IBAction func button_on_off(_ sender: Any) {
        if(btServices != nil){
            
            if(!arduinoPowerStatus) {
                btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_SYSTEM_ON.rawValue))
            }
            else {
                btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_SYSTEM_OFF.rawValue))
            }
        }
    }
    
    // If sleep button text is set to CANCEL_SLEEP then we are already about to sleep
    // and pressing the button now will cancel the sleep process
    @IBAction func button_sleep(_ sender: Any) {
        if(button_sleep.titleLabel!.text == GlobalStrings.SLEEP) {
            messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SYSTEM_SLEEP.rawValue))
        }
        else if(button_sleep.titleLabel!.text == GlobalStrings.CANCEL_SLEEP) {
            messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_CANCEL_SLEEP.rawValue))
        }
    }
    
    @IBAction func button_lights_fade(_ sender: Any) {
        messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_FADE_LIGHTS.rawValue))
    }
    
    @IBAction func button_lights_custom_color(_ sender: Any) {
        
        btServices!.writeToBt(dataToSend: String(customColorRGB))
        
        let colorPicker = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "popUpColorPicker") as! ColorPickerViewController
        colorPicker.setReceiveHueAndRGBColorDelegate(incomingDelegate: self)
        self.addChildViewController(colorPicker)
        colorPicker.view.frame = self.view.frame
        self.view.addSubview(colorPicker.view)
        colorPicker.didMove(toParentViewController: self)
        
        colorPicker.setColor(color: UIColor(red: CGFloat((customColorRGB >> 16) & 0x000000FF)/255.0, green: CGFloat((customColorRGB >> 8) & 0x000000FF)/255.0, blue: CGFloat(customColorRGB & 0x000000FF)/255.0, alpha: 1.0))
    }
    
    @IBAction func brightnessSliderListener(_ sender: UISlider) {
        print("Slider current value: " + String(Int(sender.value)))
        brightness = Int32(sender.value);
        brightnessLabel.text = String((brightness * 100) / 255) + " %"
        
        //Since we don't want to send too much bluetooth information too fast, I implemented this handler
        //that only sends the data to Arduino if the particular brightness has been chosen for more than 100ms.
        sendBrightnessData?.cancel()
        sendBrightnessData = DispatchWorkItem{
            //Since we don't want to send too much bluetooth information too fast, I implemented this handler
            //that only sends the data to Arduino if the particular brightness has been chosen for more than 100ms.
            let brightnessWithSetFlag = (self.brightness & ~((~0 << 24))) | (1 << 25);
            self.btServices!.writeToBt(dataToSend: String(brightnessWithSetFlag))
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100), execute: sendBrightnessData!)
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presentAlertController()
        
        // Disables the swipe from left edge to close page gesture
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if(btServices == nil) { // This should never happen
            print("ViewControllerBubbleCenterpiece: viewDidAppear: ERROR. btCommunication is nil")
            if(self.backToHomeViewDelegate != nil) {
                self.backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.FAILED_TO_ACCESS_THE_PHONE_BLUETOOTH)
            }
            self.disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
        }
        
        countdownTimer.delegate = self
        
        countDownTimerProgressBar.backgroundColor = UIColor.clear
        countDownTimerProgressBar.isHidden = true
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        btServices!.setReceiveBluetoothIncomingDataDelegate(incomingDelegate: self)
        btServices!.setPeripheral(peripheral: bluetoothPeripheral!)
        btServices!.connectToPeripheral()
    }
    
   
    override func viewDidAppear(_ animated: Bool) {
        // I was having problem with scaling the loadProgressBar if it was done internaly, so now we need to make this function call
        // to ensure that progress bar is loaded correctly with accurate frame height and width
        countDownTimerProgressBar.loadProgressBar()
        
        goingForward = false
    }
    
    
    // gets called when navigation bar back button is pressed
    override func viewWillDisappear(_ animated: Bool) {
        if(!goingForward) {
            print("ViewControllerBubbleCenterpiece: viewWillDisappear: Back button was pressed")
            // I delay the dismiss call by 1 second because I was having trouble when dismiss was being called too fast and alert was not getting dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { self.customAlert!.dismiss(animated: true, completion: nil)})
            disconnectFromBt()
        }
    }
    
    // Handles the setup before segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "bubbleCenterpieceToHelpPageSegue") {
            let destViewController: HelpPageViewController = segue.destination as! HelpPageViewController
            destViewController.callerName = destViewController.CALLER_BUBBLE_CENTERPIECE
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------

    
  
    // MARK: - Delegate protocol methods
    // ------------------------------------------------------------------------------------------------------------------------------
    // this delegate function is used to receive color data from ColorPicker class
    func receiveHueAndRGBColor(rgb: Int){
        if(customColorRGB != rgb){
            customColorRGB = rgb
            
            //Since we don't want to send too much bluetooth information too fast, I implemented this handler
            //that only sends the data to Arduino if the particular color has been chosen for more than 100ms.
            sendCustomColorData?.cancel()
            //Used to send custom color data and control the timing of those messages
            //See receiveHueAndRGBColor for more info
            sendCustomColorData = DispatchWorkItem{
                let customColorRGBWithSetFlag = (self.customColorRGB & ~((~0 << 24))) | (1 << 24);
                self.btServices!.writeToBt(dataToSend: String(customColorRGBWithSetFlag))
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100), execute: sendCustomColorData!)
        }
    }
    
    //Delegate function that is used by BtServices to deliver messages to this class
    func receiveBluetoothIncomingData(message: String) {

        switch (message) {
        case btServices!.CONNECTION_ESTABLISHED:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: Connection is established with peripheral")
            customAlert!.setMessage(message: "Discovering services. Please Wait...")
            
        case btServices!.FAILED_TO_CONNECT:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: Failed to establish connection.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.FAILED_TO_ESTABLISH_CONNECTION)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
            
        case btServices!.SERVICES_DISCOVERED:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: Services discovered.")
            customAlert!.setMessage(message: "Discovering characteristics. Please Wait...")
            
        case btServices!.FAILED_TO_DISCOVER_SERVICES:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: Failed to discover services.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.FAILED_TO_DISCOVER_SERVICES)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
       
        case btServices!.CHARACTERISTICS_DISCOVERED:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: Characteristics discovered.")
            // I delay the dismiss call by 1 second because I was having trouble when dismiss was being called too fast and alert was not getting dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { self.customAlert!.dismiss(animated: true, completion: nil) })
            
            
            btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_VERSION_REQUEST.rawValue))
            btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_STATUS_REQUEST.rawValue))
       
        case btServices!.FAILED_TO_DISCOVER_CHARACTERISTICS:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: Failed to discover characteristics.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.FAILED_TO_DISCOVER_CHARACTERISTICS)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
        
        case btServices!.CONNECTION_LOST:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: We got disconnected from gatt, finishing the activity.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.LOST_BLUETOOTH_CONNECTION)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
        
        // In this case we actually received a message from bluetooth and not a bluetooth state message
        default:
            print("BubbleCenterpieceViewController: receiveBluetoothIncomingData: received message " + message)
            processIncomingBtMessage(incomingMessage: message)
        }
    }

    
    // Delegate function that receives countDownTimer progress
    func countdownTime(time: (hours: String, minutes: String, seconds: String)) {
        countDownTimerSecondsLabel.text = time.seconds
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Presents the alert controller telling the user to wait for the connection to be established
    func presentAlertController() {
        customAlert = self.storyboard?.instantiateViewController(withIdentifier: "simpleID") as? ConnectionIndicatorVIewController
        customAlert!.providesPresentationContextTransitionStyle = true
        customAlert!.definesPresentationContext = true
        customAlert!.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        customAlert!.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        customAlert!.setTitle(title: "Connecting to Bubble Centerpiece")
        customAlert!.setMessage(message: "Establishing connection. Please Wait...")
        self.present(customAlert!, animated: true, completion: nil)

    }
    
    func disconnectFromBt(){
        if(btServices != nil){
            btServices!.disconnectFromPeripheralAndResetVariables()
            btServices = nil
        }
    }
    
    
    //Handles the processing of data that was received by bluetooth
    private func processIncomingBtMessage(incomingMessage: String) {
        
        let HARDWARE_VERSION_NUMBER: String = "VerNum"
        let BRIGHTNESS_MESSAGE: String = "brightness"
        let MESSAGE_STARTING_SYMBOL: Character = "*"
        let MESSAGE_ENDING_SYMBOL: Character = "|"
        let STATUS_REQUEST = "SR"
        
        //This next chunk of code ensures that the messagge we received is not corrupted.
        //This is done by making sure we have both starting and ending symbols in proper place
        //and also we do not have extra starting symbols.
        let startIndex = incomingMessage.index(of: MESSAGE_STARTING_SYMBOL)
        let endIndex = incomingMessage.index(of: MESSAGE_ENDING_SYMBOL)
        
        if(startIndex == nil || endIndex == nil || startIndex!.encodedOffset > endIndex!.encodedOffset){
            print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: ERROR, corrupted message 1")
            return
        }
        
        let message: String = String(incomingMessage[incomingMessage.index(after: startIndex!) ..< endIndex!])
        
        if(message.index(of: MESSAGE_STARTING_SYMBOL) != nil || message.index(of: MESSAGE_ENDING_SYMBOL) != nil){
            print("ViewControllerBubblePillar: processIncomingBtMessage: ERROR, corrupted message 2")
            return
        }
        
        print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Received message " + message)
        
        
        var intMessage = [Int]()
        
        if(message.count > 2 && message.prefix(2) == STATUS_REQUEST) {
            //1st character: 0 = off, 1 = on
            //2nd character: 0 = fade lights, 1 = custom lights
            //3rd-5th character: brightness
            
            
            let powerStatus = Int(message[message.index(message.startIndex, offsetBy: 2) ..< message.index(message.startIndex, offsetBy: 3)])!
            let lightsMode = Int(message[message.index(message.startIndex, offsetBy: 3) ..< message.index(message.startIndex, offsetBy: 4)])!
            let newBrightness = Int32(message[message.index(message.startIndex, offsetBy: 4) ..< message.endIndex])!
            
            if(powerStatus == 0) {
                intMessage.append(btMessageIn.BT_MESSAGE_IN_SYSTEM_OFF.rawValue)
            }
            else {
                intMessage.append(btMessageIn.BT_MESSAGE_IN_SYSTEM_ON.rawValue)
                if(lightsMode == 0) {
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_FADE_LIGHTS.rawValue)
                }
                else {
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_CUSTOM_LIGHTS.rawValue)
                }
            }
            
            
            
            
            setBrightness(brightness: newBrightness)
        }
        else if(message.contains(HARDWARE_VERSION_NUMBER)) { // If the message was for indicating hardware version of Arduino code
            hardwareVersionMajor = Int(message[message.index(message.startIndex, offsetBy: 6) ..< message.index(of: ".")!])!
            hardwareVersionMinor = Int(message[message.index(after: message.index(of: ".")!) ..< message.endIndex])!
            print("ViewControllerBubbleCenterpiece:: processIncomingBtMessage: Received harware version " + String(hardwareVersionMajor) + "." + String(hardwareVersionMinor))
            
            return
        }
        else if(message.contains(BRIGHTNESS_MESSAGE)) { // If the message was brightness level
            print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Received brightness " + String(brightness));
            setBrightness(brightness: Int32(message[message.index(message.startIndex, offsetBy: 10) ..< message.endIndex])!)
            return
        }
        else {
            //Makes sure that after this point, message only contains numbers
            if(Int(message) == nil){
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: ERROR, message contains not numeric symbols")
                return
            }
            
            intMessage.append(Int(message)!)
        }
        
        
        
        
        
        for msg in intMessage {
            if(msg == btMessageIn.BT_MESSAGE_IN_SYSTEM_ON.rawValue){
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Setting Button to On")
                arduinoPowerStatus = true;
                
                button_on_off.firstColor = GlobalColors.offButtonStartColor
                button_on_off.secondColor = GlobalColors.offButtonMiddleColor
                button_on_off.thirdColor = GlobalColors.offButtonEndColor
                button_on_off.setTitle("Off", for: .normal)
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SYSTEM_OFF.rawValue){
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Setting Button to On")
                
                if(button_sleep.titleLabel!.text == GlobalStrings.CANCEL_SLEEP) {
                    messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_CANCEL_SLEEP.rawValue))
                }
                
                arduinoPowerStatus = false;
                
                button_on_off.firstColor = GlobalColors.onButtonStartColor
                button_on_off.secondColor = GlobalColors.onButtonMiddleColor
                button_on_off.thirdColor = GlobalColors.onButtonEndColor
                button_on_off.setTitle("On", for: .normal)
                
                setLightsButtonsUnpressed()
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_MANUAL_MODE.rawValue){
                // If manual button is turned on, just alert the user and exit the View Controller
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Got notification that Bubble Pillar is in manual mode.")
                self.backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.MANUAL_MODE_IS_ON)
                disconnectFromBt()
                
                // I delay the popView call by 1 second because I was having trouble when this was being called too early and  view was not being dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { self.navigationController?.popViewController(animated: true)})
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SLEEP_MODE_STARTED.rawValue){
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Setting countDownTimer instead of sleep button")
                button_sleep.setTitle(GlobalStrings.CANCEL_SLEEP, for: .normal)
                countDownTimerProgressBar.isHidden = false
                
                countdownTimer.setTimer(hours: 0, minutes: 0, seconds: SLEEP_TIMER_SECONDS)
                countDownTimerProgressBar.setProgressBar(hours: 0, minutes: 0, seconds: SLEEP_TIMER_SECONDS)
                countdownTimer.start()
                countDownTimerProgressBar.start()
            }
            else if(msg == btMessageIn.Bt_MESSAGE_IN_SLEEP_ACHIEVED.rawValue){
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Setting Sleep button instead of countDownTimer")
                countDownTimerProgressBar.stop()
                countdownTimer.stop()
                countDownTimerProgressBar.isHidden = true
                button_sleep.setTitle(GlobalStrings.SLEEP, for: .normal)
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SLEEP_CANCELLED.rawValue) {
                if(button_sleep.titleLabel!.text == GlobalStrings.CANCEL_SLEEP) {
                    countDownTimerProgressBar.stop()
                    countdownTimer.stop()
                    countDownTimerProgressBar.isHidden = true
                    button_sleep.setTitle(GlobalStrings.SLEEP, for: .normal)
                    print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Sleep cancelled")
                }
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_FADE_LIGHTS.rawValue){
                setLightsButtonsUnpressed()
                button_lights_fade.borderColor = GlobalColors.red
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Setting fade lights button to pressed")
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_CUSTOM_LIGHTS.rawValue){
                setLightsButtonsUnpressed()
                button_lights_custom_color.borderColor = GlobalColors.red
                print("ViewControllerBubbleCenterpiece: processIncomingBtMessage: Setting custom color button to pressed")
            }
        }
    }
    
    func setBrightness(brightness: Int32) {
        self.brightness = brightness
        brightnessLabel.text = String((self.brightness * 100) / 255) + " %"
        brightnessSlider.setValue(Float(self.brightness), animated: true)
    }
    
    
    func setLightsButtonsUnpressed(){
        button_lights_fade.borderColor = GlobalColors.black
        button_lights_custom_color.borderColor = GlobalColors.black
    }
    
    // Used for some of the buttons to make sure that the system is on before sending a message
    func messageSender(message: String){
        if(!arduinoPowerStatus){
            
            let alert = UIAlertController(title: "Bubble Centerpiece Is Turned Off", message: "Do you want to turn on the Bubble Centerpiece ?", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Default action"), style: .`default`, handler: { _ in
                self.btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_SYSTEM_ON.rawValue))
                
                if(Int(message) != btMessageOut.BT_MESSAGE_OUT_SYSTEM_SLEEP.rawValue && Int(message) != btMessageOut.BT_MESSAGE_OUT_CANCEL_SLEEP.rawValue){
                    self.btServices!.writeToBt(dataToSend: message)
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Default action"), style: .`default`, handler: { _ in
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            btServices!.writeToBt(dataToSend: message)
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
