//
//  PayManager.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

public final class PayPlugin {
    
    public static var `default` = PayPlugin()
    
    required public init() { }
    
    private let controlManager = PayControlManager()
    
    public func register(id: String) {
        UnionRechargePaymentControl.register(model: id)
    }
    
    /// 发起支付
    ///
    /// - Parameters:
    ///   - target: 用于承载跳转的视图控制器
    ///   - provider: 提供支付签名的配置类
    ///   - result: 支付结果
    public func pay<T: PayProviderCustomizer>(target: UIViewController, provider: T, result: @escaping (PayResult<T.Model>) -> Void) {
        
        let payResult = MultipartPayResult<T>(provider: provider, result: result)
        
        controlManager.queryResult = {
            payResult.verify($0)
        }
        
        controlManager.failureResult {
            result(.failure($0))
        }
        
        controlManager.progressResult {
            result(.progress($0))
        }
        
        prepare(provider: provider, target: target)
    }
    
    private func prepare<T: PayProviderCustomizer>(provider: T, target viewController: UIViewController) {
        
        var payControl: MultipartPayControl?
        
        switch provider.payType {
        case .alipay:
            payControl = AlipayPaymentControl()
        case .weixin:
            payControl = WXPaymentControl()
        case .ccb:
            payControl = CCBPaymentControl()
        case .unionpay:
            payControl = UnionPayPaymentControl()
        case .unionRecharge:
            payControl = UnionRechargePaymentControl()
        case .ywt:
            payControl = YwtPaymentControl()
        case .query:
            break
        }
        
        controlManager.payControl = payControl
        controlManager.config(provider: provider, viewController: viewController)
    }
    
    
    /// 通知支付结果
    ///
    /// - Parameter url: 第三方客户端回传过来的URL地址
    public func sendNotification(_ url: URL) {
        if controlManager.payPrepare.checkURL(fromClient: url) {
            NotificationCenter.default.post(name: .payManagerHandleOpenURL, object: url)
        }
    }
    
    public func removeListener() {
        controlManager.removeListener()
    }
    
}
