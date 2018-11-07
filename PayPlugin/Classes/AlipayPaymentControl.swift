//
//  AlipayPaymentControl.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
import AlipaySDK

public class AlipayPaymentControl: MultipartPayControl {
    
    override func payOrder(profile: OrderInfoProfile, result: @escaping ResponseCompletion) {
        
        //调起支付宝支付SDK进行支付
        
        guard case .alipay(let scheme)? = payType else {
            return
        }
        
        AlipaySDK.defaultService().payOrder(profile.orderInfo, fromScheme: scheme) { dict in
            //支付结果回调Block，用于wap支付结果回调（非跳转钱包支付）
            
            //FIXME: 具体错误
            let response = PayResponse()
            result(response)
        }
    }
    
    override func processOrder(with url: URL, result: @escaping ResponseCompletion) {
        // 支付宝客户端进行支付,处理支付结果
        AlipaySDK.defaultService().processOrder(withPaymentResult: url) { dict in
            
            guard let payStatus = dict?["resultStatus"] as? String else {
                //处理失败结果
                result(.payFailure)
                return
            }
            
            let response = PayResponse(code: .alipay(payStatus), payResult: .alipay(payStatus), descriptor: dict)
            result(response)
        }
    }
    
}

public class AlipayFeePaymentControl: MultipartPayControl {
    
}

public class WeixinFeePaymentControl: MultipartPayControl {
    
}

extension PayError {
    
    fileprivate static func alipay(_ status: String) -> PayError? {
        
        switch status {
        case "6002":
            return .sentFailure
        case "6001":
            return .userCancel
        case "8000":
            return .accepting
        default:
            return nil
        }
        
    }
    
    
}

extension PaymentStatus {
    
    fileprivate static func alipay(_ status: String) -> PaymentStatus {
        switch status {
        case "9000":
            return .paySuccess
        case "8000":
            return .willPay
        default:
            return .payFailure
        }
    }
    
}


