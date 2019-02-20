//
//  Ywtpay.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
import SYWechatOpenSDK

final class WeChatControl: PaymentPlatformStrategy {
    
    let payRequest: PayReq
    
    init(package: String, partnerid: String, noncestr: String, prepayid: String, openId: String, timestamp: UInt32, sign: String) {
        
        let req = PayReq()
        req.openID = openId
        req.partnerId = partnerid
        req.prepayId = prepayid
        req.nonceStr = noncestr
        req.timeStamp = timestamp
        req.package = package
        req.sign = sign
        
        self.payRequest = req
    }
    
    override func register(_ account: PayPlugin.Account) {
        if case .weChat(let id) = account {
            WXApi.registerApp(id)
        }
    }
    
    override func payOrder() {
        WXApi.send(payRequest)
    }
    
    override func processOrder(with url: URL) {
        
        let queryDictionary = url.queryDictionary
        guard let ret = queryDictionary["ret"] as? String else {
            //TODO: 处理失败结果
            processCompletionHandler?(.failure(.lossData), queryDictionary)
            return
        }
        
        switch ret {
        case "0":
            //支付成功
            processCompletionHandler?(.success, queryDictionary)
        case "-2":
            //用户取消支付
            processCompletionHandler?(.failure(.userDidCancel), queryDictionary)
        default:
            //支付失败
            processCompletionHandler?(.failure(.unknown), queryDictionary)
        }
    }
    
}
