//
//  ListenedPaymentManager.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/8/9.
//

import Foundation

/*
 四种情况:
 
 1. 进入   ->   前台                (仅查询)
 2. 进入   ->   回调                (关闭)
 3. 进入   ->   回调   -> 前台
 4. 进入   ->   前台   -> 回调
 
 */

//
private final class ClientRoute {
    
    private var didEnterBackground: NSObjectProtocol?
    
    /// 能否打开 第三方客户端的回调  已经打开, 或者不可以打开
    private var completion: (Bool) -> Void
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }
    
    /// 打开客户端
    func open(with url: URL) {
        
        guard UIApplication.shared.canOpenURL(url) else {
            completion(false)
            return
        }
        
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: completion)
        }
        else {
            
            let canOpenURL = UIApplication.shared.openURL(url)
            
            didEnterBackground = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] (notification) in
                
                defer {
                    self?.didEnterBackground.flatMap{ NotificationCenter.default.removeObserver($0) }
                }
                
                self?.completion(canOpenURL)
            }
            
        }
        
    }
}

public class ListenedPaymentManager: NSObject {
    
    private var listener = ListenerManager()
    
    private var didEnterBackground: NSObjectProtocol?
    
    public func completionHandler(result: @escaping (Any?) -> Void) {
        listener.completionHandler = result
    }
    
    public func add() {
        listener.add()
    }
    
    public func remove() {
        listener.remove()
    }
    
    public func openURLAndAddListened(with url: URL) -> Bool {
        return openURL(with: url) { (completed) in
            self.add()
        }
    }
    
    private func openURL(with url: URL, complete: @escaping (Bool) -> Void ) -> Bool {
        
        guard UIApplication.shared.canOpenURL(url) else {
            complete(false)
            return false
        }
        
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: complete)
        }
        else {
            
            var canOpenURL: Bool = true
            
            didEnterBackground = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { (notification) in
                
                defer {
                    self.didEnterBackground.flatMap{ NotificationCenter.default.removeObserver($0) }
                }
                
                complete(canOpenURL)
            }
            
            canOpenURL = UIApplication.shared.openURL(url)
        }
        
        return true
    }
    
}

public class ListenerManager: NSObject {
    
    public var completionHandler: ((Any?) -> Void)?
    
    public private(set) var isBusy: Bool = false
    private var applicationWillEnterForeground: NSObjectProtocol?
    private var applicationDidBecomeActive: NSObjectProtocol?
    private var payManagerHandleOpenURLActive: NSObjectProtocol?
    
