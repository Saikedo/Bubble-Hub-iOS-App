//
//  BtCommunication.swift
//  bubble_bubble
//
//  Created by Hovo Menejyan on 10/1/17.
//  Copyright © 2017 Hovo Menejyan. All rights reserved.
//

import UIKit
import CoreBluetooth

class BtCommunication: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    
    var txCharacteristic: CBCharacteristic!
    
    
    let BubbleWallBluetoothName = "TestBluetooth"
    let BEAN_SERVICE_UUID =
        CBUUID(string: "ffe0")
    let BEAN_CHARACTERISTIC_UUID =
        CBUUID(string: "ffe1")
    
    
    func setPeripheral(peripheral: CBPeripheral){
        self.peripheral = peripheral
    }
    
    func connectToBtDevice(){
        
        manager = CBCentralManager(delegate: self, queue: nil)
        self.peripheral.delegate = self
    }
    ////////////////////////////////////////////////////////////////////
    
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        
        switch (central.state)
        {
        case . unsupported:
            print("BLE is unsupported")
        case.unauthorized:
            print("BLE is unauthorised")
        case.unknown:
            print("BLE is unknown")
        case.resetting:
            print("BLE is resetting")
        case.poweredOff:
            print("BLE is powered off")
        case.poweredOn:
            print("BLE is powered on")
            manager.connect(peripheral, options: nil)
            print("Trying to establish communication to ", peripheral.name!)

        }
    }
    
    
    //This function never gets called
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        print("We are connected to BT");
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral	){
        print("Failed to establish communication")
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Trying to discover services");
        
        
        
        for service in peripheral.services! {
            let thisService = service as CBService
            
            print("Got service " + service.uuid.uuidString)
            if (service.uuid == BEAN_SERVICE_UUID) {
                peripheral.discoverCharacteristics( nil, for: thisService)
                print("Trying to discover the characteristics of the service " + service.uuid.uuidString)
            }
        }
    }
}
