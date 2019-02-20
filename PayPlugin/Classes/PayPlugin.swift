//
//  PayManager.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

public enum PaymentResult<T> {
    case success(T)
    case failure(String)
}

public enum VerifyResult {
    //拒绝
    case reject
    //通过
    case pass
}

public class Cancelable {
    
    let action: () -> Void
    
    init(_ action: @escaping () -> Void) {
        self.action = action
    }
    
    public func dispose() {
        action()
    }
}

final public class PayPlugin: NSObject {
    
    //支付结果
    public typealias PaymentCompletionHandler = (PaymentStatus) -> Void
    
    public enum SupportedPlatform {
        //微信
        case weChat
        //支付宝
        case alipay
        //建行
        case ccbpay
        //银联
        case unionpay
        
        public var isAppInstalled: Bool {
            switch self {
            case .weChat:
                return shared.canOpenURL(urlString: "weixin://")
            case .alipay:
                return shared.canOpenURL(urlString: "alipay://")
            case .ccbpay:
                return shared.canOpenURL(urlString: "mbspay://")
            case .unionpay:
                return shared.canOpenURL(urlString: "uppaywallet://")
            }
        }
    }
    
    public enum PayBusiness {
        case alipay // 支付宝
        case weChat // 微信
        case unionpay // 银联
        case ccbpay // 建行支付
        case ywt    //招行一网通
        case unionRechargeByAlipay // 支付宝充值到银联账户
        case unionRechargeByWeChat // 微信充值到银联账户
        
        public var isAppInstalled: Bool {
            switch self {
            case .weChat, .unionRechargeByWeChat:
                return SupportedPlatform.weChat.isAppInstalled
            case .alipay, .unionRechargeByAlipay:
                return SupportedPlatform.alipay.isAppInstalled
            case .ccbpay:
                return SupportedPlatform.ccbpay.isAppInstalled
            case .unionpay:
                return SupportedPlatform.unionpay.isAppInstalled
            case .ywt:
                return false
            }
        }
    }
    
    public enum Account: Hashable {
        
        case weChat(appId: String)
        
        public var hashValue: Int {
            switch self {
            case .weChat(let id):
                return id.hashValue
            }
        }
    }
    
    private var payCompletionHandler: PaymentCompletionHandler?
    private var listenterManager: ListenterManager?
    /// 支付状态
    public private(set) var active: Bool = false
    public private(set) var accountList: Set<Account>?
    
    public static let shared = PayPlugin()
    
    private override init() { }
    
    public class func register(list: Set<Account>) {
        shared.accountList = list
    }
    
    public class func handleOpenURL(_ url: URL) -> Bool {
        //判断是否正在发起支付
        guard shared.active else { return false }
        //将回调传入listenterManager内部处理
        shared.listenterManager?.didReceiveHandleOpenURLCompletion?(url)
        
        //FIXME: - 判断url是否可以激活App
        return true
    }
    
    
    /// 恢复成默认支付状态
    private func reset() {
        payCompletionHandler = nil
        active = false
    }
    
    @discardableResult
    public class func deliver(provider: PaymentProvider, result: @escaping PaymentCompletionHandler) -> Cancelable {
        
        var cancelable: (() -> Void)?
        
        provider.sign { (result) in
            switch result {
            case .success(let business):
                cancelable = shared.configuration(business: business, provider: provider)
            case .failure(let error):
                //网络请求失败,直接抛出异常
                shared.payCompletionHandler?(.failure(.custom(error)))
                shared.reset()
            }
        }
        
        defer {
            shared.payCompletionHandler = result
            shared.active = true
            shared.listenterManager = ListenterManager()
        }
        
        return Cancelable({
            cancelable?()
            shared.listenterManager?.didReceiveHandleOpenURLCompletion = nil
            shared.listenterManager = nil
            shared.payCompletionHandler = nil
            shared.active = false
        })
    }
    
    func configuration(business: PaymentProvider.PaymentBusiness, provider: PaymentProvider) -> (() -> Void)? {
        switch business {
        case .alipayClient(let orderInfo, let scheme):
            //支付宝客户端签名成功
            let control = AlipayControl(orderInfo: orderInfo, scheme: scheme)
            //初始化参数配置
            accountList?.forEach{ control.register($0) }
            //添加同步逻辑回调
            return syncCallback(control: control, provider: provider)
            
        case let .wechat(openId, partnerId, prepayId, nonceStr, timeStamp, package, sign):
            //微信客户端签名成功
            let control = WeChatControl(package: package, partnerid: partnerId, noncestr: nonceStr, prepayid: prepayId, openId: openId, timestamp: timeStamp, sign: sign)
            //初始化参数配置
            accountList?.forEach{ control.register($0) }
            //添加同步逻辑回调
            return asyncCallback(control: control, provider: provider)
            
        case .ccbpay(let orderInfo):
            //建行签名成功
            let control = CCBPayControl(orderInfo: orderInfo)
            //初始化参数配置
            accountList?.forEach{ control.register($0) }
            //添加同步逻辑回调
            return asyncCallback(control: control, provider: provider)
            
        case .unionRecharge(let orderInfo, let channel):
            //银联充值签名成功
            let control = UnionRechargeControl(orderInfo: orderInfo, payChannel: channel.unionRecharge)
            //初始化参数配置
            accountList?.forEach{ control.register($0) }
            //添加异步逻辑回调
            return asyncCallback(control: control, provider: provider)
            
        case .web(let profile):
            let control = WebPayControl(profile: profile)
            //添加异步查询逻辑
            return queryCallback(control: control, provider: provider)
            
        }
    }
    
