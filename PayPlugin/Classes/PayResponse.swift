//
//  PayResponse.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
/*
public struct PayResponse {
    
    var code: PayError?
    
    var payResult: PaymentStatus?
    
    /// SDK调用验签接口返回的出参, 包含支付正确或错误信息
    var descriptor: [AnyHashable: Any]?
    
    static func needVerify(_ dict: [AnyHashable: Any]?) -> PayResponse {
        var p = PayResponse()
        p.descriptor = dict
        return p
    }
    
    static var payFailure: PayResponse {
        return PayResponse(code: .lossData, payResult: .payFailure, descriptor: nil)
    }
}

extension PayResponse {
    //本地同步通知支付成功
    var isPaySuccessed: Bool {
        return payResult == .paySuccess
    }
}

public struct PayPrepare {
    
    /// SDK调用签名接口返回的出参
    var descriptor: [AnyHashable: Any]?
    
    static func justDict(_ dict: [AnyHashable: Any]?) -> PayPrepare {
        var p = PayPrepare()
        p.descriptor = dict
        return p
    }
    
}
*/
