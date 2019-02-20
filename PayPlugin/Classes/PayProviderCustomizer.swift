//
//  PayType.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
/*
public protocol PayProviderCustomizer: class {
    
    //查询或验签的数据模型, 遵守协议的类具体实现后, 在Paymanger.default.pay()成功回调结果中, 会传递出去
    associatedtype Model
    
    /// 支付类型配置
    var payType: PayType { get }
    
    /// 支付环境配置 包括: 开发/生产, 默认为开发环境, 仅作用于支持配置支付环境的第三方SDK, 因为很多支付SDK并不区分支付环境
//    var payMode: PayMode { get }
    
    /// 支付终端配置, 有默认实现, (目前仅用于银联充值调起支付宝或微信客户端时使用)
    var payClient: PayClient? { get }
    
    /// 没有按照客户端就打开网页, 默认否(最好的方式是: 根据配置wab和client签名自动切换)
    var openWebIfNotFoundClient: Bool { get }
    
    /// 签名
    ///
    /// - Parameter result: 签名结果
    func sign(result: @escaping (ResponseResult<PayParamsType>) -> Void)
    
    /// 查询或验签
    ///
    /// - Parameters:
    ///   - dict: 由支付平台SDK回调的字典, 可用于通知服务器验签功能, 如dict为空, 表示SDK不具有验签功能, 可进行请求接口进行支付结果验证
    ///   - payResult: 支付结果
    func query(dict: [AnyHashable: Any?]?, payResult: @escaping (ResponseResult<Model>) -> Void)
    
}

public extension PayProviderCustomizer {
    
//    var payMode: PayMode {
//        return .dev
//    }
    
    //使用终端
    var payClient: PayClient? {
        switch payType {
        case .alipay:
            return .alipay
        case .weixin:
            return .weixin
        case .unionpay:
            return .unionpay
        case .ccb:
            return .ccb
        default:
            return nil
        }
    }
    
    var openWebIfNotFoundClient: Bool {
        return false
    }
}

*/
