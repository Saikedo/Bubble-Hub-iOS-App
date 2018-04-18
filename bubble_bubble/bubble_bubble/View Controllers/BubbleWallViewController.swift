//
//  BubbleWallViewController.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 9/22/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import CoreBluetooth


//Handles all the Bubble Wall related controls.
class BubbleWallViewController: UIViewController, ReceiveBluetoothIncomingDataDelegate, CountdownTimerDelegate, ReceiveHueAndRGBColorDelegate  {
    
    // MARK: - Global constants
    // ------------------------------------------------------------------------------------------------------------------------------
    private let SLEEP_TIMER_SECONDS: Int = 30
    private let countdownTimer = CountdownTimer()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    var backToHomeViewDelegate: BackToHomeViewDelegate? = nil
    private var customColorRGB: Int = 0xFFFF0000 //Red
    private var sendCustomColorData: DispatchWorkItem? = nil
    private var soundVolume: Int = 30;
    private var soundSystemPowerStatus: Bool = false;
    private var soundMuteStatus: Bool = false
    private var arduinoPowerStatus: Bool = false
    var btServices: BtServices? = nil
    private var hardwareVersionMajor: Int = 0;
    private var hardwareVersionMinor: Int = 0;
    var bluetoothPeripheral: CBPeripheral?  = nil
    var  goingForward = false
    private var customAlert: ConnectionIndicatorVIewController? = nil
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global enumerators
    // ------------------------------------------------------------------------------------------------------------------------------
    private enum btMessageOut: Int {
        case  BT_MESSAGE_OUT_STATUS_REQUEST, BT_MESSAGE_OUT_VERSION_REQUEST, BT_MESSAGE_OUT_SYSTEM_OFF,
        BT_MESSAGE_OUT_SYSTEM_ON, BT_MESSAGE_OUT_SYSTEM_SLEEP, BT_MESSAGE_OUT_CANCEL_SLEEP, BT_MESSAGE_OUT_SMALL_BUBBLES,
        BT_MESSAGE_OUT_BIG_BUBBLES, BT_MESSAGE_OUT_SMALL_AND_BIG_BUBBLES, BT_MESSAGE_OUT_PYRAMID_BUBBLES,
        BT_MESSAGE_OUT_PILLAR_BUBBLES, BT_MESSAGE_OUT_MIXED_BUBBLES, BT_MESSAGE_OUT_FADE_LIGHTS, BT_MESSAGE_OUT_FADE_SPLIT_LIGHTS,
        BT_MESSAGE_OUT_RAINBOW_LIGHTS, BT_MESSAGE_OUT_RAINBOW_2_LIGHTS, BT_MESSAGE_OUT_MIXED_LIGHTS, BT_MESSAGE_OUT_SOUND_ON_OFF,
        BT_MESSAGE_OUT_SOUND_VOLUME_DOWN, BT_MESSAGE_OUT_SOUND_VOLUME_UP, BT_MESSAGE_OUT_SOUND_MUTE, BT_MESSAGE_OUT_SOUND_PREVIOUS,
        BT_MESSAGE_OUT_SOUND_PLAY_PAUSE, BT_MESSAGE_OUT_SOUND_NEXT, BT_MESSAGE_OUT_SOUND_USB_MODE, BT_MESSAGE_OUT_SOUND_AUX_MODE,
        BT_MESSAGE_OUT_SOUND_BT_MODE, BT_MESSAGE_OUT_SOUND_SD_MODE;
    }
    
