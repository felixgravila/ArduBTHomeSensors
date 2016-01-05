//
//  DataViewController.swift
//  BTHomeMonitoring
//
//  Created by Felix Gravila on 14/12/15.
//  Copyright © 2015 Felix Gravila. All rights reserved.
//

import UIKit
import CoreBluetooth

class DataViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var swWhite: UISwitch!
    @IBOutlet weak var swRed: UISwitch!
    @IBOutlet weak var swGreen: UISwitch!
    @IBOutlet weak var swYellow: UISwitch!
    @IBOutlet weak var swBlue: UISwitch!
    @IBOutlet weak var swAll: UISwitch!
    
    
    var BLEManager: CBCentralManager!
    var currentPeripheral: CBPeripheral?
    var currentCharacteristic: CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.setProgress(0, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        temperatureLabel.text = "Temperature loading..."
        humidityLabel.text = "Humidity loading..."
        BLEManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: CB Delegates
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        var consoleMsg = ""
        switch BLEManager.state{
        case .PoweredOn:
            consoleMsg = "BLE is ON"
            BLEManager.scanForPeripheralsWithServices(nil, options: nil)
        case .PoweredOff:
            consoleMsg = "BLE is OFF"
        case .Resetting:
            consoleMsg = "BLE is resetting"
        case .Unauthorized:
            consoleMsg = "BLE is unauthorized"
        case .Unknown:
            consoleMsg = "BLE is unknown"
        case .Unsupported:
            consoleMsg = "BLE is unsupported"
        }
        progressView.setProgress(0.2, animated: true)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        if let name = peripheral.name {
            if name == "CC41-A"{
                central.connectPeripheral(peripheral, options: nil)
                currentPeripheral = peripheral
                progressView.setProgress(0.4, animated: true)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        currentPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        progressView.setProgress(0.6, animated: true)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
        progressView.setProgress(0.8, animated: true)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                peripheral.readValueForCharacteristic(characteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
        progressView.setProgress(0.95, animated: true)
    }
    
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        progressView.setProgress(1, animated: true)
        progressView.alpha = 0
        let data = characteristic.value
        currentCharacteristic = characteristic
        let myString = String(data: data!, encoding: NSUTF8StringEncoding)
        
        if myString != nil {
            
            let theStrings = myString?.componentsSeparatedByString(" ")

            if(theStrings?.count == 7){
                do {
                    print(theStrings!)
                    let humidity = Int.init((theStrings?[0])!)
                    let temperature = Int.init((theStrings?[1])!)
                    
                    let lw = Int.init((theStrings?[2])!)
                    let lr = Int.init((theStrings?[3])!)
                    let lg = Int.init((theStrings?[4])!)
                    let ly = Int.init((theStrings?[5])!)
                    let lb = Int.init((theStrings?[6])!)
                    
                    applyToSwitch(swWhite, i: lw!)
                    applyToSwitch(swRed, i: lr!)
                    applyToSwitch(swGreen, i: lg!)
                    applyToSwitch(swYellow, i: ly!)
                    applyToSwitch(swBlue, i: lb!)
                    
                    if lb == 1 && lr == 1 && lg == 1 && ly == 1 && lb == 1 {
                        applyToSwitch(swAll, i: 1)
                    } else {
                        applyToSwitch(swAll, i: 0)
                    }
                    
                    
                    if humidity != nil && temperature != nil {
                        temperatureLabel.text = "Temperature: \(temperature!)°C"
                        humidityLabel.text = "Humidity: \(humidity!)%"
                    }
                }
            }
        }
    }
    
    
    func applyToSwitch(sw: UISwitch, i:Int){
        if i == 1 {
            sw.on = true
        } else {
            sw.on = false
        }
    }
    
    func sendData(s: String){
        let data = s.dataUsingEncoding(NSUTF8StringEncoding)
        currentPeripheral!.writeValue(data!, forCharacteristic: currentCharacteristic!, type: .WithoutResponse)
    }
    
    @IBAction func switchLed(sender: UISwitch) {
        switch sender {
        case swWhite:
            swWhite.on = !swWhite.on
            sendData("w")
        case swRed:
            swRed.on = !swRed.on
            sendData("r")
        case swGreen:
            swGreen.on = !swGreen.on
            sendData("g")
        case swYellow:
            swYellow.on = !swYellow.on
            sendData("y")
        case swBlue:
            swBlue.on = !swBlue.on
            sendData("b")
        case swAll:
            swAll.on = !swAll.on
            sendData("a")
        default:
            let _ = 0
        }
    }
}
