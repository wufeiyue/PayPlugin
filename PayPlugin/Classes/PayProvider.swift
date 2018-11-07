//
//  PayProvider.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/8/9.
//

import Foundation

/*
 
 支付流程:
 
 1.参数配置
 2.签名接口
 3.SDK调起支付
 4.SDK获取回调(可选)
 5.效验支付通知
 6.返回结果
 
 */

public typealias ResponseCompletion = (PayResponse) -> Void
public typealias PaymentStatusCompletion = (PayResult<PaymentStatus>) -> Void

//MARK: - 支付状态
public enum PaymentStatus: Int {
    /// 支付成功
    case paySuccess = 1
    /// 支付中
    case willPay = 0
    /// 未支付
    case payFailure = 2
}


/// 支付终端类型
///
/// - client: 第三方客户端
/// - web: 网页H5
public enum PayTerminal {
    case client
    case web
}

public struct PostFormProfile {
    
    public var loadHTMLString: String = ""
    public var baseURL: URL?
    
    public var returnURLString: String = ""
    
    public var javeScript: String?
    
    public var title: String = ""
    
    public var openURLRole: (URL) -> Bool = { url in
        return url.scheme != "https" && url.scheme != "http" && url.absoluteString != "about:blank"
    }
    
    public init() {
        
    }
    
}

public struct OrderInfoProfile {
    public var orderInfo: String = ""
    public var params: Dictionary<String, Any>!
    
    public init(orderInfo: String) {
        self.orderInfo = orderInfo
    }
    
    public init(params: Dictionary<String, Any>) {
        self.params = params
    }
}

public struct PayParamsType {
    
    public var clientProfile: OrderInfoProfile!
    public var webProfile: PostFormProfile!
    
    let type: PayTerminal
    
    init(type: PayTerminal) {
        self.type = type
    }
    
    public static func client(orderInfo: String) -> PayParamsType {
        var paramsType = PayParamsType(type: .client)
        paramsType.clientProfile = OrderInfoProfile(orderInfo: orderInfo)
        return paramsType
    }
    
    public static func client(params: Dictionary<String, Any>) -> PayParamsType {
        var paramsType = PayParamsType(type: .client)
        paramsType.clientProfile = OrderInfoProfile(params: params)
        return paramsType
    }
    
    public static func web(_ profile: PostFormProfile) -> PayParamsType {
        var paramsType = PayParamsType(type: .web)
        paramsType.webProfile = profile
        return paramsType
    }
    
}

//MARK: - 支付环境
public enum PayMode {
    case dev    //开发环境
    case pro    //生产环境
}

/// 客户端支付进度
///
/// - prepare: 准备阶段
/// - didSign: 已签名
/// - willVerify: 已验签
public enum PaymentProgress {
    case prepare
    case completed
}

extension Notification.Name {
    //不给外部暴露
    internal static let payManagerHandleOpenURL = Notification.Name("payManagerHandleOpenURL")
}
