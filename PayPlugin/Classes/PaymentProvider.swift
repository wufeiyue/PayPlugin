//
//  PaymentProvider.swift
//  PayPlugin
//
//  Created by 武飞跃 on 2019/2/20.
//

import Foundation

open class PaymentProvider {
    
    public enum PaymentBusiness {
        /// 支付宝客户端
        case alipayClient(orderInfo: String, scheme: String)
        /// 微信客户端
        case wechat(openId: String, partnerId: String, prepayId: String, nonceStr: String, timeStamp: UInt32, package: String, sign: String)
        /// 建行
        case ccbpay(orderInfo: String)
        /// 网页支付
        case web(profile: PostFormProfile)
        /// 银联充值 目前仅支持微信/支付宝
        case unionRecharge(orderInfo: String, payChannel: PayPlugin.SupportedPlatform)
    }
    
    //签名回调
    public typealias SignCompletionHandler = (PaymentResult<PaymentBusiness>) -> Void
    //验签回调
    public typealias VerifyCompletionHandler = (VerifyResult) -> Void
    //查询回调
    public typealias QueryCompletionHandler = (PaymentStatus) -> Void
    
    public init() { }
    
    /// 签名
    open func sign(result: @escaping SignCompletionHandler) {
        fatalError("需由子类实现")
    }
    
    /// 验签
    open func verify(dict: Dictionary<AnyHashable, Any?>, result: @escaping VerifyCompletionHandler) {
        result(.pass)
    }
    
    /// 查询
    open func query(result: @escaping QueryCompletionHandler) {
        result(.success)
    }
    
    deinit {
        print("PaymentProvider被释放")
    }
}
