//
//  PayManager.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
import AlipaySDK
import SYWechatOpenSDK
import CCBNetPaySDK
import UMSPPPayUnifyPayPlugin

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
    private var listenterManager = ListenterManager()
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
        shared.listenterManager.didReceiveHandleOpenURLCompletion?(url)
        
        //FIXME: - 判断url是否可以激活App
        return true
    }
    
    public class func deliver(provider: PaymentProvider, result: @escaping PaymentCompletionHandler) {
        
        shared.payCompletionHandler = result
        shared.active = true
        
        let accountList = shared.accountList
        
        provider.sign { (result) in
            switch result {
            case .success(let business):

                switch business {
                case .alipayClient(let orderInfo, let scheme):
                    //支付宝客户端签名成功
                    let control = AlipayControl(orderInfo: orderInfo, scheme: scheme)
                    //初始化参数配置
                    accountList?.forEach{ control.register($0) }
                    //添加同步逻辑回调
                    shared.syncCallback(control: control, provider: provider)
                    
                case let .wechat(openId, partnerId, prepayId, nonceStr, timeStamp, package, sign):
                    //微信客户端签名成功
                    let control = WeChatControl(package: package, partnerid: partnerId, noncestr: nonceStr, prepayid: prepayId, openId: openId, timestamp: timeStamp, sign: sign)
                    //初始化参数配置
                    accountList?.forEach{ control.register($0) }
                    //添加同步逻辑回调
                    shared.asyncCallback(control: control, provider: provider)
                    
                case .ccbpay(let orderInfo):
                    //建行签名成功
                    let control = CCBPayControl(orderInfo: orderInfo)
                    //初始化参数配置
                    accountList?.forEach{ control.register($0) }
                    //添加同步逻辑回调
                    shared.asyncCallback(control: control, provider: provider)
                    
                case .unionRecharge(let orderInfo, let channel):
                    //银联充值签名成功
                    let control = UnionRechargeControl(orderInfo: orderInfo, payChannel: channel.unionRecharge)
                    //初始化参数配置
                    accountList?.forEach{ control.register($0) }
                    //添加异步逻辑回调
                    shared.asyncCallback(control: control, provider: provider)
                 
                case .web(let profile):
                    let control = WebPayControl(profile: profile)
                    //添加异步查询逻辑
                    shared.queryCallback(control: control, provider: provider)
                    
                }

            case .failure(let error):
                //网络请求失败,直接抛出异常
                shared.payCompletionHandler?(.failure(.custom(error)))
                shared.reset()
            }
        }
    }
    
    // 依靠客户端同步回调拿到支付结果
    private func syncCallback(control: PaymentPlatformStrategy, provider: PaymentProvider) {
        
        //调起SDK并跳转到第三方客户端
        control.payOrder()
        
        //得到支付结果
        control.processCompletionHandler = { (state, dict) in
            
            switch state {
            case .success, .willPay: //本地SDK同步为支付成功/支付中
                
                if let unwrappedDict = dict {
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
                }
                else {
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
                }
                
            case .failure(let error): //本地sdk状态码显示处理失败
                self.payCompletionHandler?(.failure(error))
                self.reset()
            }
            
        }
        
        // 增加返回第三方客户端的监听
        listenterManager.singleHandleOpenURLCompletion { (url) in
            //通过第三方客户端传回,需要传入SDK再做一次校对
            control.processOrder(with: url)
        }
    }
    
    private func asyncCallback(control: PaymentPlatformStrategy, provider: PaymentProvider) {
        
        //调起SDK并跳转到第三方客户端
        control.payOrder()
        
        //第三方客户端回调的验签结果
        control.processCompletionHandler = { (state, dict) in
            
            switch state {
            case .success, .willPay: //本地SDK同步为支付成功/支付中
                
                if let unwrappedDict = dict {
                    //开始验签
                    provider.verify(dict: unwrappedDict, result: { verifyResult in
                        
                        switch verifyResult {
                        case .pass: //验签通过也可能没有重载方法直接通过的, 进入查询, 已查询结果为准
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
                }
                else {
                    //不需要验签,直接去查询结果
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
                }
                
            case .failure(let error): //本地sdk状态码显示处理失败
                self.payCompletionHandler?(.failure(error))
                self.reset()
            }
            
        }
        
        // 增加返回前台页面的监听
        listenterManager.withLatestFromOpenURLCompletion({ (url) in
            
            if let unwrappedURL = url {
                //通过第三方客户端传回,需要传入SDK再做一次校对
                control.processOrder(with: unwrappedURL)
            }
            else {
                provider.query(result: {
                    //将查询结果通知到外面, 整个支付过程结束
                    self.payCompletionHandler?($0)
                    self.reset()
                })
            }
            
        })
        
    }
    
    private func queryCallback(control: PaymentWebStrategy, provider: PaymentProvider) {
        
        //调起SDK打开网页也有可能跳转到第三方
        control.payOrder()
        
        //得到支付结果
        control.processCompletionHandler = {
            provider.query(result: {
                //将查询结果通知到外面, 整个支付过程结束
                self.payCompletionHandler?($0)
                self.reset()
            })
        }
        
        control.openURLCompletion = { url in
            //跳转到第三方平台
            return self.openURL(url: url, completionHandler: { (finished) in
                guard finished else { return }
                //仅跳转成功后, 才增加返回前台的监听
                self.listenterManager.singleHandleForegroundNotification { [unowned self] in
                    //判断是否正在发起支付
                    guard self.active else { return }
                    
                    provider.query(result: {
                        //将查询结果通知到外面, 整个支付过程结束
                        self.payCompletionHandler?($0)
                        self.reset()
                    })
                }
            })
        }
        
    }
    
    /// 恢复成默认支付状态
    private func reset() {
        payCompletionHandler = nil
        active = false
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
    
}

class ListenterManager {
    
    /// 已经接收到第三方客户端发来的回调
    var didReceiveHandleOpenURLCompletion: ((URL) -> Void)?
    
    private var applicationWillEnterForeground: NSObjectProtocol?
    
    /// 仅接收一次来自切回前台的通知,如果后面收到第三方客户端的回调将不处理
    func singleHandleForegroundNotification(_ result: @escaping () -> Void) {
        applicationWillEnterForeground = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self](notification) in
            result()
            self?.applicationWillEnterForeground = nil
        }
    }
    
    /// 仅接收一次来自第三方客户端的回调,如果后面切回前台的通知过来将不处理
    func singleHandleOpenURLCompletion(_ result: @escaping (URL) -> Void) {
        didReceiveHandleOpenURLCompletion = { [weak self] in
            result($0)
            self?.didReceiveHandleOpenURLCompletion = nil
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

class PaymentPlatformStrategy {
    
    typealias ProcessCompletionHandler = (_ result: PaymentStatus, _ jsonDict: Dictionary<AnyHashable, Any?>?) -> Void
    
    /// 支付结果
    var processCompletionHandler: ProcessCompletionHandler?
    
    //注册
    func register(_ account: PayPlugin.Account) { }
    
    /// 传入签名,调起客户端
    func payOrder() {
        fatalError("由子类实现")
    }
    
    /// 从客户端回调App
    func processOrder(with url: URL) {
        fatalError("由子类实现")
    }
    
}

class PaymentWebStrategy {
    
    typealias ProcessCompletionHandler = () -> Void
    
    /// 支付结果
    var processCompletionHandler: ProcessCompletionHandler?
    
    // 打开客户端跳转回调
    var openURLCompletion: ((URL) -> Bool)?
    
    func payOrder() {
        fatalError("由子类实现")
    }
}


//MARK: - 策略模式

//MARK:- 支付宝
class AlipayControl: PaymentPlatformStrategy {
    
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
                self.processCompletionHandler?(.failure(.lossData), dict)
                return
            }
            
            switch payStatus {
            case "9000":
                //支付成功
                self.processCompletionHandler?(.success, dict)
            case "8000":
                //支付中
                self.processCompletionHandler?(.willPay, dict)
            case "6001":
                //用户取消
                self.processCompletionHandler?(.failure(.userDidCancel), dict)
            default:
                //未知状态
                self.processCompletionHandler?(.failure(.unknown), dict)
            }
            
        }
    }
    
}

//MARK:- 微信
class WeChatControl: PaymentPlatformStrategy {
    
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

//MARK: - 建行
class CCBPayControl: PaymentPlatformStrategy {
    
    let orderInfo: String
    private var isFlag = true
    
    init(orderInfo: String) {
        self.orderInfo = orderInfo
    }
    
    override func payOrder() {
        
        CCBNetPay.defaultService().payOrder(orderInfo) { dict in
            //支付完成回调方法，该方法回调结果需要在processOrderWithPaymentResult方法实现的前提下才能在completionBlock拿到支付结果。将在支付结果获取与处理中详细说明
            if self.isFlag {
                self.singleProcessCompletionHandler(dict: dict)
                self.isFlag = false
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

class WebPayControl: PaymentWebStrategy {
    
    let profile: PostFormProfile
    
    init(profile: PostFormProfile) {
        self.profile = profile
    }
    
    override func payOrder() {
        
        let postFormWebViewController = PostFormWebViewController()
        postFormWebViewController.baseURL = profile.baseURL
        postFormWebViewController.javeScript = profile.javeScript
        postFormWebViewController.loadHTMLString = profile.loadHTMLString
        postFormWebViewController.returnURLString = profile.returnURLString
        postFormWebViewController.openURLRole = profile.openURLRole
        postFormWebViewController.navigationItemTitle = profile.title
        
        func close() {
            postFormWebViewController.free()
            postFormWebViewController.view.removeFromSuperview()
            postFormWebViewController.removeFromParent()
        }
        
        postFormWebViewController.openURLCompletion = { url in
            if self.openURLCompletion?(url) == true {
                // 通过webview检索到url跳转到第三方客户端后,就关闭此网页
                close()
            }
        }
        
        postFormWebViewController.backAction = {
            // 关闭页面
            close()
            //回调出去
            self.processCompletionHandler?()
        }
        
        if let currentViewController = UIViewController.current() {
            
            if let current = currentViewController.navigationController {
                current.view.addSubview(postFormWebViewController.view)
                current.addChild(postFormWebViewController)
            }
            else {
                currentViewController.view.addSubview(postFormWebViewController.view)
                currentViewController.addChild(postFormWebViewController)
            }
        }
        
    }
}

//{\"extraMsg\":\"\",\"resultMsg\":\"用户取消支付\",\"rawMsg\":\"{\\\"errCode\\\":\\\"-2\\\",\\\"type\\\":\\\"0\\\",\\\"errStr\\\":\\\"用户点击取消并返回\\\"}\"}
struct UnionRechargeResult: Codable {
    var extraMsg: String
    var resultMsg: String
    var rawMsg: UnionRechargeMsg
}

struct UnionRechargeMsg: Codable {
    var errCode: String
    var type: String
    var errStr: String
}

//MARK: - 银联充值
class UnionRechargeControl: PaymentPlatformStrategy {
    
    let payChannel: String
    let orderInfo: String
    
    init(orderInfo: String, payChannel: String) {
        self.orderInfo = orderInfo
        self.payChannel = payChannel
    }
    
    override func register(_ account: PayPlugin.Account) {
        if case .weChat(let id) = account {
            UMSPPPayUnifyPayPlugin.registerApp(id)
        }
    }
    
    override func payOrder() {
        
        UMSPPPayUnifyPayPlugin.pay(withPayChannel: payChannel, payData: orderInfo) { [weak self](code, info) in
            
            guard let unwrappedInfo = info else {
                self?.processCompletionHandler?(.failure(.lossData), nil)
                return
            }
            
            do {
                let coder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: unwrappedInfo, options: [])
                let params = try coder.decode(UnionRechargeResult.self, from: data)
            
                switch params.rawMsg.errCode {
                case "-2":
                    //取消支付
                    self?.processCompletionHandler?(.failure(.userDidCancel), nil)
                case "0":
                    //支付成功
                    self?.processCompletionHandler?(.success, nil)
                default:
                    //未知
                    self?.processCompletionHandler?(.failure(.unknown), nil)
                }
            }
            catch {
                self?.processCompletionHandler?(.failure(.custom(error.localizedDescription)), nil)
            }
        }
        
    }
    
    override func processOrder(with url: URL) {
        UMSPPPayUnifyPayPlugin.handleOpen(url)
    }
}

extension PayPlugin.SupportedPlatform {
    
    var unionRecharge: String {
        
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

extension UIViewController {
    fileprivate class func current(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return current(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return current(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return current(base: presented)
        }
        return base
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
