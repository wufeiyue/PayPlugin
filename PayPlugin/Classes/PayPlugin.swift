//
//  PayManager.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
import Result
import AlipaySDK
import SYWechatOpenSDK
import CCBNetPaySDK
import UMSPPPayUnifyPayPlugin

/*
public final class oldPayPlugin {
    
    public static var `default` = oldPayPlugin()
    
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
*/
//////////////


class PayPlugin: NSObject {
    
    //支付结果
    typealias PaymentCompletionHandler = (PaymentStatus) -> Void
    
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
        
        var hashValue: Int {
            switch self {
            case .weChat(let id):
                return id.hashValue
            }
        }
    }
    
    private var payCompletionHandler: PaymentCompletionHandler?
    private var listenterManager = ListenterManager()
    /// 支付状态
    public private(set) var active: Bool = false
    public private(set) var accountList: Set<Account>?
    
    static let shared = PayPlugin()
    
    private override init() { }
    
    public class func register(list: Set<Account>) {
        shared.accountList = list
    }
    
    public class func handleOpenURL(_ url: URL) -> Bool {
        //判断是否正在发起支付
        guard shared.active else { return false }
        //将回调传入listenterManager内部处理
        shared.listenterManager.didReceiveHandleOpenURLCompletion?(url)
        
        //FIXME: - 判断url是否可以激活App
        return true
    }
    
    public class func deliver(provider: Provider, result: @escaping PaymentCompletionHandler) {
        
        shared.payCompletionHandler = result
        shared.active = true
        
        let accountList = shared.accountList
        
        provider.sign { (result) in
            switch result {
            case .success(let business):

                //支付参数配置完成
                
                var control: PaymentStrategy
                
                switch business {
                case .alipayClient(let orderInfo, let scheme):
                    //支付宝客户端签名成功
                    control = AlipayControl(orderInfo: orderInfo, scheme: scheme)
                    
                case .wechat(let params):
                    //微信客户端签名成功
                    control = WeChatControl(params: params)
                }

                //初始化参数配置
                accountList?.forEach{ control.register($0) }
                
                switch business {
                case .alipayClient:
                    //开始执行逻辑
                    shared.syncCallback(control: control, provider: provider)
                case .wechat:
                    //TODO: - 执行微信逻辑
                    break
                }
                
            case .failure(let error):
                //网络请求失败,直接抛出异常
                break
            }
        }
    }
    
    // 依靠客户端同步回调拿到支付结果
    private func syncCallback(control: PaymentStrategy, provider: Provider) {
        
        //调起SDK并跳转到第三方客户端
        control.payOrder()
        
        // 增加返回第三方客户端的监听
        listenterManager.singleHandleOpenURLCompletion { (url) in
            //通过第三方客户端传回,需要传入SDK再做一次校对
            control.processOrder(with: url)
        }
        
        //得到支付结果
        control.processCompletionHandler = { (state, dict) in
            
            //开始验签
            provider.verify(dict: dict, result: { (result) in
                
                switch result {
                case .pass:
                    //验签通过, 进入查询
                    provider.query(result: { (status) in
                        if case let .payFailure(error) = status, case .custom = error , state {
                            //如果本地签名成功,遇到服务器请求失败时,可返回成功状态
                            self.payCompletionHandler?(.paySuccess)
                            self.reset()
                        }
                        else {
                            //将查询结果通知到外面, 整个支付过程结束
                            self.payCompletionHandler?(status)
                            self.reset()
                        }
                    })
                case .reject:
                    //验签未通过
                    self.payCompletionHandler?(.payFailure(.verifyReject))
                    self.reset()
                }
                
            })
            
        }
    }
    
    private func asyncCallback(control: PaymentStrategy, provider: Provider) {
        
        //调起SDK并跳转到第三方客户端
        control.payOrder()
        
        // 增加返回前台页面的监听
        listenterManager.withLatestFromOpenURLCompletion({ (url) in
            
            if let unwrappedURL = url {
                //通过第三方客户端传回,需要传入SDK再做一次校对
                control.processOrder(with: unwrappedURL)
            }
            else {
                //TODO: 进入查询
                provider.query(result: { (result) in
                    
                    //整个支付过程结束
                    
                    switch result {
                    case .paySuccess:
                        //支付成功
                        break
                    case .willPay:
                        //支付中
                        break
                    case .payFailure:
                        //支付失败
                        break
                    }
                })
            }
            
        })
        
    }
    
    /// 恢复成默认支付状态
    private func reset() {
        active = false
    }
}

/// 支付状态管理
//class StatusManager {
//
//    /// 已经发起支付
//    var active: Bool {
//        return true
//    }
//
//
//
//    //准备工作
//    func prepare() {
//
//    }
//
//    /// 释放
//    func free() {
//
//    }
//
//}

extension PayPlugin {
    