    /// 在每个支付项生活周期最开始调用
    func add() {
        
        if applicationWillEnterForeground == nil {
            
            applicationWillEnterForeground = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self](notification) in
                
                self?.isBusy = true
                
            }
        }
        
        if applicationDidBecomeActive == nil {
            
            applicationDidBecomeActive = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] (notification) in
                
                guard self?.isBusy == true else {
                    return
                }
                
                defer {
                    self?.isBusy = false
                }
                
                self?.completionHandler?(nil)
                
                self?.applicationWillEnterForeground.flatMap{ NotificationCenter.default.removeObserver($0) }
                self?.applicationWillEnterForeground = nil
                self?.applicationDidBecomeActive.flatMap{ NotificationCenter.default.removeObserver($0) }
                self?.applicationDidBecomeActive = nil
            }
        }
        
        if payManagerHandleOpenURLActive == nil {
            
            payManagerHandleOpenURLActive = NotificationCenter.default.addObserver(forName: .payManagerHandleOpenURL, object: nil, queue: .main) { [weak self] (notification) in
                
                self?.isBusy = false
                
                self?.completionHandler?(notification.object)
                
                self?.payManagerHandleOpenURLActive.flatMap{ NotificationCenter.default.removeObserver($0) }
                self?.payManagerHandleOpenURLActive = nil
                self?.applicationWillEnterForeground.flatMap{ NotificationCenter.default.removeObserver($0) }
                self?.applicationWillEnterForeground = nil
                self?.applicationDidBecomeActive.flatMap{ NotificationCenter.default.removeObserver($0) }
                self?.applicationDidBecomeActive = nil
            }
            
        }
    }
    
    func remove() {
        payManagerHandleOpenURLActive.flatMap{ NotificationCenter.default.removeObserver($0) }
        applicationWillEnterForeground.flatMap{ NotificationCenter.default.removeObserver($0) }
        applicationDidBecomeActive.flatMap{ NotificationCenter.default.removeObserver($0) }
    }
    
}
/*
public class ListenedPaymentManager: NSObject {
    
    public var notificationName: Notification.Name = .payManagerHandleOpenURL
    
//    public var clientHandler: ((Any?) -> Void)?
//    public var queryHandler: (() -> Void)?
    
    public var completionHandler: ((Any?) -> Void)?
    
    /// open回调已经执行
//    public private(set) var isAlreadyOpenURL: Bool = false
    
    private var rebecomeActive: Bool = false
    
    private var didBecomeActiveServer: NSObjectProtocol?
    /// 客户端回到的监听
    private var openURLServer: NSObjectProtocol?
    
    private var didEnterBackground: NSObjectProtocol?
    
    public func openURLAndAddListened(with url: URL) -> Bool {
        return openURL(with: url) { (completed) in
            self.addListenedPayment()
        }
    }
    
    /// 添加监听回调
    ///
    ///     点击商户回调到App中, 如果openURL调用时机在appBecomeActive前, 则appBecomeActive监听不会执行, 直接compledHandler结果
    ///     点击商户回调到App中, 如果openURL调用时机在appBecomeActive后, 会走网络查询接口, 如果响应成功后, openURL还未执行, 则使用网络接口数据
    ///                                                                           如果响应成功后, openURL已经执行, 外部逻辑处理放弃查询接口数据, 使用compledHandler结果, 再次进行接口验签
    ///     直接点击App进入, 处于appBecomeActive状态, openURL不会执行, 仅查询网络接口获取结果
    ///
    /// - Parameter completedHandler: 回调结果, 需要查询的返回查询结果, 或者直接由第三方平台回调的结果
    public func addListenedPayment() {
        
//        isAlreadyOpenURL = false
        
        didEnterBackground = NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: .main) { (notification) in
            
            defer {
                self.didEnterBackground.flatMap{ NotificationCenter.default.removeObserver($0) }
            }
            
            self.rebecomeActive = true
            
        }

        
        didBecomeActiveServer = NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: .main) { (notification) in
            
            //避免因为打开系统弹框时, 触发监听回调(第三方支付支付宝,微信首次打开会有弹框出现)
//            guard notification.object is UIApplication == false else {
//                return
//            }
            
            guard self.rebecomeActive else { return }

            defer {
                self.didBecomeActiveServer.flatMap{ NotificationCenter.default.removeObserver($0) }
                //不移除客户端回调的监听, 此监听需要再外部手动移除才行, 因为会出现调转到第三方支付平台等待支付页面后, 将App切到前台, 这时有支付结果查询, 会提示失败, 但是当再次操作第三方完成支付时, 应该正常回调给App, 继续之前未完成的支付
//                self.openURLServer.flatMap{ NotificationCenter.default.removeObserver($0) }
            }
            
//            self.queryHandler?()
//            self.queryHandler = nil
            self.completionHandler?(nil)
            self.completionHandler = nil
            self.rebecomeActive = false
            
        }
        
        openURLServer = NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: .main) { (notification) in
            
            defer {
                self.didBecomeActiveServer.flatMap{ NotificationCenter.default.removeObserver($0) }
                self.openURLServer.flatMap{ NotificationCenter.default.removeObserver($0) }
            }
            
//            self.isAlreadyOpenURL = true
//            self.clientHandler?(notification.object)
//            self.clientHandler = nil
            self.completionHandler?(notification.object)
            self.completionHandler = nil
        }
        
    }
    
    public func removeListenedPayment() {
        self.didBecomeActiveServer.flatMap{ NotificationCenter.default.removeObserver($0) }
        self.openURLServer.flatMap{ NotificationCenter.default.removeObserver($0) }
    }
    
    private func openURL(with url: URL, complete: @escaping (Bool) -> Void ) -> Bool {
        
        guard UIApplication.shared.canOpenURL(url) else {
            complete(false)
            return false
        }
        
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: complete)
        }
        else {
            
            var canOpenURL: Bool = true
            
            didEnterBackground = NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: .main) { (notification) in
                
                defer {
                    self.didEnterBackground.flatMap{ NotificationCenter.default.removeObserver($0) }
                }
                
                complete(canOpenURL)
            }
            
            canOpenURL = UIApplication.shared.openURL(url)
        }
        
        return true
    }
    
    deinit {
        self.openURLServer.flatMap{ NotificationCenter.default.removeObserver($0) }
    }
}
 
 */
