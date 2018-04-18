//
//  Btservices.swift
//  Bubble_Hub
//
//  Created by Hovo Menejyan on 8/27/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import CoreBluetooth

// MARK: - Protocols
// ------------------------------------------------------------------------------------------------------------------------------

// Used to send discovered peripherals to HomePageViewController
protocol ReceiveBluetoothPeripheralDelegate{
    func receiveBluetoothPeripheral(peripheral: CBPeripheral)
}

// Used to send bluetooth state and bluetooth received messages to other ViewControllers
protocol ReceiveBluetoothIncomingDataDelegate{
    func receiveBluetoothIncomingData(message: String)
}
// ------------------------------------------------------------------------------------------------------------------------------

// Provide services such as Bluetooth peripheral discovery, connection with peripheral and data transfer to and from peripheral to other classes
class BtServices: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Global constants
    // ------------------------------------------------------------------------------------------------------------------------------
    private let BEAN_SERVICE_UUID = CBUUID(string: "ffe0")
    private let BEAN_CHARACTERISTIC_UUID = CBUUID(string: "ffe1")
    let CONNECTION_ESTABLISHED: String = "net.california_design.bubble_hub.CONNECTION_ESTABLISHED"
    let CONNECTION_LOST: String = "net.california_design.bubble_hub.CONNECTION_LOST"
    
    let FAILED_TO_CONNECT: String = "net.california_design.bubble_hub.bluetooth_connection.FAILED_TO_CONNECT"
    let SERVICES_DISCOVERED: String = "net.california_design.bubble_hub.bluetooth_connection.SERVICES_DISCOVERED"
    let FAILED_TO_DISCOVER_SERVICES: String = "net.california_design.bubble_hub.bluetooth_connection.FAILED_TO_DISCOVER_SERVICES"
    let CHARACTERISTICS_DISCOVERED: String = "net.california_design.bubble_hub.bluetooth_connection.CHARACTERISTICS_DISCOVERED"
    let FAILED_TO_DISCOVER_CHARACTERISTICS: String = "net.california_design.bubble_hub.bluetooth_connection.FAILED_TO_DISCOVER_CHARACTERISTICS"
    
    let PHONE_DOES_NOT_SUPPORT_BLE: String = "net.california_design.bubble_hub.PHONE_DOES_NOT_SUPPORT_BLE"
    let CAN_NOT_AUTORIZE_BLUETOOTH: String = "net.california_design.bubble_hub.CAN_NOT_AUTHORIZE_BLUETOOTH"
    private let BLUETOOTH_SERVICE:CBUUID  = CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
    private let BLUETOOTH_CHARACTERISTIC: CBUUID  = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
    // ------------------------------------------------------------------------------------------------------------------------------
    
    

    // MARK: - Global variables
    // ------------------------------------------------------------------------------------------------------------------------------
    private var isScanning = false
    private var manager:CBCentralManager!
    private var m_peripheral:CBPeripheral? = nil
    private var txCharacteristic: CBCharacteristic!
    private var receiveBluetoothPeripheralDelegate:ReceiveBluetoothPeripheralDelegate?
    private var receiveBluetoothIncomingDataDelegate:ReceiveBluetoothIncomingDataDelegate?
    private var didConnectionTimedOut = true
    private var didWeDiscoveredServices = false
    private var numTimesTriedToDiscoverServices: Int = 0
    
    // ------------------------------------------------------------------------------------------------------------------------------
    
    
    
    // MARK: - Delegate/protocol listener methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    // Receives the state of phone`s Bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        switch (central.state)
        {
        case . unsupported:
            print("BtServices: centralManagerDidUpdateState: BLE is unsupported")
            receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: PHONE_DOES_NOT_SUPPORT_BLE)
        case.unauthorized:
            print("BtServices: centralManagerDidUpdateState: BLE is unauthorised")
            receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: CAN_NOT_AUTORIZE_BLUETOOTH)
        case.unknown:
            print("BtServices: centralManagerDidUpdateState: BLE is unknown")
        case.resetting:
            print("BtServices: centralManagerDidUpdateState: BLE is resetting")
        case.poweredOff:
            print("BtServices: centralManagerDidUpdateState: BLE is powered off")
        case.poweredOn:
            print("BtServices: centralManagerDidUpdateState: BLE is powered on")
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    // Gets called when we discover a peripheral device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // TODO Check when this might be nil.  (For  example only 1 device arround and it  is connected to another phone)
        if(peripheral.name != nil) {
            print("--- Peripheral: " + peripheral.name!)
            if (receiveBluetoothPeripheralDelegate != nil) {
                if(peripheral.name!.contains("BubblePillar") || peripheral.name!.contains("BubbleWall") || peripheral.name!.contains("CenCon")){
                    receiveBluetoothPeripheralDelegate!.receiveBluetoothPeripheral(peripheral: peripheral)
                }
            }
            else{
                print("--- Periplhera: nil")
            }
        }
    }
    
    // Gets called when we connect to the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BtServices: centralManager didConnectPeripheral: Connection established");
        receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: CONNECTION_ESTABLISHED)
        
        m_peripheral!.delegate = self
        
        //Disable the connectionTimedOut async task
        didConnectionTimedOut = false
        
        // I think discoverServices works better if called on main thread and after waiting for about 600ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: { self.discoverServices() })
        
        // Here we try 3 more times to discover the services. If the 3rd time fails, we just stop trying.
        //Sometimes Bluetooth service discovery takes a long time or it fails without notification
        //The below code is here to automatically close this activity if either of those situations takes place.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: {
           
            if(!self.didWeDiscoveredServices) {
                 print("--------------- 1st Try")
                self.tryToDiscoverServicesAgain()
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.6, execute: {
            
            if(!self.didWeDiscoveredServices) {
                print("--------------- 2nd Try")
                self.tryToDiscoverServicesAgain()
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.6, execute: {
            
            if(!self.didWeDiscoveredServices) {
                print("--------------- 3rd Try")
                self.tryToDiscoverServicesAgain()
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.6, execute: {
            if(!self.didWeDiscoveredServices) {
                print("--------------- 4th Try")
                self.tryToDiscoverServicesAgain()
            }
        })
    }
    
    
    // Gets called when we disconnect from the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if(peripheral == m_peripheral){
            print("BtServiceClass: didDisconnectPeripheral: Got disconnected from bluetooth")
            
            //Disable the connectionTimedOut async task
            didConnectionTimedOut = false
            
            receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: CONNECTION_LOST)
        }
    }
    
    
    // Gets called when we fail to connect to the peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral){
        print("BtServices: centralManager didFailToConnect: Failed to establish communication")
        
        //Disable the connectionTimedOut async task
        didConnectionTimedOut = false
        
        receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: FAILED_TO_CONNECT)
    }
    
    
    // Gets called when we discover services of the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        //Disable the tryToDiscoverServicesAgain async task
        didWeDiscoveredServices = true
        
        if(peripheral.services!.count > 0) {
            for service in peripheral.services! {
                let thisService = service as CBService
                
                print("BtServices: peripheral didDiscoverServices: Got service " + service.uuid.uuidString)
                if (service.uuid == BEAN_SERVICE_UUID) {
                    let characteristics = [BLUETOOTH_CHARACTERISTIC]
                    m_peripheral!.discoverCharacteristics( characteristics, for: thisService)
                    receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: SERVICES_DISCOVERED)
                }
            }
        }
        else {
            receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: FAILED_TO_DISCOVER_SERVICES)
        }
    }
    
    // Gets called when we discover characterisctis of the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if(service.characteristics!.count > 0) {
            for characteristic in service.characteristics! {
                let thisCharacteristic = characteristic as CBCharacteristic
                
                print("BtServices: peripheral didDiscoverCharacteristicsFor: Got characteristic " + thisCharacteristic.uuid.uuidString)
                if (thisCharacteristic.uuid == BEAN_CHARACTERISTIC_UUID) {
                    txCharacteristic = thisCharacteristic
                    m_peripheral!.setNotifyValue(true,for: thisCharacteristic)
                    
                    receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: CHARACTERISTICS_DISCOVERED)
                }
            }
        }
        else {
            receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: FAILED_TO_DISCOVER_CHARACTERISTICS)
        }
        
    }
    
    // Gets called when we receive update for characteristic value (We use this to retrieve incoming bluetooth data)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == BEAN_CHARACTERISTIC_UUID {
            let incomingMessage =  String(bytes: characteristic.value!, encoding: String.Encoding.utf8)
            
            if(incomingMessage != nil && !incomingMessage!.isEmpty){
                print("BtServices: peripheral didUpdateValueFor: " + incomingMessage!)
                receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: incomingMessage!)
            }
        }
    }
    
    // ------------------------------------------------------------------------------------------------------------------------------
    
   
    
    
    // MARK: - Helper methods
    // ------------------------------------------------------------------------------------------------------------------------------
    
    func tryToDiscoverServicesAgain() {
            if(numTimesTriedToDiscoverServices >= 3) {
                receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: FAILED_TO_DISCOVER_SERVICES)
                return;
            }
            
            numTimesTriedToDiscoverServices += 1
            
            discoverServices()
    }
    
    // Discover services of m_peripheral
    func discoverServices() {
        let serviceUUID = [BLUETOOTH_SERVICE]
        m_peripheral!.discoverServices(serviceUUID)
        print("BluetoothConnection: discoverServices: Attempt #" + String(numTimesTriedToDiscoverServices + 1) + " to start service discovery")
    }
    
    
    func setPeripheral(peripheral: CBPeripheral){
        m_peripheral = peripheral
    }
    
    
    func setReceiveBluetoothPeripheralDelegate(incomingDelegate: ReceiveBluetoothPeripheralDelegate){
        receiveBluetoothPeripheralDelegate = incomingDelegate
    }
    
    
    func setReceiveBluetoothIncomingDataDelegate(incomingDelegate: ReceiveBluetoothIncomingDataDelegate){
        receiveBluetoothIncomingDataDelegate = incomingDelegate
    }
    
    
    func startScanningForBtPeripherals() {
        if(!isScanning) {
            isScanning = true
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    
    func stopScanningForDevices(){
        if(isScanning) {
            isScanning = false
            manager.stopScan()
        }
    }
    
    
    func connectToPeripheral(){
        stopScanningForDevices()
        manager.connect(m_peripheral!, options: nil)
        
        //Sometimes Bluetooth connection takes a long time or it fails without notification
        //The below code is here to automatically close this activity if this situations takes place.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            if(self.didConnectionTimedOut) {
                self.receiveBluetoothIncomingDataDelegate?.receiveBluetoothIncomingData(message: self.FAILED_TO_CONNECT)
            }
        })
    }
    
    
    func disconnectFromPeripheralAndResetVariables(){
        if(m_peripheral != nil){
            manager.cancelPeripheralConnection(m_peripheral!)
            m_peripheral = nil
        }
    }
    
    
    // Handles the sending of Bluetooth data
    func writeToBt(dataToSend : String){
        //Arduino expects data sent to him to be terminated by newline
        let data = ( (dataToSend + "\n") as NSString).data(using: String.Encoding.utf8.rawValue)
        print("BtServices: writeToBt: Sending message: " + dataToSend)
        
        if(m_peripheral == nil){
            print("BtServices: writeToBt: ERROR. m_peripheral is nil")
            return
        }
        if(data == nil){
            print("BtServices: writeToBt: ERROR. data is nil")
            return
        }
        
        m_peripheral!.writeValue(data!, for: txCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
    }
    // ------------------------------------------------------------------------------------------------------------------------------
}