    class func openURL(urlString: String, completionHandler completion: ((Bool) -> Swift.Void)? = nil) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            completion?(false)
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { flag in
                completion?(flag)
            }
        } else {
            completion?(UIApplication.shared.openURL(url))
        }
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

enum Business {
    /// 支付宝客户端
    case alipayClient(orderInfo: String, scheme: String)
    /// 微信客户端
    case wechat(params: Dictionary<String, Any>)
}

enum VerifyResult {
    //拒绝
    case reject
    //通过
    case pass
}

//protocol Requester {
//    associatedtype ModelType
//}
//
//class AnyRequester<ModelType>: Requester {
//
//    init<T: Requester>(_ requester: T) where T.ModelType == ModelType {
//
//    }
//}

//class PayControl {
//
//    var provider: Provider
//
//    init(_ provider: Provider) {
//        self.provider = provider
//    }
//
//    func request() {
//
//        provider.sign { (result) in
//
//            switch result {
//            case .success(let business):
//                switch business {
//                case .alipayClient:
//                    //支付宝客户端
//                    break
//                case .alipayWeb:
//                    //支付宝网页
//                    break
//                }
//
//            case .failure(let error):
//                break
//            }
//
//        }
//
//    }
//
//}

class Provider {
    
    //签名回调
    typealias SignCompletionHandler = (Result<Business, PayPluginError>) -> Void
    //验签回调
    typealias VerifyCompletionHandler = (VerifyResult) -> Void
    //查询回调
    typealias QueryCompletionHandler = (PaymentStatus) -> Void
    
    var business: PayPlugin.PayBusiness?
    
    init() {
        
    }
    
    /// 签名
    func sign(result: @escaping SignCompletionHandler) {
        fatalError("需交由子类重写")
    }
    
    /// 验签
    func verify(dict: Dictionary<AnyHashable, Any?>?, result: @escaping VerifyCompletionHandler) {
        result(.pass)
    }
    
    /// 查询
    func query(result: @escaping QueryCompletionHandler) {
        result(.paySuccess)
    }
    
}

class ListenterManager {
    
    /// 已经接收到第三方客户端发来的回调
    var didReceiveHandleOpenURLCompletion: ((URL) -> Void)?
    
    private var applicationWillEnterForeground: NSObjectProtocol?
    
    /// 仅接收一次来自切回前台的通知,如果后面收到第三方客户端的回调将不处理
    func singleHandleForegroundNotification(_ result: @escaping () -> Void) {
        applicationWillEnterForeground = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self](notification) in
            defer { self?.applicationWillEnterForeground = nil }
            result()
        }
    }
    
    /// 仅接收一次来自第三方客户端的回调,如果后面切回前台的通知过来将不处理
    func singleHandleOpenURLCompletion(_ result: @escaping (URL) -> Void) {
        didReceiveHandleOpenURLCompletion = { [unowned self] in
            defer { self.didReceiveHandleOpenURLCompletion = nil }
            result($0)
        }
    }
    
    /// 无论前台或第三方客户端哪一方,只要有回调过来都会调用此方法,因此这个方法会多次调用
    func combinLatest(_ result: @escaping (URL?) -> Void) {
        singleHandleForegroundNotification { result(nil) }
        singleHandleOpenURLCompletion(result)
    }
    
    /// 前台和第三方客户端都有可能回调时,依第三方客户端为准的回调通知. 同时有个超时时间,如果在前台收到通知以后,超出规定时间内没有收到客户端的回调就依前台通知为准
    func withLatestFromOpenURLCompletion(_ result: @escaping (URL?) -> Void, timeout: TimeInterval = 1) {
        
        var isReceivedOpenURLCompletion: Bool = false
        
        singleHandleForegroundNotification {
            
            if isReceivedOpenURLCompletion == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                    if isReceivedOpenURLCompletion == false {
                        result(nil)
                    }
                }
            }
            
        }
        
        singleHandleOpenURLCompletion { (url) in
            result(url)
            isReceivedOpenURLCompletion = true
        }
        
    }
}

class PaymentStrategy {
    
    typealias ProcessCompletionHandler = (_ state: Bool, _ jsonDict: Dictionary<AnyHashable, Any?>?) -> Void
    
    /// 支付结果
    var processCompletionHandler: ProcessCompletionHandler?
    
    //注册
    func register(_ account: PayPlugin.Account) {
        
    }
    
    /// 传入签名,调起客户端
    func payOrder() {
        fatalError("由子类实现")
    }
    
    /// 从客户端回调App
    func processOrder(with url: URL) {
        fatalError("由子类实现")
    }
    
}

//MARK: - 策略模式

//MARK:- 支付宝
class AlipayControl: PaymentStrategy {
    
    let orderInfo: String
    let scheme: String
    
    init(orderInfo: String, scheme: String) {
        self.orderInfo = orderInfo
        self.scheme = scheme
    }
    
