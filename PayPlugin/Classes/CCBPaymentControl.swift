//
//  CCBPaymentControl.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
import CCBNetPaySDK

class CCBPaymentControl: MultipartPayControl {
    
    override func payOrder(profile: OrderInfoProfile, result: @escaping ResponseCompletion) {
        //调起建行支付SDK进行支付
        CCBNetPay.defaultService().payOrder(profile.orderInfo) { dict in
            //支付完成回调方法，该方法回调结果需要在processOrderWithPaymentResult方法实现的前提下才能在completionBlock拿到支付结果。将在支付结果获取与处理中详细说明
            
            let response = PayResponse(code: .ccbpay(dict: dict),
                                       payResult: .ccbpay(dict: dict),
                                       descriptor: dict)
            
            result(response)
        }
        
        //去掉建行加载loading
        let windows = UIApplication.shared.windows
        for window in windows {
            for j in window.subviews {
                if j.classForCoder == NSClassFromString("CCBProgressHUD") {
                    j.isHidden = true
                }
            }
        }
    }
    
    override func processOrder(with url: URL, result: @escaping ResponseCompletion) {
        
        CCBNetPay.defaultService().processOrder(withPaymentResult: url) { dict in
            
            let response = PayResponse(code: .ccbpay(dict: dict),
                                       payResult: .ccbpay(dict: dict),
                                       descriptor: dict)
            
            result(response)
        }
        
    }
    
}

extension PayError {
    
    fileprivate static func ccbpay(dict: [AnyHashable: Any?]?) -> PayError? {
        
        if let code = dict?["code"] as? String, code == "-1" {
            //H5支付（龙支付H5、支付宝支付、银联支付） 取消支付
            return .userCancel
        }
        
        if let epayStatus = dict?["epayStatus"] as? String, epayStatus.isEmpty {
            return .platformCancel
        }
        
        if let epayStatus = dict?["ERRORMSG"] as? String {
            return .custom(epayStatus)
        }
        
        return nil
    }
}

extension PaymentStatus {
    
    fileprivate static func ccbpay(dict: [AnyHashable: Any?]?) -> PaymentStatus {
        
        guard let unwrappedDict = dict else {
            return .payFailure
        }
        
        if let status = unwrappedDict["SUCCESS"] as? String, status.isEmpty == false {
            switch status {
            case "Y":
                return .paySuccess
            case "N":
                return .payFailure
            default:
                return .willPay
            }
        }
        
        if let epayStatus = unwrappedDict["epayStatus"] as? String, epayStatus == "Y" {
            return .paySuccess
        }
        
        return .payFailure
        
    }
    
}
