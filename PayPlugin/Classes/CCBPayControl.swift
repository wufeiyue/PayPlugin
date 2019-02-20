//
//  Ywtpay.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
import CCBNetPaySDK

final class CCBPayControl: PaymentPlatformStrategy {
    
    let orderInfo: String
    private var isFlag = true
    
    init(orderInfo: String) {
        self.orderInfo = orderInfo
    }
    
    override func payOrder() {
        
        CCBNetPay.defaultService().payOrder(orderInfo) {  [weak self] dict in
            //支付完成回调方法，该方法回调结果需要在processOrderWithPaymentResult方法实现的前提下才能在completionBlock拿到支付结果。将在支付结果获取与处理中详细说明
            guard let this = self else { return }
            if this.isFlag {
                this.singleProcessCompletionHandler(dict: dict)
                this.isFlag = false
            }
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
    
    override func processOrder(with url: URL) {
        
        CCBNetPay.defaultService().processOrder(withPaymentResult: url) { dict in
            if self.isFlag {
                self.singleProcessCompletionHandler(dict: dict)
                self.isFlag = false
            }
        }
        
    }
    
    private func singleProcessCompletionHandler(dict: [AnyHashable: Any]?) {
        
        /*
         返回状态，以dic为：
         1.code = -1。H5支付（龙支付H5、支付宝支付、银联支付） 取消支付。
         2.epayStatus = ”” 为手机银行APP支付取消
         3.epayStatus = Y 为手机银行APP支付成功，未开商户通知
         4.有返回。以字段SUCCESS为“Y”支付成功，“N”支付失败，ERRORMSG字段为错误信息。
         nil。手机银行无返回信息 订单状态请商户以异步服务器通知为准
         */
        
        guard let unwrappedDict = dict else {
            self.processCompletionHandler?(.failure(.lossData), dict)
            return
        }
        
        if let status = unwrappedDict["SUCCESS"] as? String, status.isEmpty == false {
            switch status {
            case "Y":
                //支付成功
                self.processCompletionHandler?(.success, dict)
                return
            case "N":
                //支付失败, 返回错误
                var error: PayPluginError {
                    //是否存在错误码
                    if let message = unwrappedDict["ERRORMSG"] as? String {
                        return .custom(message)
                    }
                    return .unknown
                }
                self.processCompletionHandler?(.failure(error), dict)
                return
            default:
                break
            }
        }
        
        if let epayStatus = unwrappedDict["epayStatus"] as? String {
            switch epayStatus {
            case "Y":
                //支付成功
                self.processCompletionHandler?(.success, dict)
                return
            case "":
                //手机银行取消支付
                self.processCompletionHandler?(.failure(.userDidCancel), dict)
                return
            default:
                break
            }
        }
        
        if let status = unwrappedDict["code"] as? String, status == "-1" {
            //h5取消支付
            self.processCompletionHandler?(.failure(.userDidCancel), dict)
            return
        }
        
        self.processCompletionHandler?(.failure(.unknown), dict)
        
    }
    
}

