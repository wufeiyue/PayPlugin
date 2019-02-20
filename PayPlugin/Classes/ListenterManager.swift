//
//  ListenterManager.swift
//  PayPlugin
//
//  Created by 武飞跃 on 2019/2/20.
//

import Foundation

class ListenterManager {
    
    /// 已经接收到第三方客户端发来的回调
    var didReceiveHandleOpenURLCompletion: ((URL) -> Void)?
    
    private var applicationWillEnterForeground: NSObjectProtocol?
    
    /// 仅接收一次来自切回前台的通知,如果后面收到第三方客户端的回调将不处理
    func singleHandleForegroundNotification(_ result: @escaping () -> Void) {
        applicationWillEnterForeground = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            result()
            self?.applicationWillEnterForeground.flatMap{ NotificationCenter.default.removeObserver($0) }
            self?.applicationWillEnterForeground = nil
        }
    }
    
    func multipleHandleForegroundNotification(_ result: @escaping () -> Void) -> (() -> Void){
        applicationWillEnterForeground = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            result()
        }
        return {
            self.applicationWillEnterForeground.flatMap{ NotificationCenter.default.removeObserver($0) }
            self.applicationWillEnterForeground = nil
        }
    }
    
    /// 仅接收一次来自第三方客户端的回调,如果后面切回前台的通知过来将不处理
    func singleHandleOpenURLCompletion(_ result: @escaping (URL) -> Void){
        didReceiveHandleOpenURLCompletion = {
            result($0)
            self.didReceiveHandleOpenURLCompletion = nil
        }
    }
    
    /// 无论前台或第三方客户端哪一方,只要有回调过来都会调用此方法,因此这个方法会多次调用
    func combinLatest(_ result: @escaping (URL?) -> Void) {
        singleHandleForegroundNotification { result(nil) }
        singleHandleOpenURLCompletion(result)
    }
    
    /// 前台和第三方客户端都有可能回调时,依第三方客户端为准的回调通知. 同时有个超时时间,如果在前台收到通知以后,超出规定时间内没有收到客户端的回调就依前台通知为准
    func withLatestFromOpenURLCompletion(_ result: @escaping (URL?) -> Void, timeout: TimeInterval = 1) -> (() -> Void) {
        
        var isReceivedOpenURLCompletion: Bool = false
        
        let cancelable = multipleHandleForegroundNotification {
            
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
        
        return cancelable
    }
}
