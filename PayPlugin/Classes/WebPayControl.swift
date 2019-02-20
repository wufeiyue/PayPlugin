//
//  Ywtpay.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

final class WebPayControl: PaymentWebStrategy {
    
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
