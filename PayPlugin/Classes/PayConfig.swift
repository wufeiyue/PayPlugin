//
//  PayConfig.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
//
//protocol PayTypeConfig {
//    var canOpenString: String { get }
//    var openURLString: String? { get }
//}
//
//extension PayTypeConfig {
//    var openURLString: String? {
//        return nil
//    }
//}
//
//public struct PayConfig {
//    
//    public struct Alipay: PayTypeConfig {
//        
//        public var canOpenString: String {
//            return "alipay://"
//        }
//        
//        public var openURLString: String? {
//            return "safepay"
//        }
//        
//    }
//    
//    public struct Weixin: PayTypeConfig {
//        public var canOpenString: String {
//            return "weixin://"
//        }
//    }
//    
//    public struct CCBPay: PayTypeConfig {
//        public var canOpenString: String {
//            return "mbspay://"
//        }
//    }
//    
//    public struct Unionpay: PayTypeConfig {
//        public var canOpenString: String {
//            return "uppaywallet://"
//        }
//    }
//    
//    
//}
//
//extension PayClient {
//    
//    var config: PayTypeConfig {
//        
//        switch self {
//        case .alipay:
//            return PayConfig.Alipay()
//        case .ccb:
//            return PayConfig.CCBPay()
//        case .unionpay:
//            return PayConfig.Unionpay()
//        case .weixin:
//            return PayConfig.Weixin()
//        }
//        
//    }
//    
//    var name: String {
//        
//        switch self {
//        case .alipay:
//            return "支付宝"
//        case .ccb:
//            return "建行App"
//        case .unionpay:
//            return "银联App"
//        case .weixin:
//            return "微信"
//        }
//        
//    }
//}
