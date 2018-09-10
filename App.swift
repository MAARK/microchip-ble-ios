//
//  App.swift
//  Poolboy demo app 
// 
//  FOR USE WITH SWIFT 2.0 
// 
//  Created by Richard Wagner on 1/14/16.
//  Copyright © 2016 MAARK. All rights reserved.
//

import SwiftyJSON
import CoreBluetooth

let remotePHWarning = "Low pH Value Warning (6.8). A pH value below 7.0 indicates that the water is in a corrosive condition."

let peripheralDiscovered = "peripheralDiscovered"
let peripheralConnectSuccess = "peripheralConnectSuccess"
let peripheralConnectFailed = "peripheralConnectFailed"
let notifyPeripheralNoMicrochipBLEServicesFound = "peripheralNoMicrochipBLEServicesFound"
let notifyPeripheralNoMicrochipBLECharacteristicsFound = "peripheralNoMicrochipBLECharacteristicsFound"
let notifyBluetoothDataReceived = "bluetoothDataReceived"
let notifyBluetoothNotificationReceived = "bluetoothNotificationReceived"

class App: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    static let sharedInstance = App()
        
    let currentPeripheralDevice: PeripheralDevice = PeripheralDevice()
    
    var currentPoolData:PoolData = PoolData()
    
    fileprivate let mchpServiceUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000300")
    fileprivate let mchpTxUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000301")
    fileprivate let mchpRxUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000301")
    fileprivate let mchpRemoteTxUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A0003FF")
    fileprivate let mchpRemoteRxUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A0003FF")
    fileprivate let isscServiceUUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    fileprivate let isscTxUUID = CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3")
    fileprivate let isscRxUUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    
    fileprivate var customServiceUUID = CBUUID(string: "00000000-0000-0000-0000-000000000000")
    fileprivate var customTxUUID = CBUUID(string: "00000000-0000-0000-0000-000000000000")
    fileprivate var customRxUUID = CBUUID(string: "00000000-0000-0000-0000-000000000000")
    fileprivate var characteristicTxInstance: CBCharacteristic?
    fileprivate var characteristicRxInstance: CBCharacteristic?
    fileprivate var characteristicRemoteTxInstance: CBCharacteristic?
    fileprivate var characteristicRemoteRxInstance: CBCharacteristic?
    fileprivate var alertController: UIAlertController?
    fileprivate var localTimer: Foundation.Timer = Foundation.Timer()
    fileprivate var rssiTime: Date = Date()
    fileprivate var cbCentralManager: CBCentralManager!
    fileprivate var peripheralInstance: CBPeripheral?
    fileprivate var peripheralDict = [String: PeripheralsStructure]()
    fileprivate var previousPeripheralRSSIValue: Int = 0
    fileprivate var indexPathForSelectedRow: IndexPath?
    fileprivate var remoteCommandEnabled: Bool = false
    fileprivate var upgradeEnabled: Bool = false
    fileprivate var incomingText: String = ""
    
    override init() {
    }
    
    func initBluetooth() {
        cbCentralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // *************************************
    // Local notifications
    // *************************************
    
    func bluetoothNotificationReceived(_ value:Int) {

        let settings = UIApplication.shared.currentUserNotificationSettings
        
        if settings!.types == UIUserNotificationType() {
            return
        }

        var msg = ""
        
        if (value == 100) {
            msg = remotePHWarning
        }
        
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 10)
        notification.alertBody = msg
        notification.alertAction = "Dismiss"
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.shared.scheduleLocalNotification(notification)
        
        
    }

    // *************************************
    // Bluetooth Public methods
    // *************************************

    func sendData(_ data:String) {
        if ((peripheralInstance) != nil) {
            var bytesData = [UInt8] (data.utf8)
            let writeData = Data(buffer: UnsafeBufferPointer(start: &bytesData, count: bytesData.count))
            print("sending: " + data)
            peripheralInstance!.writeValue(writeData, for: characteristicTxInstance! as CBCharacteristic, type:CBCharacteristicWriteType.withResponse)
        }
    }
    
    func connectToDefaultPeripheral() {
        cbCentralManager.connect(currentPeripheralDevice.instance!, options: nil)
    }

    func disconnectFromDefaultPeripheral() {
        cbCentralManager.cancelPeripheralConnection(currentPeripheralDevice.instance!)
    }
    
    // *************************************
    // Bluetooth Data Transfer
    // *************************************
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var bytesData = [UInt8] (repeating: 0, count: characteristic.value!.count)
        (characteristic.value! as NSData).getBytes(&bytesData, length: characteristic.value!.count)
        let receivedString = String(bytes: bytesData, encoding: String.Encoding.ascii)
        parseIncomingString(receivedString!);
    }
    
    func parseIncomingString(_ string: String) {
        
        print("Incoming string from Bluetooth: " + string)
        
        let needle: Character = "}"
        if let idx = string.index(of: needle) {
            let pos = string.distance(from: string.startIndex, to: idx) + 1
            incomingText += string[string.startIndex..<string.index(string.startIndex, offsetBy: pos)]
            let data = incomingText.data(using: String.Encoding.utf8, allowLossyConversion: false)!
            do {
                let json = try JSON(data:data)
                let type:Int = json["type"].intValue
            
                // Data
                if (type == 1) {
                    let poolData = PoolData()
                    poolData.temperature = json["temp"].stringValue
                    poolData.ph = json["ph"].stringValue
                    poolData.totalAlkalinity = json["ta"].stringValue
                    poolData.calciumHardness = json["calc"].stringValue
                    poolData.chlorine = json["ch"].stringValue
                    poolData.pumpOn = json["pumpOn"].intValue
            
                    // Going here for easier view controller access to latest info
                    self.currentPoolData = poolData;
            
                    NotificationCenter.default.post(name: Notification.Name(rawValue: notifyBluetoothDataReceived), object:self)
                }
                // Notifications
                else if (type == 2) {
                    let notify:Int = json["notify"].intValue
                    bluetoothNotificationReceived(notify)
                }
            
                incomingText = ""
                
            }
            catch {
            print(error)
            }
            
        }
        else {
            incomingText += string
        }
        
        
        
    }
    
    // *************************************
    // Bluetooth Connection Delegates
    // *************************************
    
    @objc func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
            
        case CBCentralManagerState.poweredOn:
            cbCentralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            break
            
        default:
            break
        }
    }
    
    @objc func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if (currentPeripheralDevice.instance?.state == CBPeripheralState.connected) {
            return
        }
        
        
        self.peripheralInstance = peripheral
        let peripheralConnectable: AnyObject = advertisementData["kCBAdvDataIsConnectable"]! as AnyObject
        
        if ((self.peripheralInstance == nil || self.peripheralInstance?.state == CBPeripheralState.disconnected) && (peripheralConnectable as! NSNumber == 1)) {
            var peripheralName: String = String()
            if (advertisementData.index(forKey: "kCBAdvDataLocalName") != nil) {
                peripheralName = advertisementData["kCBAdvDataLocalName"] as! String
            }
            if (peripheralName == "" || peripheralName.isEmpty) {
                
                if (peripheral.name == nil || peripheral.name!.isEmpty) {
                    peripheralName = "Unknown"
                } else {
                    peripheralName = peripheral.name!
                }
            }
            
            print(peripheralName)
            
            // Hardcode peripheral name - should add UI selector
            if (peripheralName == "RN4020_BA2E") {
                peripheralDict.updateValue(PeripheralsStructure(peripheralInstance: peripheral, peripheralRSSI: RSSI, timeStamp: Date()), forKey: peripheralName)
                currentPeripheralDevice.name = peripheralName
                currentPeripheralDevice.rssi = RSSI
                currentPeripheralDevice.instance = peripheral
                NotificationCenter.default.post(name: Notification.Name(rawValue: peripheralDiscovered), object:self)
                connectToDefaultPeripheral()
            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([mchpServiceUUID, isscServiceUUID, customServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: peripheralConnectFailed), object:self)
    }
    
    func centralManager(_ central: CBCentralManager!, didRetrievePeripherals peripherals: [AnyObject]!) {
        
    }
    
    @objc func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (peripheral.services!.isEmpty) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: notifyPeripheralNoMicrochipBLEServicesFound), object:self)
            //cbCentralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        for service in peripheral.services! {
            NSLog("Service discovered: \(service.uuid)")
            if (service.uuid == mchpServiceUUID) {
                peripheral.discoverCharacteristics([mchpTxUUID, mchpRxUUID, mchpRemoteTxUUID, mchpRemoteRxUUID], for: service )
            }
            else if (service.uuid == isscServiceUUID) {
                peripheral.discoverCharacteristics([isscTxUUID, isscRxUUID], for: service )
            }
            else if (service.uuid == customServiceUUID) {
                peripheral.discoverCharacteristics([customTxUUID, customRxUUID], for: service )
            }
        }
    }
    
    @objc func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    @objc func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if (service.characteristics!.isEmpty) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: notifyPeripheralNoMicrochipBLECharacteristicsFound), object:self)
            //cbCentralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        self.peripheralInstance = peripheral
        for characteristic in service.characteristics! {
            NSLog("Characteristics discovered: \(characteristic.uuid)")
            if (service.uuid == mchpServiceUUID) {
                
                if (characteristic.uuid == mchpTxUUID) {
                    characteristicTxInstance = characteristic
                }
                
                if (characteristic.uuid == mchpRxUUID) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    characteristicRxInstance = characteristic
                }
                
                if (characteristic.uuid == mchpRemoteTxUUID) {
                    remoteCommandEnabled = true
                    upgradeEnabled = true
                    characteristicRemoteTxInstance = characteristic
                }
                
                if (characteristic.uuid == mchpRemoteRxUUID) {
                    remoteCommandEnabled = true
                    upgradeEnabled = true
                    characteristicRemoteRxInstance = characteristic
                }
            }
            else if (service.uuid == isscServiceUUID) {
                if (characteristic.uuid == isscTxUUID) {
                    characteristicTxInstance = characteristic
                }
                
                if (characteristic.uuid == isscRxUUID) {
                    peripheral.setNotifyValue(true, for: characteristic )
                    characteristicRxInstance = characteristic
                }
            }
            else if (service.uuid == customServiceUUID) {
                if (characteristic.uuid == customTxUUID) {
                    characteristicTxInstance = characteristic
                }
                
                if (characteristic.uuid == customRxUUID) {
                    peripheral.setNotifyValue(true, for: characteristic )
                    characteristicRxInstance = characteristic
                }
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: peripheralConnectSuccess), object:self)
        
    }
        

    
}
