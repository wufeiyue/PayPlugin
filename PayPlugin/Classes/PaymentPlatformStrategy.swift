//
//  PaymentPlatformStrategy.swift
//  PayPlugin
//
//  Created by 武飞跃 on 2019/2/20.
//

import Foundation

class PaymentPlatformStrategy {
    
    typealias ProcessCompletionHandler = (_ result: PaymentStatus, _ jsonDict: Dictionary<AnyHashable, Any?>?) -> Void
    
    /// 支付结果
    var processCompletionHandler: ProcessCompletionHandler?
    
    //注册
    func register(_ account: PayPlugin.Account) { }
    
    /// 传入签名,调起客户端
    func payOrder() {
        fatalError("由子类实现")
    }
    
    /// 从客户端回调App
    func processOrder(with url: URL) {
        fatalError("由子类实现")
    }
    
    deinit {
        print("PaymentPlatformStrategy被释放")
    }
}