    override func payOrder() {
        AlipaySDK.defaultService().payOrder(orderInfo, fromScheme: scheme) { _ in
            //用于wab跳转支付成功或失败的回调
        }
    }
    
    override func processOrder(with url: URL) {
        AlipaySDK.defaultService().processOrder(withPaymentResult: url) { dict in
            
            guard let payStatus = dict?["resultStatus"] as? String else {
                //TODO: 处理失败结果
                self.processCompletionHandler?(false, dict)
                return
            }

            if payStatus == "9000" {
                self.processCompletionHandler?(true, dict)
            }
            else {
                self.processCompletionHandler?(false, dict)
            }
            
        }
    }
    
}

public struct WeixinSignResult: Codable {
    
    var package: String
    var partnerid: String
    var noncestr: String
    var prepayid: String
    var appid: String
    var timestamp: String
    var sign: String
 
    fileprivate var payRequest: PayReq {
        let req = PayReq()
        req.openID = appid
        req.partnerId = partnerid
        req.prepayId = prepayid
        req.nonceStr = noncestr
        req.timeStamp = UInt32(timestamp)!
        req.package = package
        req.sign = sign
        return req
    }
}


//MARK:- 微信
class WeChatControl: PaymentStrategy {
    
    let params: Dictionary<String, Any>
    
    init(params: Dictionary<String, Any>) {
        self.params = params
    }
    
    override func payOrder() {
        
        do {
            let data = try JSONSerialization.data(withJSONObject: params, options: [])
            let coder = JSONDecoder()
            let result = try coder.decode(WeixinSignResult.self, from: data)
            WXApi.send(result.payRequest)
        }
        catch {
            fatalError("解析出错")
        }
        
    }
    
    override func processOrder(with url: URL) {
        
        let queryDictionary = url.queryDictionary
        guard let ret = queryDictionary["ret"] as? String else {
            //TODO: 处理失败结果
            processCompletionHandler?(false, queryDictionary)
            return
        }
        
        let result = (ret == "0")
        
        processCompletionHandler?(result, queryDictionary)
        
    }
    
}

//MARK: - 建行
class CCBPayControl: PaymentStrategy {
    
    var orderInfo: String!
    
    override func payOrder() {
        
        CCBNetPay.defaultService().payOrder(orderInfo) { dict in
            //支付完成回调方法，该方法回调结果需要在processOrderWithPaymentResult方法实现的前提下才能在completionBlock拿到支付结果。将在支付结果获取与处理中详细说明
            
            guard let unwrappedDict = dict else {
                //FIXME: - 字典为空时
                return
            }
            
            if let status = unwrappedDict["SUCCESS"] as? String, status.isEmpty == false {
                switch status {
                case "Y":
                    self.processCompletionHandler?(true, dict)
                    return
                case "N":
                    self.processCompletionHandler?(false, dict)
                    return
                default:
                    break
                }
            }
            
            if let epayStatus = unwrappedDict["epayStatus"] as? String, epayStatus == "Y" {
                self.processCompletionHandler?(true, dict)
                return
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
            
            //FIXME: - 会不会触发两次回调
            guard let unwrappedDict = dict else {
                //FIXME: - 字典为空时
                return
            }
            
            if let status = unwrappedDict["SUCCESS"] as? String, status.isEmpty == false {
                switch status {
                case "Y":
                    self.processCompletionHandler?(true, dict)
                    return
                case "N":
                    self.processCompletionHandler?(false, dict)
                    return
                default:
                    break
                }
            }
            
            if let epayStatus = unwrappedDict["epayStatus"] as? String, epayStatus == "Y" {
                self.processCompletionHandler?(true, dict)
                return
            }
            
        }
        
    }
    
}


//MARK: - 银联充值
class UnionRechargeControl: PaymentStrategy {
    
    var payChannel: String!
    var orderInfo: String!
    
    override func register(_ account: PayPlugin.Account) {
        if case .weChat(let id) = account {
            UMSPPPayUnifyPayPlugin.registerApp(id)
        }
    }
    
    override func payOrder() {
        
        UMSPPPayUnifyPayPlugin.pay(withPayChannel: payChannel, payData: orderInfo) { (code, info) in
            
            
            
        }
        
    }
    
    override func processOrder(with url: URL) {
        UMSPPPayUnifyPayPlugin.handleOpen(url)
    }
}

extension PayPlugin.SupportedPlatform {
    
    var payChannel: String {
        
        switch self {
        case .alipay:
            return "02" //支付宝支付
        case .weChat:
            return "01" //微信支付
        case .unionpay:
            return "03" //银商钱包
        default:
            fatalError("不支持的类型")
        }
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


////MARK: - 支付策略上下文
//class PayControlContext {
//
//    var control: PaymentStrategy
//
//    init(control: PaymentStrategy) {
//        self.control = control
//    }
//
//    func payOrder() {
//        control.payOrder()
//    }
//
//    func processOrder(with url: URL) {
//        control.processOrder(with: url)
//    }
//}
