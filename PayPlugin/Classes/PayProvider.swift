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
/*

public typealias PaymentStatusCompletion = (PayResult<PaymentStatus>) -> Void
*/



public enum PayPluginError: Error {
    //网络请求失败结果的输出
    case custom(String)
    case verifyReject
    case userDidCancel
    case lossData
    case unknown
}

extension PayPluginError: Equatable {
    static public func ==(lhs: PayPluginError, rhs: PayPluginError) -> Bool {
        switch (lhs, rhs) {
        case (.custom, .custom):
            return true
        case (.verifyReject, .verifyReject):
            return true
        default:
            return false
        }
    }
}

extension PayPluginError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .custom(let value):
            return value
        case .verifyReject:
            return "验证签名失败!"
        case .userDidCancel:
            return "用户取消支付"
        case .lossData:
            return "JSON解析失败"
        case .unknown:
            return "未知错误"
        }
    }
}

//MARK: - 支付状态
public enum PaymentStatus {
    /// 支付成功
    case success
    /// 支付中
    case willPay
    /// 支付失败
    case failure(PayPluginError)
}

public struct PostFormProfile {
    
    /// 发起网页请求
    public var loadHTMLString: String = ""
    public var baseURL: URL?
    
    /// 在网页中,点击回退按钮可关闭网页,回到我们的App中,这里就需要和服务器约定好需要返回的urlString
    public var returnURLString: String = ""
    
    /// 需要执行的js
    public var javeScript: String?
    
    /// 网页的标题
    public var title: String = ""
    
    /// 处理需要跳转打开App的url规则
    public var openURLRole: (URL) -> Bool = { url in
        return url.scheme != "https" && url.scheme != "http" && url.absoluteString != "about:blank"
    }
    
    public init() { }
    
}


/*


/// 支付终端类型
///
/// - client: 第三方客户端
/// - web: 网页H5
public enum PayTerminal {
    case client
    case web
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
*/