    private enum btMessageIn: Int {
        case BT_MESSAGE_IN_SYSTEM_OFF, BT_MESSAGE_IN_SYSTEM_ON, BT_MESSAGE_IN_SLEEP_MODE_STARTED,
        Bt_MESSAGE_IN_SLEEP_ACHIEVED, BT_MESSAGE_IN_SLEEP_CANCELLED, BT_MESSAGE_IN_MANUAL_MODE,
        BT_MESSAGE_IN_SMALL_BUBBLES, BT_MESSAGE_IN_BIG_BUBBLES, BT_MESSAGE_IN_SMALL_AND_BIG_BUBBLES,
        BT_MESSAGE_IN_PYRAMID_BUBBLES, BT_MESSAGE_IN_PILLAR_BUBBLES, BT_MESSAGE_IN_MIXED_BUBBLES,
        BT_MESSAGE_IN_FADE_LIGHTS, BT_MESSAGE_IN_FADE_SPLIT_LIGHTS, BT_MESSAGE_IN_RAINBOW_LIGHTS_1,
        BT_MESSAGE_IN_RAINBOW_LIGHTS_2, BT_MESSAGE_IN_MIXED_LIGHTS, BT_MESSAGE_IN_CUSTOM_LIGHTS,
        BT_MESSAGE_IN_SOUND_ON, BT_MESSAGE_IN_SOUND_OFF, BT_MESSAGE_IN_SOUND_VOLUME_CHANGE,
        BT_MESSAGE_IN_SOUND_MUTE, BT_MESSAGE_IN_SOUND_UNMUTE, BT_MESSAGE_IN_SOUND_PLAY, BT_MESSAGE_IN_SOUND_PAUSE,
        BT_MESSAGE_IN_SOUND_USB, BT_MESSAGE_IN_SOUND_AUX, BT_MESSAGE_IN_SOUND_BT, BT_MESSAGE_IN_SOUND_SD;
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var countDownTimerSecondsLabel: UILabel!
    @IBOutlet var button_sound_volume_mute: UIButton!
    @IBOutlet var button_sound_on_off: UIButton!
    @IBOutlet var button_sound_play_pause: UIButton!
    @IBOutlet var countDownTimerProgressBar: ProgressBarCircular!
    @IBOutlet var button_on_off: CustomButtonIbDesignable!
    @IBOutlet var button_sleep: CustomButtonIbDesignable!
    @IBOutlet var button_small_bubble: CustomButtonIbDesignable!
    @IBOutlet var button_big_bubble: CustomButtonIbDesignable!
    @IBOutlet var button_small_plus_big_bubble: CustomButtonIbDesignable!
    @IBOutlet var button_pyramid_bubble: CustomButtonIbDesignable!
    @IBOutlet var button_pillar_bubble: CustomButtonIbDesignable!
    @IBOutlet var button_bubble_mix_mode: CustomButtonIbDesignable!
    @IBOutlet var button_lights_rainbow_1: CustomButtonIbDesignable!
    @IBOutlet var button_lights_rainbow_2: CustomButtonIbDesignable!
    @IBOutlet var button_lights_fade: CustomButtonIbDesignable!
    @IBOutlet var button_lights_fade_split: CustomButtonIbDesignable!
    @IBOutlet var button_lights_custom_color: CustomButtonIbDesignable!
    @IBOutlet var button_lights_mix_mode: CustomButtonIbDesignable!
    @IBOutlet var button_sound_mode_sd: CustomButtonIbDesignable!
    @IBOutlet var button_sound_mode_aux: CustomButtonIbDesignable!
    @IBOutlet var button_sound_mode_bt: CustomButtonIbDesignable!
    @IBOutlet var button_sound_mode_usb: CustomButtonIbDesignable!
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - IBActions
    // ------------------------------------------------------------------------------------------------------------------------------
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
    
