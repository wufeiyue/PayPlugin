//
//  PayType.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

public class PostFormControl {
    
    /// 支付视图控制器
    public var viewController: UIViewController!
    
    public var willOpenURL: ((URL) -> Bool)?
    
    func payOrder(profile: PostFormProfile, result: @escaping ResponseCompletion) {
        
        let postFormWebViewController = PostFormWebViewController(formProfile: profile)
        postFormWebViewController.backAction = result
        postFormWebViewController.title = profile.title
        
        postFormWebViewController.willOpenURL = {
            
            let isDidOpenURL = self.willOpenURL?($0)
            
            if isDidOpenURL == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    postFormWebViewController.navigationController?.popViewController(animated: true)
                })
            }
        }
        
        viewController.navigationController?.pushViewController(postFormWebViewController, animated: true)
        
    }
    
}
