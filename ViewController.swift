//
//  ViewController.swift
//  Poolboy
//
//  FOR USE WITH SWIFT 2.0
//
//  Created by Richard Wagner on 1/12/16.
//  Copyright © 2016 MAARK. All rights reserved.
//

import UIKit
import CircleSlider
import AFDropdownNotification
import SwiftSpinner

class ViewController: UIViewController, AFDropdownNotificationDelegate {
    
    @IBOutlet weak var tempSliderContainer: UIView!
    
    fileprivate var alertController: UIAlertController?
    
    fileprivate var circleSlider: CircleSlider! {
        didSet {
            self.circleSlider.tag = 0
        }
    }
    fileprivate var valueLabel: UILabel!

    fileprivate var notificationPane: AFDropdownNotification!
    
    func delay(seconds: Double, completion:@escaping ()->()) {
        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * seconds )) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            completion()
        }
    }
    
    func initBluetoothNotificationPane() {
        self.notificationPane = AFDropdownNotification();
        self.notificationPane.notificationDelegate = self;
        self.notificationPane.image = UIImage(named: "rssiStrength100");
    }
    
    fileprivate func initConnectSpinner() {
        SwiftSpinner.show("Connecting to \nBluepool™ Station").addTapHandler({
            print("tapped")
            SwiftSpinner.hide()
            }, subtitle: "Please wait while the app connects\nto the paired Bluepool™ Station device")

        let delay = 2.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time) {
            App.sharedInstance.initBluetooth()
        }
    }
    
    func syncUI() {
        let poolData:PoolData = App.sharedInstance.currentPoolData
        self.valueLabel.text = poolData.temperature + "°"
        self.circleSlider!.value = Float(poolData.temperature)!
    }
    
    // *************************************
    // Bluetooth Getters/Setters
    // *************************************
    
    func refreshPoolDataFromDevice() {
        SwiftSpinner.show("Synching pool data")
        
        SwiftSpinner.show("Synching pool data").addTapHandler({
            print("tapped")
            SwiftSpinner.hide()
            }, subtitle: "Please wait while the app connects\nto the paired Bluepool™ Station device")
        
        App.sharedInstance.sendData("refresh_pool_data");
    }
    
    // Handler for Incoming Bluetooth Data
    func poolDataReceived(_ notification: Notification) {
        syncUI()
        SwiftSpinner.hide()
    }

    // Send temp update command to Bluetooth
    func setPoolTemperature(_ temperature: Int) {
        let cmd = "set_temp_to:" + String(temperature);
        App.sharedInstance.sendData(cmd)
    }
    
    // Handler for Bluetooth Notifications
    func poolNotificationReceived(_ notification: Notification) {
        let dict: NSDictionary = notification.userInfo! as NSDictionary;
        let notify:Int = dict.object(forKey: "notify") as! Int;
        print(notify);
    }
    
    // *************************************
    // Bluetooth Connect
    // *************************************
    @IBAction func bluetoothConnectTouchHandler(_ sender: AnyObject) {

        var iconImage: UIImage = UIImage(named: "rssiStrengthNil")!
        
        let peripheralRSSIValue: NSNumber = App.sharedInstance.currentPeripheralDevice.rssi
        
        if (peripheralRSSIValue.intValue < -27 && peripheralRSSIValue.intValue > -110) {
            
            if (peripheralRSSIValue.intValue <= -27 && peripheralRSSIValue.intValue > -60 ) {
                iconImage = UIImage(named: "rssiStrength100")!
            }
            
            if (peripheralRSSIValue.intValue <= -60 && peripheralRSSIValue.intValue > -70 ) {
                iconImage = UIImage(named: "rssiStrength75")!
            }
            
            if (peripheralRSSIValue.intValue <= -70 && peripheralRSSIValue.intValue > -80 ) {
                iconImage = UIImage(named: "rssiStrength50")!
            }
            
            if (peripheralRSSIValue.intValue <= -80 && peripheralRSSIValue.intValue > -90 ) {
                iconImage = UIImage(named: "rssiStrength25")!
            }
            
            if (peripheralRSSIValue.intValue <= -90 && peripheralRSSIValue.intValue > -110 ) {
                iconImage = UIImage(named: "rssiStrength0")!
            }
        }
        
        self.notificationPane.image = iconImage
        self.notificationPane.titleText = "Connected to " + App.sharedInstance.currentPeripheralDevice.name
        self.notificationPane.subtitleText = "RSSI: \(peripheralRSSIValue)dB"
        self.notificationPane.topButtonText = "Disconnect"
        self.notificationPane.bottomButtonText = " "
        self.notificationPane.dismissOnTap = true
        self.notificationPane.present(in: self.view!, withGravityAnimation: true)
    }
    
    
    @objc internal func dropdownNotificationTopButtonTapped() {
        self.notificationPane.dismiss(withGravityAnimation: true);
    }
    
    @objc internal func dropdownNotificationBottomButtonTapped() {
        self.notificationPane.dismiss(withGravityAnimation: true);
        App.sharedInstance.disconnectFromDefaultPeripheral()
    }
    
    // *************************************
    // Temperature View
    // *************************************
    
    fileprivate func buildTemperatureSlider() {
        
        let curTemp = Float(50.0);
        
        self.circleSlider = CircleSlider(frame: self.tempSliderContainer.bounds, options: self.sliderOptions)
        self.circleSlider?.addTarget(self, action: Selector("valueChange:"), for: .valueChanged)
        self.circleSlider?.addTarget(self, action: Selector("circleSliderTouchUpHandler:"), for: .touchUpInside)
        
        self.tempSliderContainer.addSubview(self.circleSlider!)
        self.valueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        self.valueLabel.textAlignment = .center
        self.valueLabel.textColor = App.deepOrangeColor
        self.valueLabel.font = UIFont(name: "GillSans-SemiBold", size: 120.0)
        self.valueLabel.center = CGPoint(x: self.circleSlider.bounds.width * 0.5, y: self.circleSlider.bounds.height * 0.5)
        self.circleSlider.addSubview(self.valueLabel)
        self.circleSlider!.value = curTemp
    }
    
    func valueChange(_ sender: CircleSlider) {
        self.valueLabel.text = "\(Int(sender.value))" + "°"
    }
    
    
    @IBAction func circleSliderTouchUpHandler(_ sender: CircleSlider) {
        let temperature = Int(sender.value);
        self.setPoolTemperature(temperature);
    }
    
    
    // *************************************
    // Top View
    // *************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initBluetoothNotificationPane()
        self.initConnectSpinner()
        self.buildTemperatureSlider()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.peripheralDeviceConnected), name: NSNotification.Name(rawValue: peripheralConnectSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.peripheralDeviceFailed), name: NSNotification.Name(rawValue: peripheralConnectFailed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.peripheralNoMicrochipBLEServicesFound), name: NSNotification.Name(rawValue: notifyPeripheralNoMicrochipBLEServicesFound), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.peripheralNoMicrochipBLECharacteristicsFound), name: NSNotification.Name(rawValue: notifyPeripheralNoMicrochipBLECharacteristicsFound), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.poolDataReceived(_:)), name: NSNotification.Name(rawValue: notifyBluetoothDataReceived), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncUI()
    }
    
    // *************************************
    // Notification handlers
    // *************************************
    
    func peripheralDeviceDiscovered(){
        print("Device discovered")
    }
    
    func peripheralDeviceConnected(){
        print("Device connected")
        refreshPoolDataFromDevice()
    }
    
    func peripheralDeviceFailed(){
        print("Failed to connect to the peripheral! Check if the peripheral is functioning properly and try to reconnect.")
    }
    
    func peripheralNoMicrochipBLEServicesFound(){
        print("Microchip BLE data services not found!")
    }
    
    func peripheralNoMicrochipBLECharacteristicsFound(){
        print("Microchip BLE data characteristics not found")
    }
    
}

