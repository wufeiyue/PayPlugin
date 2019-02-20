//
//  Weixin.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import UIKit
import AlipaySDK

final class AlipayControl: PaymentPlatformStrategy {
    
    let orderInfo: String
    let scheme: String
    
    init(orderInfo: String, scheme: String) {
        self.orderInfo = orderInfo
        self.scheme = scheme
    }
    
    override func payOrder() {
        AlipaySDK.defaultService().payOrder(orderInfo, fromScheme: scheme) { _ in
            //用于wab跳转支付成功或失败的回调
        }
    }
    
    override func processOrder(with url: URL) {
        AlipaySDK.defaultService().processOrder(withPaymentResult: url) { dict in
            
            guard let payStatus = dict?["resultStatus"] as? String else {
                self.processCompletionHandler?(.failure(.lossData), dict)
                return
            }
            
            switch payStatus {
            case "9000":
                //支付成功
                self.processCompletionHandler?(.success, dict)
            case "8000":
                //支付中
                self.processCompletionHandler?(.willPay, dict)
            case "6001":
                //用户取消
                self.processCompletionHandler?(.failure(.userDidCancel), dict)
            default:
                //未知状态
                self.processCompletionHandler?(.failure(.unknown), dict)
            }
            
        }
    }
    
}
