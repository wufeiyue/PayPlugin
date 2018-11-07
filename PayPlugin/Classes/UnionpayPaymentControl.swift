//
//  Unionpay.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation

extension PayMode {
    fileprivate var unionpay: String {
        switch self {
        case .dev:
            return "01"
        case .pro:
            return "00"
        }
    }
}

public class UnionPayPaymentControl: MultipartPayControl {
    
    public var scheme: String = ""
    
//    override func payOrder(orderInfo: String, result: @escaping ResponseCompletion) {
//        
//        UPPaymentControl.default().startPay(orderInfo,
//                                            fromScheme: scheme,
//                                            mode: mode.unionpay,
//                                            viewController: viewController)
//        
//    }
    
    
}