    // 依靠客户端同步回调拿到支付结果
    private func syncCallback(control: PaymentPlatformStrategy, provider: PaymentProvider) -> (() -> Void) {
        
        //调起SDK并跳转到第三方客户端
        control.payOrder()
        
        //得到支付结果
        control.processCompletionHandler = { (state, dict) in
            switch state {
            case .success, .willPay: //本地SDK同步为支付成功/支付中
                guard let unwrappedDict = dict else {
                    self.query(provider)
                    return
                }
                //开始验签
                provider.verify(dict: unwrappedDict, result: { verifyResult in
                    switch verifyResult {
                    case .pass: //验签通过, 进入查询
                        provider.query(result: {
                            if case let .failure(error) = $0, case .custom = error {
                                //如果本地签名成功,遇到服务器请求失败时,可返回成功状态
                                self.payCompletionHandler?(.success)
                                self.reset()
                            }
                            else {
                                //将查询结果通知到外面, 整个支付过程结束
                                self.payCompletionHandler?($0)
                                self.reset()
                            }
                        })
                    case .reject: //验签未通过
                        self.payCompletionHandler?(.failure(.verifyReject))
                        self.reset()
                    }
                })
            case .failure(let error): //本地sdk状态码显示处理失败
                self.payCompletionHandler?(.failure(error))
                self.reset()
            }
        }
        
        // 增加返回第三方客户端的监听
        listenterManager?.singleHandleOpenURLCompletion { (url) in
            //通过第三方客户端传回,需要传入SDK再做一次校对
            control.processOrder(with: url)
        }
        
        return {
            //TODO:取消回调
            
        }
    }
    
    private func asyncCallback(control: PaymentPlatformStrategy, provider: PaymentProvider) -> (() -> Void)? {
        
        //调起SDK并跳转到第三方客户端
        control.payOrder()
        
        //第三方客户端回调的验签结果
        control.processCompletionHandler = { (state, dict) in
            switch state {
            case .success, .willPay: //本地SDK同步为支付成功/支付中
                guard let unwrappedDict = dict else {
                    self.query(provider)
                    return
                }
                //获取到dict, 准备验签
                provider.verify(dict: unwrappedDict, result: { verifyResult in
                    switch verifyResult {
                    case .pass: //验签通过也可能没有重载方法直接通过的, 进入查询, 已查询结果为准
                        self.query(provider)
                    case .reject: //验签未通过
                        self.payCompletionHandler?(.failure(.verifyReject))
                        self.reset()
                    }
                })
            case .failure(let error): //本地sdk状态码显示处理失败
                self.payCompletionHandler?(.failure(error))
                self.reset()
            }
        }
        
        // 增加监听
        return listenterManager?.withLatestFromOpenURLCompletion({ [weak self] url in
            if let unwrappedURL = url {
                //通过第三方客户端传回,需要传入SDK再做一次校对
                control.processOrder(with: unwrappedURL)
            }
            else {
                provider.query(result: { [weak self] in
                    //将查询结果通知到外面, 整个支付过程结束
                    self?.payCompletionHandler?($0)
                })
            }
        })
        
    }
    
    private func queryCallback(control: PaymentWebStrategy, provider: PaymentProvider) -> (() -> Void) {
        
        //调起SDK打开网页也有可能跳转到第三方
        control.payOrder()
        
        //得到支付结果
        control.processCompletionHandler = {
            self.query(provider)
        }
        
        control.openURLCompletion = { url in
            //跳转到第三方平台
            return self.openURL(url: url, completionHandler: { (finished) in
                
                guard finished else {
                    return
                }
                
                //仅跳转成功后, 才增加返回前台的监听
                self.listenterManager?.singleHandleForegroundNotification { [unowned self] in
                    
                    //判断是否正在发起支付
                    guard self.active else {
                        return
                    }
                    
                    self.query(provider)
                }
            })
        }
        
        return {
            //TODO:取消回调
        }
    }
    
    
    private func query(_ provider: PaymentProvider) {
        provider.query(result: {
            //将查询结果通知到外面, 整个支付过程结束
            self.payCompletionHandler?($0)
            self.reset()
        })
    }
    
}

extension PayPlugin {
    
    func openURL(url: URL, completionHandler completion: ((Bool) -> Swift.Void)? = nil) -> Bool {
        guard UIApplication.shared.canOpenURL(url) else {
            completion?(false)
            return false
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { flag in
                completion?(flag)
            }
        } else {
            completion?(UIApplication.shared.openURL(url))
        }
        return true
    }
    
    class func openURL(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.openURL(url)
    }
    
    func canOpenURL(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
}

//MARK: - Helper

extension URL {
    
    var queryDictionary: [String: Any] {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        guard let items = components?.queryItems else {
            return [:]
        }
        var infos = [String: Any]()
        items.forEach {
            if let value = $0.value {
                infos[$0.name] = value
            }
        }
        return infos
    }
}
