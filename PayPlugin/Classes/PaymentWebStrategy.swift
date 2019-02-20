//
//  PaymentWebStrategy.swift
//  PayPlugin
//
//  Created by 武飞跃 on 2019/2/20.
//

import Foundation

class PaymentWebStrategy {
    
    typealias ProcessCompletionHandler = () -> Void
    
    /// 支付结果
    var processCompletionHandler: ProcessCompletionHandler?
    
    // 打开客户端跳转回调
    var openURLCompletion: ((URL) -> Bool)?
    
    func payOrder() {
        fatalError("由子类实现")
    }
}
