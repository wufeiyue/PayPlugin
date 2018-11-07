//
//  UnionRechargePaymentControl.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/8/8.
//  银联充值

import Foundation
import UMSPPPayUnifyPayPlugin

extension PayClient {
    
    var payChannel: String {
        
        switch self {
        case .alipay:
            return "02" //支付宝支付
        case .weixin:
            return "01" //微信支付
        case .unionpay:
            return "03" //银商钱包
        default:
            fatalError("不支持的类型")
        }
    }
}

public class UnionRechargePaymentControl: MultipartPayControl {
    
    static func register(model: String) {
        UMSPPPayUnifyPayPlugin.registerApp(model)
    }
    
    override func payOrder(profile: OrderInfoProfile, result: @escaping ResponseCompletion) {
        
        UMSPPPayUnifyPayPlugin.pay(withPayChannel: payClient.payChannel, payData: profile.orderInfo) { (code, info) in
            //交易结果回调Block
            print("充值失败: \(String(describing: info))")
        }
    }
    
    override func processOrder(with url: URL, result: @escaping ResponseCompletion) {
        result(PayResponse(code: nil, payResult: nil, descriptor: nil))
    }
}

