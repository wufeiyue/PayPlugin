//
//  MultipartPayControl.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

public class MultipartPayControl: NSObject {
    
    /// 支付类型
    public var payType: PayType!
    
    public var payClient: PayClient!
    
    /// 支付视图控制器
    public var viewController: UIViewController!
    
    func payOrder(profile: OrderInfoProfile, result: @escaping ResponseCompletion) { }
    
    func processOrder(with url: URL, result: @escaping ResponseCompletion) { }
    
}