    @IBAction func button_small_bubble(_ sender: Any) {
         messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SMALL_BUBBLES.rawValue))
    }
    
    @IBAction func button_big_bubble(_ sender: Any) {
         messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_BIG_BUBBLES.rawValue))
    }
    
    @IBAction func button_small_plus_big_bubble(_ sender: Any) {
         messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SMALL_AND_BIG_BUBBLES.rawValue))
    }
    
    @IBAction func button_pyramid_bubble(_ sender: Any) {
         messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_PYRAMID_BUBBLES.rawValue))
    }
    
    @IBAction func button_pillar_bubble(_ sender: Any) {
         messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_PILLAR_BUBBLES.rawValue))
    }
    
    @IBAction func button_bubble_mix_mode(_ sender: Any) {
         messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_MIXED_BUBBLES.rawValue))
    }
    
    @IBAction func button_lights_rainbow_1(_ sender: Any) {
        messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_RAINBOW_LIGHTS.rawValue))
    }
    
    @IBAction func button_lights_rainbow_2(_ sender: Any) {
        messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_RAINBOW_2_LIGHTS.rawValue))
    }
    
    @IBAction func button_lights_fade(_ sender: Any) {
        messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_FADE_LIGHTS.rawValue))
    }
    
    @IBAction func button_lights_fade_split(_ sender: Any) {
        messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_FADE_SPLIT_LIGHTS.rawValue))
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
    
    @IBAction func button_lights_mix_mode(_ sender: Any) {
        messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_MIXED_LIGHTS.rawValue))
    }
    
    @IBAction func button_sound_on_off(_ sender: Any) {
        btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_SOUND_ON_OFF.rawValue))
    }
    
    @IBAction func button_sound_volume_down(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_VOLUME_DOWN.rawValue))
    }
    
    @IBAction func button_sound_volume_up(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_VOLUME_UP.rawValue))
    }
    
    @IBAction func button_sound_volume_mute(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_MUTE.rawValue))
    }
    
    @IBAction func button_sound_previous(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_PREVIOUS.rawValue))
    }
    
    @IBAction func button_sound_play_pause(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_PLAY_PAUSE.rawValue))
    }

    @IBAction func button_sound_next(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_NEXT.rawValue))
    }
    
    @IBAction func button_sound_mode_usb(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_USB_MODE.rawValue))
    }
    
    @IBAction func button_sound_mode_sd(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_SD_MODE.rawValue))
    }
    
    @IBAction func button_sound_mode_bt(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_BT_MODE.rawValue))
    }
    
    @IBAction func button_sound_mode_aux(_ sender: Any) {
        soundMessageSender(message: String(btMessageOut.BT_MESSAGE_OUT_SOUND_AUX_MODE.rawValue))
    }
    
    @IBAction func helpPageButtonAction(_ sender: Any) {
        goingForward = true
        performSegue(withIdentifier: "bubbleWallToHelpPageSegue", sender: self)
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
            print("ViewControllerBubbleWall: viewDidAppear: ERROR. btCommunication is nil")
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
            print("ViewControllerBubbleWall: viewWillDisappear: Back button was pressed")
            
            // I delay the dismiss call by 1 second because I was having trouble when dismiss was being called too fast and alert was not getting dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { self.customAlert!.dismiss(animated: true, completion: nil)})
            
            disconnectFromBt()
        }
    }
    
    
    // Handles the setup before segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "bubbleWallToHelpPageSegue") {
            let destViewController: HelpPageViewController = segue.destination as! HelpPageViewController
            destViewController.callerName = destViewController.CALLER_BUBBLE_WALL
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
            print("BubbleWallViewController: receiveBluetoothIncomingData: Connection is established with peripheral")
            customAlert?.setMessage(message: "Discovering services. Please Wait...")
            
        case btServices!.FAILED_TO_CONNECT:
            print("BubbleWallViewController: receiveBluetoothIncomingData: Failed to establish connection.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.FAILED_TO_ESTABLISH_CONNECTION)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
            
        case btServices!.SERVICES_DISCOVERED:
            print("BubbleWallViewController: receiveBluetoothIncomingData: Services discovered.")
            customAlert?.setMessage(message: "Discovering characteristics. Please Wait...")
            
        case btServices!.FAILED_TO_DISCOVER_SERVICES:
            print("BubbleWallViewController: receiveBluetoothIncomingData: Failed to discover services.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.FAILED_TO_DISCOVER_SERVICES)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
            
        case btServices!.CHARACTERISTICS_DISCOVERED:
            print("BubbleWallViewController: receiveBluetoothIncomingData: Characteristics discovered.")
            // I delay the dismiss call by 1 second because I was having trouble when dismiss was being called too fast and alert was not getting dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { self.customAlert!.dismiss(animated: true, completion: nil)})
            
            btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_VERSION_REQUEST.rawValue))
            btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_STATUS_REQUEST.rawValue))
            
        case btServices!.FAILED_TO_DISCOVER_CHARACTERISTICS:
            print("BubbleWallViewController: receiveBluetoothIncomingData: Failed to discover characteristics.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.FAILED_TO_DISCOVER_CHARACTERISTICS)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
            
        case btServices!.CONNECTION_LOST:
            print("BubbleWallViewController: receiveBluetoothIncomingData: We got disconnected from gatt, finishing the activity.")
            if(backToHomeViewDelegate != nil){
                backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.LOST_BLUETOOTH_CONNECTION)
            }
            disconnectFromBt()
            self.navigationController?.popViewController(animated: true)
            
        // In this case we actually received a message from bluetooth and not a bluetooth state message
        default:
            print("BubbleWallViewController: receiveBluetoothIncomingData: received message " + message)
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
        customAlert!.setTitle(title: "Connecting to Bubble Wall")
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
        
        let SOUND_LEVEL: String = "soundLevel";
        let HARDWARE_VERSION_NUMBER: String = "VerNum";
        let MESSAGE_STARTING_SYMBOL: Character = "*"
        let MESSAGE_ENDING_SYMBOL: Character = "|"
        let STATUS_REQUEST = "SR"
    
        //This next chunk of code ensures that the messagge we received is not corrupted.
        //This is done by making sure we have both starting and ending symbols in proper place
        //and also we do not have extra starting symbols.
        let startIndex = incomingMessage.index(of: MESSAGE_STARTING_SYMBOL)
        let endIndex = incomingMessage.index(of: MESSAGE_ENDING_SYMBOL)
        
        if(startIndex == nil || endIndex == nil || startIndex!.encodedOffset > endIndex!.encodedOffset){
            print("ViewControllerBubbleWall: processIncomingBtMessage: ERROR, corrupted message 1")
            return
        }
        
        let message: String = String(incomingMessage[incomingMessage.index(after: startIndex!) ..< endIndex!])
        
        if(message.index(of: MESSAGE_STARTING_SYMBOL) != nil || message.index(of: MESSAGE_ENDING_SYMBOL) != nil){
            print("ViewControllerBubbleWall: processIncomingBtMessage: ERROR, corrupted message 2")
            return
        }
        
        print("ViewControllerBubbleWall: processIncomingBtMessage: Received message " + message)
        
        var intMessage = [Int]()

        if(message.count > 2 && message.prefix(2) == STATUS_REQUEST) {
            //1st character: System power: 0 = off, 1 = on
            //2nd character: Bubbles: 0 = mixed, 1 = small, 2 = big, 3 = small+big, 4 = pyramid, 5 = pillar
            //3rd character: Lights: 0 = mixed, 1 = Rainbow, 2 = Rainbow2, 3 = fade, 4 = fade split, 5 = custom
            //4th character: Sound power: 0 = off, 1 = on
            //5th character: Sound mute: 0 = not mute, 1 = mute
            //6th character: Sound play: 0 = pause, 1 = play
            //7th character: Sound mode: 0 = USB, 1 = AUX, 2 = BT, 3 = SD
            //8th-9th characters: Sound volume
            
            let powerStatus = Int(message[message.index(message.startIndex, offsetBy: 2) ..< message.index(message.startIndex, offsetBy: 3)])!
            let bubblesMode = Int(message[message.index(message.startIndex, offsetBy: 3) ..< message.index(message.startIndex, offsetBy: 4)])!
            let lightsMode = Int(message[message.index(message.startIndex, offsetBy: 4) ..< message.index(message.startIndex, offsetBy: 5)])!
            let soundPowerStatus = Int(message[message.index(message.startIndex, offsetBy: 5) ..< message.index(message.startIndex, offsetBy: 6)])!
            let soundMute = Int(message[message.index(message.startIndex, offsetBy: 6) ..< message.index(message.startIndex, offsetBy: 7)])!
            let soundPlay = Int(message[message.index(message.startIndex, offsetBy: 7) ..< message.index(message.startIndex, offsetBy: 8)])!
            let soundMode = Int(message[message.index(message.startIndex, offsetBy: 8) ..< message.index(message.startIndex, offsetBy: 9)])!
            let newSoundVolume = Int(message[message.index(message.startIndex, offsetBy: 9) ..< message.endIndex])!
            
            if(powerStatus == 0) {
                intMessage.append(btMessageIn.BT_MESSAGE_IN_SYSTEM_OFF.rawValue)
            }
            else {
                intMessage.append(btMessageIn.BT_MESSAGE_IN_SYSTEM_ON.rawValue)
                switch(bubblesMode) {
                case 0:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_MIXED_BUBBLES.rawValue)
                    break
                    
                case 1:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SMALL_BUBBLES.rawValue)
                    break
                    
                case 2:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_BIG_BUBBLES.rawValue)
                    break
                    
                case 3:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SMALL_AND_BIG_BUBBLES.rawValue)
                    break
                    
                case 4:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_PYRAMID_BUBBLES.rawValue)
                    break
                    
                case 5:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_PILLAR_BUBBLES.rawValue)
                    break
                default:
                    print("BubbleWallViewController: ProcessIncomingBtMessage: Error, incorrect bubble Mode. Value was" + String(bubblesMode))
                }
                
                switch(lightsMode) {
                case 0:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_MIXED_LIGHTS.rawValue)
                    break
                    
                case 1:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_RAINBOW_LIGHTS_1.rawValue)
                    break
                    
                case 2:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_RAINBOW_LIGHTS_2.rawValue)
                    break
                    
                case 3:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_FADE_LIGHTS.rawValue)
                    break
                    
                case 4:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_FADE_SPLIT_LIGHTS.rawValue)
                    break
                    
                case 5:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_CUSTOM_LIGHTS.rawValue)
                    break
                default:
                    print("BubbleWallViewController: ProcessIncomingBtMessage: Error, incorrect lights Mode. Value was" + String(lightsMode))
                    
                }
            }
            
           
            if(soundPowerStatus == 0) {
                intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_OFF.rawValue)
            } else {
           
                intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_ON.rawValue)
                
                if(soundMute == 0) {
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_UNMUTE.rawValue)
                } else {
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_MUTE.rawValue)
                }
                
                if(soundPlay == 0) {
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_PAUSE.rawValue)
                } else {
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_PLAY.rawValue)
                }
                
                switch(soundMode) {
                case 0:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_USB.rawValue)
                    break
                case 1:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_AUX.rawValue)
                    break
                case 2:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_BT.rawValue)
                    break
                case 3:
                    intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_SD.rawValue)
                    break
                default:
                    print("BubbleWallViewController: ProcessIncomingBtMessage: Error, incorrect sound Mode. Value was" + String(soundMode))
                }
            }
                soundVolume = newSoundVolume
                intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_VOLUME_CHANGE.rawValue)
 
            
        }
        else if(message.contains(HARDWARE_VERSION_NUMBER)) { // If the message was for indicating hardware version of Arduino code
            hardwareVersionMajor = Int(message[message.index(message.startIndex, offsetBy: 6) ..< message.index(of: ".")!])!
            hardwareVersionMinor = Int(message[message.index(after: message.index(of: ".")!) ..< message.endIndex])!
            print("ViewControllerBubbleWall: processIncomingBtMessage: Received harware version " + String(hardwareVersionMajor) + "." + String(hardwareVersionMinor))
            
            return;
        }
        else if(message.contains(SOUND_LEVEL)){ // If the message was for indicating the sound level of BubbleWall speaker
            soundVolume = Int(message[message.index(message.startIndex, offsetBy: 10) ..< message.endIndex])!
            intMessage.append(btMessageIn.BT_MESSAGE_IN_SOUND_VOLUME_CHANGE.rawValue)
        }
        else {
            //Makes sure that after this point, message only contains numbers
            if(Int(message) == nil){
                print("ViewControllerBubbleWall: processIncomingBtMessage: ERROR, message contains not numeric symbols")
                return
            }
            
            intMessage.append(Int(message)!)
        }
        
        for msg in intMessage {
            if(msg == btMessageIn.BT_MESSAGE_IN_SYSTEM_ON.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting Button to Off")
                arduinoPowerStatus = true;
                button_on_off.firstColor = GlobalColors.offButtonStartColor
                button_on_off.secondColor = GlobalColors.offButtonMiddleColor
                button_on_off.thirdColor = GlobalColors.offButtonEndColor
                button_on_off.setTitle("Off", for: .normal)
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SYSTEM_OFF.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting Button to On")
                
                if(button_sleep.titleLabel!.text == GlobalStrings.CANCEL_SLEEP) {
                    messageSender(message: String(btMessageOut.BT_MESSAGE_OUT_CANCEL_SLEEP.rawValue))
                }
                
                arduinoPowerStatus = false;
                button_on_off.firstColor = GlobalColors.onButtonStartColor
                button_on_off.secondColor = GlobalColors.onButtonMiddleColor
                button_on_off.thirdColor = GlobalColors.onButtonEndColor
                button_on_off.setTitle("On", for: .normal)
                
                setLightsButtonsUnpressed()
                setBubbleButtonsUnpressed()
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_MANUAL_MODE.rawValue){
                // If manual button is turned on, just alert the user and exit the View Controller
                print("ViewControllerBubbleWall: processIncomingBtMessage: Got notification that Bubble Wall is in manual mode.")
                self.backToHomeViewDelegate!.backToHomeView(status: GlobalStrings.MANUAL_MODE_IS_ON)
                disconnectFromBt()
                
                // I delay the popView call by 1 second because I was having trouble when this was being called too early and  view was not being dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { self.navigationController?.popViewController(animated: true)})
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SLEEP_MODE_STARTED.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting countDownTimer instead of sleep button")
                button_sleep.setTitle(GlobalStrings.CANCEL_SLEEP, for: .normal)
                countDownTimerProgressBar.isHidden = false
                
                countdownTimer.setTimer(hours: 0, minutes: 0, seconds: SLEEP_TIMER_SECONDS)
                countDownTimerProgressBar.setProgressBar(hours: 0, minutes: 0, seconds: SLEEP_TIMER_SECONDS)
                countdownTimer.start()
                countDownTimerProgressBar.start()
            }
            else if(msg == btMessageIn.Bt_MESSAGE_IN_SLEEP_ACHIEVED.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting Sleep button instead of countDownTimer")
                countDownTimerProgressBar.stop()
                countdownTimer.stop()
                countDownTimerProgressBar.isHidden = true
                button_sleep.setTitle(GlobalStrings.SLEEP, for: .normal)
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SLEEP_CANCELLED.rawValue) {
                if(button_sleep.titleLabel!.text == GlobalStrings.CANCEL_SLEEP) {
                    print("ViewControllerBubbleWall: processIncomingBtMessage: Sleep cancelled")
                    countDownTimerProgressBar.stop()
                    countdownTimer.stop()
                    countDownTimerProgressBar.isHidden = true
                    button_sleep.setTitle(GlobalStrings.SLEEP, for: .normal)
                }
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SMALL_BUBBLES.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting small bubbles button to pressed")
                setBubbleButtonsUnpressed()
                button_small_bubble.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_BIG_BUBBLES.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting big bubbles button to pressed")
                setBubbleButtonsUnpressed()
                button_big_bubble.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SMALL_AND_BIG_BUBBLES.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting small and big bubbles button to pressed")
                setBubbleButtonsUnpressed()
                button_small_plus_big_bubble.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_PYRAMID_BUBBLES.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting pyramid bubbles button to pressed")
                setBubbleButtonsUnpressed()
                button_pyramid_bubble.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_PILLAR_BUBBLES.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting pillar bubbles button to pressed")
                setBubbleButtonsUnpressed()
                button_pillar_bubble.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_MIXED_BUBBLES.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting mixed bubbles button to pressed")
                setBubbleButtonsUnpressed()
                button_bubble_mix_mode.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_RAINBOW_LIGHTS_1.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting rainbow lights 1 button to pressed")
                setLightsButtonsUnpressed()
                button_lights_rainbow_1.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_RAINBOW_LIGHTS_2.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting rainbow lights 2 button to pressed")
                setLightsButtonsUnpressed()
                button_lights_rainbow_2.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_FADE_LIGHTS.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting fade lights button to pressed")
                setLightsButtonsUnpressed()
                button_lights_fade.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_FADE_SPLIT_LIGHTS.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting fade split lights button to pressed")
                setLightsButtonsUnpressed()
                button_lights_fade_split.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_CUSTOM_LIGHTS.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting custom lights button to pressed")
                setLightsButtonsUnpressed()
                button_lights_custom_color.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_MIXED_LIGHTS.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting mixed lights button to pressed")
                setLightsButtonsUnpressed()
                button_lights_mix_mode.borderColor = GlobalColors.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_ON.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound power button to Off")
                soundSystemPowerStatus = true;
                button_sound_on_off.setImage( UIImage.init(named: "icon_sound_off"), for: .normal)
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_OFF.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound power button to On")
                soundSystemPowerStatus = false;
                button_sound_on_off.setImage( UIImage.init(named: "icon_sound_on"), for: .normal)
                setSoundModeButtonsToUnpressed()
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_VOLUME_CHANGE.rawValue || msg == btMessageIn.BT_MESSAGE_IN_SOUND_MUTE.rawValue || msg == btMessageIn.BT_MESSAGE_IN_SOUND_UNMUTE.rawValue) {
                
                if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_UNMUTE.rawValue){
                    soundMuteStatus = false
                }
                else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_MUTE.rawValue){
                    soundMuteStatus = true
                }
                
                if(soundMuteStatus){
                    print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound level to mute icon")
                    button_sound_volume_mute.setImage( UIImage.init(named: "icon_sound_mute"), for: .normal)
                }
                else if(soundVolume == 0){
                    print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound level icon to sound level 0")
                    button_sound_volume_mute.setImage( UIImage.init(named: "icon_sound_volume_level_0"), for: .normal)
                }
                else if(soundVolume > 0 && soundVolume < 13){
                    print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound level icon to sound level 1")
                    button_sound_volume_mute.setImage( UIImage.init(named: "icon_sound_volume_level_1"), for: .normal)
                }
                else if(soundVolume >= 13 && soundVolume < 23){
                    print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound level icon to sound level 2")
                    button_sound_volume_mute.setImage( UIImage.init(named: "icon_sound_volume_level_2"), for: .normal)
                }
                else if(soundVolume >= 23 && soundVolume < 31){
                    print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound level icon to sound level 3")
                    button_sound_volume_mute.setImage( UIImage.init(named: "icon_sound_volume_level_3"), for: .normal)
                }
                else if(soundVolume == 31){
                    print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound level icon to sound level max")
                    button_sound_volume_mute.setImage( UIImage.init(named: "icon_sound_volume_level_max"), for: .normal)
                }
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_PLAY.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound play/pause button to ")
                button_sound_play_pause.setImage(UIImage.init(named: "icon_sound_pause"), for: .normal)
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_PAUSE.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound play/pause button to play")
                button_sound_play_pause.setImage(UIImage.init(named: "icon_sound_play"), for: .normal)
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_USB.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound mode to usb")
                setSoundModeButtonsToUnpressed()
                button_sound_mode_usb.borderColor = UIColor.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_AUX.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound mode to aux")
                setSoundModeButtonsToUnpressed()
                button_sound_mode_aux.borderColor = UIColor.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_BT.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound mode to bt")
                setSoundModeButtonsToUnpressed()
                button_sound_mode_bt.borderColor = UIColor.red
            }
            else if(msg == btMessageIn.BT_MESSAGE_IN_SOUND_SD.rawValue){
                print("ViewControllerBubbleWall: processIncomingBtMessage: Setting sound mode to sd")
                setSoundModeButtonsToUnpressed()
                button_sound_mode_sd.borderColor = UIColor.red
            }
            
        }
       
    }
    
    
    func setLightsButtonsUnpressed(){
        button_lights_rainbow_1.borderColor = GlobalColors.black
        button_lights_rainbow_2.borderColor = GlobalColors.black
        button_lights_fade.borderColor = GlobalColors.black
        button_lights_fade_split.borderColor = GlobalColors.black
        button_lights_custom_color.borderColor = GlobalColors.black
        button_lights_mix_mode.borderColor = GlobalColors.black
    }
    
    
    func setBubbleButtonsUnpressed(){
        button_small_bubble.borderColor = GlobalColors.black
        button_big_bubble.borderColor = GlobalColors.black
        button_small_plus_big_bubble.borderColor = GlobalColors.black
        button_pyramid_bubble.borderColor = GlobalColors.black
        button_pillar_bubble.borderColor = GlobalColors.black
        button_bubble_mix_mode.borderColor = GlobalColors.black
    }
    
    
    func setSoundModeButtonsToUnpressed(){
        button_sound_mode_usb.borderColor = UIColor.clear
        button_sound_mode_sd.borderColor = UIColor.clear
        button_sound_mode_bt.borderColor = UIColor.clear
        button_sound_mode_aux.borderColor = UIColor.clear
    }
    
    
    // Used for some of the buttons to make sure that the system is on before sending a message
    func messageSender(message: String){
        if(!arduinoPowerStatus){
            
            let alert = UIAlertController(title: "Bubble Wall Is Turned Off", message: "Do you want to turn on the Bubble Wall ?", preferredStyle: UIAlertControllerStyle.alert)
            
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
        else{
            if(btServices != nil){
                btServices!.writeToBt(dataToSend: message)
            }
            else{
                print("ViewControllerBubbleWall: messageSender: ERROR. btCommunication was nil")
            }
        }
    }
    
    // Used for sound buttons to make sure that the speaker is turned on before sending a message
    func soundMessageSender(message: String){
        if(!soundSystemPowerStatus){
            
            let alert = UIAlertController(title: "Speaker Is Turned Off", message: "Do you want to turn on the speaker ?", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Default action"), style: .`default`, handler: { _ in
                self.btServices!.writeToBt(dataToSend: String(btMessageOut.BT_MESSAGE_OUT_SOUND_ON_OFF.rawValue))
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
