//
//  HomeScreenViewController.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 9/14/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import CoreBluetooth


// MARK: - Protocols
// ------------------------------------------------------------------------------------------------------------------------------

// Receive messages from child ViewControllers to display when child ViewControllers finish their job
protocol BackToHomeViewDelegate{
    func backToHomeView(status: String)
}
// ------------------------------------------------------------------------------------------------------------------------------


//Handles displaying of found peripheral devices and navigating to other activities whien clicked on peripheral
class HomeScreenViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ReceiveBluetoothPeripheralDelegate, ReceiveBluetoothIncomingDataDelegate, BackToHomeViewDelegate{
    
    // MARK: - Global constants
    // ------------------------------------------------------------------------------------------------------------------------------
    private let btServices = BtServices()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    private var statusLabelHider: DispatchWorkItem? = nil
    private var btPeripheralTimer: Timer!
    private var btPeripheralList = [BtPeripheral]()
    // ------------------------------------------------------------------------------------------------------------------------------
    
    

    // MARK: - IBOutlets
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBOutlet var tableView: UITableView!
    @IBOutlet var statusLabel: UILabel!
    // ------------------------------------------------------------------------------------------------------------------------------
    
    

    // MARK: - IBActions
    // ------------------------------------------------------------------------------------------------------------------------------
    @IBAction func helpPageButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "homeScreenToHelpPageSegue", sender: self)
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Structs
    // ------------------------------------------------------------------------------------------------------------------------------
    struct BtPeripheral {
        var bluetoothPeripheral: CBPeripheral
        var timeSinceLastUpdate: Double
        
        init(btPeripheral: CBPeripheral, time: Double){
            bluetoothPeripheral = btPeripheral
            timeSinceLastUpdate = time
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------

    
    
    // MARK: - Override methods
    // ------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btServices.setReceiveBluetoothPeripheralDelegate(incomingDelegate: self)
        btServices.setReceiveBluetoothIncomingDataDelegate(incomingDelegate: self)
        
        statusLabel.isHidden = true
        
        statusLabelHider = DispatchWorkItem {
            self.statusLabel.isHidden = true
        }
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Used to get notifications when app goes into background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if(statusLabel.isHidden == false &&  statusLabel.text == GlobalStrings.MANUAL_MODE_IS_ON){
            let alert = UIAlertController(title: "Alert: Manual button is turned on", message: GlobalStrings.MANUAL_BUTTON_IS_TURNED_ON_MESSAGE, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert,   animated: false, completion: nil)
        }
        
        if(btPeripheralTimer == nil) {
            btPeripheralTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkIfPeripheralTimersAreExpired), userInfo: nil, repeats: true)
        }
        btPeripheralList.removeAll()
        tableView.reloadData()
        
        btServices.startScanningForBtPeripherals()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        
        if(btPeripheralTimer != nil) {
            btPeripheralTimer.invalidate();
            btPeripheralTimer = nil
        }
        
        btServices.stopScanningForDevices()
    }
    
    // Handles the setup before segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "mainScreenToBubbleWall"){
            let destViewController : BubbleWallViewController = segue.destination as! BubbleWallViewController
            destViewController.btServices = btServices
            destViewController.backToHomeViewDelegate = self
            
            if let indexPath =  tableView.indexPathForSelectedRow {
                destViewController.bluetoothPeripheral = btPeripheralList[indexPath.row].bluetoothPeripheral
            }
        }
        else if(segue.identifier == "mainScreenToBubblePillar"){
            let destViewController : BubblePillarViewController = segue.destination as! BubblePillarViewController
            destViewController.btServices = btServices
            destViewController.backToHomeViewDelegate = self
            
            if let indexPath =  tableView.indexPathForSelectedRow {
                destViewController.bluetoothPeripheral = btPeripheralList[indexPath.row].bluetoothPeripheral
            }
        }
        else if(segue.identifier == "mainScreenToCenterpiece"){
            let destViewController : BubbleCenterpieceViewController = segue.destination as! BubbleCenterpieceViewController
            destViewController.btServices = btServices
            destViewController.backToHomeViewDelegate = self
            
            if let indexPath =  tableView.indexPathForSelectedRow {
                destViewController.bluetoothPeripheral = btPeripheralList[indexPath.row].bluetoothPeripheral
            }
        }
        else if(segue.identifier == "homeScreenToHelpPageSegue") {
            let destViewController: HelpPageViewController = segue.destination as! HelpPageViewController
            destViewController.callerName = destViewController.CALLER_HOME_SCREEN
        }
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Delegate/protocol listener methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Displays an alert to the user if we are having trouble accessing the bluetooth
    func receiveBluetoothIncomingData(message: String) {
        if(message == btServices.PHONE_DOES_NOT_SUPPORT_BLE) {
            let alert = UIAlertController(title: "Alert", message: "Your phones does not support Bluetooth 4.0. This application requires BLE in order to work.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else if(message == btServices.CAN_NOT_AUTORIZE_BLUETOOTH) {
            let alert = UIAlertController(title: "Alert", message: "Can`t get autorization to access the phone`s Bluetooth. This application requires Bluetooth autorization in order to work.",
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    // Receives bt peripherals from BtService
    func receiveBluetoothPeripheral(peripheral: CBPeripheral) {
        if(!doesBtDeviceListContainsBtDevice(peripheral: peripheral)){ //if we do not have the peripheral already, add it
            print("HomeScreenViewController: receiveBluetoothPeripheral: " + peripheral.name!)
            btPeripheralList.append(BtPeripheral(btPeripheral: peripheral,time: NSDate().timeIntervalSince1970))
            tableView.reloadData()
        }
        else{ // if we have the peripheral, update the timer
            let indexOfBtPeripheral = btDeviceListIndexOf(peripheral: peripheral)
            if(indexOfBtPeripheral != -1){
                btPeripheralList[indexOfBtPeripheral].timeSinceLastUpdate = NSDate().timeIntervalSince1970
            }
        }
    }
    
    // Displays messages that are sent by child ViewControllers
    func backToHomeView(status: String) {
        statusLabel.isHidden = false
        statusLabel.text = status
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: statusLabelHider!)
    }

    
    // Handles the tableView click and takes us to child ViewControllers.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        btServices.stopScanningForDevices()
        
        if (btPeripheralList[indexPath.row].bluetoothPeripheral.name!.contains("BubbleWall")) {
            print("HomeScreenViewController: tableView didSelectRowAt: We are going to BubbleWall activity")
            performSegue(withIdentifier: "mainScreenToBubbleWall", sender: self)
        } else if(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.contains("BubblePillar")) {
            print("HomeScreenViewController: tableView didSelectRowAt: We are going to BubblePillar activity")
            performSegue(withIdentifier: "mainScreenToBubblePillar", sender: self)
        } else if(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.contains("BubbleCenCon")) {
            print("HomeScreenViewController: tableView didSelectRowAt: We are going to Centerpiece activity")
            performSegue(withIdentifier: "mainScreenToCenterpiece", sender: self)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btPeripheralList.count
    }
    
    
    // Handles the tableView setup such as text and icon next to the text.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        
        if(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.contains("BubbleWall")) {
            let index = btPeripheralList[indexPath.row].bluetoothPeripheral.name!.index(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.startIndex, offsetBy: 10)
            let bubbleWallNumber = btPeripheralList[indexPath.row].bluetoothPeripheral.name![index ..< btPeripheralList[indexPath.row].bluetoothPeripheral.name!.endIndex]
            
            cell.tableViewText.text = "Bubble Wall " + String(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.last!);
            cell.tableViewImage.image = UIImage(named: "bw_icon_" + bubbleWallNumber)
        }
        else if(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.contains("BubblePillar")) {
            let index = btPeripheralList[indexPath.row].bluetoothPeripheral.name!.index(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.startIndex, offsetBy: 12)
            let bubblePillarNumber = btPeripheralList[indexPath.row].bluetoothPeripheral.name![index ..< btPeripheralList[indexPath.row].bluetoothPeripheral.name!.endIndex]
            
            
            
            cell.tableViewText.text = "Bubble Pillar " + String(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.last!);
            cell.tableViewImage.image = UIImage(named: "bp_icon_" + bubblePillarNumber)
        }
        else if(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.contains("BubbleCenCon")) {
            let index = btPeripheralList[indexPath.row].bluetoothPeripheral.name!.index(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.startIndex, offsetBy: 12)
            let bubblePillarNumber = btPeripheralList[indexPath.row].bluetoothPeripheral.name![index ..< btPeripheralList[indexPath.row].bluetoothPeripheral.name!.endIndex]
            
            cell.tableViewText.text = "Centerpiece " + String(btPeripheralList[indexPath.row].bluetoothPeripheral.name!.last!);
            cell.tableViewImage.image = UIImage(named: "cp_icon_" + bubblePillarNumber)
        }
        
        return cell
    }
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    

    
    @objc func appMovedToBackground() {
        
        // If HomeScreenView is loaded
        if(self.viewIfLoaded!.window != nil) {
            if(btPeripheralTimer != nil) {
                btPeripheralTimer.invalidate();
                btPeripheralTimer = nil
            }
            
            btServices.stopScanningForDevices()
        }
    }
    
    @objc func appMovedToForeground() {
        // If HomeScreenView is loaded
        if(self.viewIfLoaded!.window != nil) {
            if(btPeripheralTimer == nil) {
                btPeripheralTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkIfPeripheralTimersAreExpired), userInfo: nil, repeats: true)
            }
            btPeripheralList.removeAll()
            tableView.reloadData()
            
            btServices.startScanningForBtPeripherals()
        }
    }
    
    // Chechs all the peripherals in btPeripheralList to make sure that none of them have update time less than 2 seconds
    // If any of the times are less than 2 seconds, peripheral is removed from list.
    @objc private func checkIfPeripheralTimersAreExpired(){
        var peripheralIndex: Int = 0
        var itemsToRemove = [Int]()
        // Check which items need to be removed
        for btPeripheral in btPeripheralList {
            if(NSDate().timeIntervalSince1970 - btPeripheral.timeSinceLastUpdate > 3.0){
                itemsToRemove.append(peripheralIndex)
            }
            peripheralIndex += 1
        }
        
        //remove the items that we found above
        for index in itemsToRemove {
            btPeripheralList.remove(at: index)
            tableView.reloadData()
        }
    }
    
    // Checks if peripheral exists in btPeripheralList
    func doesBtDeviceListContainsBtDevice(peripheral: CBPeripheral) -> Bool{
        for btPeripheral in btPeripheralList{
            if(btPeripheral.bluetoothPeripheral.isEqual(peripheral)){
                return true
            }
        }
        
        return false
    }
    
    // Returns the index of given peripheral in btPeripheralList. Returns -1 if it does not exist
    func btDeviceListIndexOf(peripheral: CBPeripheral) -> Int{
        var peripheralIndex: Int = 0
        for btPeripheral in btPeripheralList{
            if(btPeripheral.bluetoothPeripheral.isEqual(peripheral)){
                return peripheralIndex
            }
            peripheralIndex += 1
        }
        
        return -1
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
