//
//  ViewController.swift
//  CoreBluetoothDemo
//
//  Created by user on 17/2/25.
//  Copyright © 2017年 陈泽槟. All rights reserved.
//


/*
 
 1.外设：就是你手机要连接的蓝牙设备
 2.回调：当一个方法执行完后就会回调到指定的回调方法执行
 
 */

import UIKit
import CoreBluetooth
class ViewController: UIViewController,CBCentralManagerDelegate,CBPeripheralDelegate{
    @IBOutlet weak var textView: UITextView!

    /// 中心者对象
    var central: CBCentralManager!
    
    /// 外设数组
    var peripheralArray = NSMutableArray.init()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = nil
        initBluetooth()
    }
    
    
    /// 初始化中心设备
    func initBluetooth() {
        //MARK: -1.初始化本地中心设备对象
        central = CBCentralManager.init(delegate: self, queue: nil) // 初始化后会回调centralManagerDidUpdateState方法
        self.writeToTextView(string: "1.初始化本地中心设备对象")
        
        
        
    }
    
    //MARK: -2.检查设备自身（中心设备）支持的蓝牙状态
    // CBCentralManagerDelegate的代理方法
    
    /// 本地设备状态
    ///
    /// - Parameter central: 中心者对象
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.writeToTextView(string: "初始化对象后，来到centralManagerDidUpdateState")
        switch central.state {
        case .unknown:
            print("CBCentralManager state:", "unknown")
            break
        case .resetting:
            print("CBCentralManager state:", "resetting")
            break
        case .unsupported:
            print("CBCentralManager state:", "unsupported")
            break
        case .unauthorized:
            print("CBCentralManager state:", "unauthorized")
            break
        case .poweredOff:
            print("CBCentralManager state:", "poweredOff")
            break
        case .poweredOn:
            print("CBCentralManager state:", "poweredOn")
            
            // 第一个参数那里表示扫描带有相关服务的外部设备，例如填写@[[CBUUIDUUIDWithString:@"需要连接的外部设备的服务的UUID"]]，即表示带有需要连接的外部设备的服务的UUID的外部设备，nil表示扫描全部设备；
            //MARK: -3.扫描周围外设（支持蓝牙）
            central.scanForPeripherals(withServices: nil, options: nil) // 每次搜索到一个外设都会回调起代理方法centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
            
            
            self.writeToTextView(string: "2.扫描周围外设")
            break
        }

    }
    
    //MARK: -4.发现外设
    /// 搜索到外设会的回调方法
    ///
    /// - Parameters:
    ///   - central: 中心设备实例对象
    ///   - peripheral: 外设实例对象
    ///   - advertisementData: 一个包含任何广播和扫描响应数据的字典
    ///   - RSSI: 外设的蓝牙信息强度
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.writeToTextView(string: "扫描外设后回调发现外设方法")
        
        // 停止扫描外设
        central.stopScan()
        
        // 添加外设到外设数组（如果不保存这个外设或者说没有对这个外设对象有个强引用的话，就没有办法到达连接成功的方法，因此没有强引用的话，这个方法过后，就销毁外设对象了）
        // 连接外设成功或者失败分别会进入回调方法
        // MAKE: -连接外设
        peripheralArray.add(peripheral)
        
        // 或者，你可以建立一个全局的外设对象。例如
//        self.peripheral = peripheral  这就是强引用这个局部的外设对象，这样就不会导致出了这个方法这个外设对象就被销毁了
        
        //MARK: -5.连接外设
        // 添加完后，就开始连接外设
        central.connect(peripheral, options: nil) // 会根据条件触发，连接成功，失败，断开连接的代理方法
        
        
        // 如果你扫描到多个外设，要连接特定的外设，可以用以下方法
//        if peripheral.name == "A" {
//            // 连接设备
//             central.connect(peripheral, options: nil)
//        }
        
        
        self.writeToTextView(string: "外设信息")
        self.writeToTextView(string: "名字：\(peripheral.name)")
        
        
        
    }
    
    //MARK: -6.连接成功，扫描外设服务
    // 连接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.writeToTextView(string: "连接成功")
        
        // 连接成绩后，接下来就要开始对外设进行寻找服务 特征 读写，所以要开始用到外设的代理方法，所以这里要设置外设的代理为当前控制器
        peripheral.delegate = self
        
        // 设置完后，就开始扫描外设的服务
        // 参数设了nil，是扫描所有服务，如果你知道你想要的服务的UUID，那么也可以填写指定的UUID
        peripheral.discoverServices(nil) //这里会回调代理peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)  这里方法里有这个外设的服务信息
    }
    
    // 连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.writeToTextView(string: "连接失败")
    }
    
    // 断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.writeToTextView(string: "断开连接")
    }
    
    //MARK: -7.发现服务，遍历服务，扫描服务下的特征
    // 外设的服务信息
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)// 发现特征，第二个参数填哪个服务的特征，这个方法会回调特征信息的方法
            print("服务UUID：\(service.uuid.uuidString)")
        }
    }
    
    //MARK: -8.发现特征
    //  特征信息的方法
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("\(service.uuid.uuidString)服务下的特性:\(characteristic)")
            if characteristic.uuid == CBUUID (string: "FFF0")  {
                //MARK: -9.读取指定特征的信息
                //读取特征数据
                peripheral.readValue(for: characteristic)//读取都就会进入didUpdate的代理方法
            }
            
            if  characteristic.uuid == CBUUID (string: "FFF0") {
                //订阅通知
                /**
                 -- 通知一般在蓝牙设备状态变化时会发出，比如蓝牙音箱按了上一首或者调整了音量，如果这时候对应的特征被订阅，那么app就可能收到通知
                 -- 阅读文档查看需要对该特征的操作
                 -- 订阅成功后回调didUpdateNotificationStateForCharacteristic
                 -- 订阅后characteristic的值发生变化会发送通知到didUpdateValueForCharacteristic
                 -- 取消订阅：设置setNotifyValue为NO
                 */
                //这里我们可以使用readValueForCharacteristic:来读取数据。如果数据是不断更新的，则可以使用setNotifyValue:forCharacteristic:来实现只要有新数据，就获取。
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            //扫描描述
            /**
             -- 进一步提供characteristic的值的相关信息。（因为我项目里没有的特征没有进一步描述，所以我也不怎么理解）
             -- 当发现characteristic有descriptor,回调didDiscoverDescriptorsForCharacteristic
             */
            peripheral.discoverDescriptors(for: characteristic)
            
            
        }
        
    
    }
    
    //MARK: -9.拿到需要的数据，写入外设
    /**
     -- peripheral调用readValueForCharacteristic成功后会回调该方法
     -- peripheral调用setNotifyValue后，特征发出通知也会调用该方法
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // 写数据，第一个参数转data类型的数据，第二个参数传写入数据的特征，第三个参数是枚举类型分别是CBCharacteristicWriteWithResponse和                                                  CBCharacteristicWriteWithoutResponse；
//        peripheral.writeValue(<#T##data: Data##Data#>, for: <#T##CBCharacteristic#>, type: <#T##CBCharacteristicWriteType#>)
    }
    
    // 对于以上的枚举类型的第一个CBCharacteristicWriteWithResponse，每往硬件写入一次数据就会调用一下代理方法
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    
    //订阅通知的回调
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    
    
    func writeToTextView(string:String) {
        textView.text = String (format: "%@\r\n%@", textView.text,string)
    }
    
    

    


}

