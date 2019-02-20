//
//  Ywtpay.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import Foundation
import UMSPPPayUnifyPayPlugin

final class UnionRechargeControl: PaymentPlatformStrategy {
    
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
            
            /*
             {\"extraMsg\":\"\",\"resultMsg\":\"用户取消支付\",\"rawMsg\":\"{\\\"errCode\\\":\\\"-2\\\",\\\"type\\\":\\\"0\\\",\\\"errStr\\\":\\\"用户点击取消并返回\\\"}\"}
             */
            
            guard let data = info?.data(using: .utf8) else {
                self?.processCompletionHandler?(.failure(.lossData), nil)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                let dict = json as? Dictionary<String, String>
                if let rawMsg = dict?["rawMsg"], let subData = rawMsg.data(using: .utf8) {
                    let subJson = try JSONSerialization.jsonObject(with: subData, options: .mutableContainers)
                    let subDict = subJson as? Dictionary<String, String>
                    if let code = subDict?["errCode"] {
                        switch code {
                        case "-2":
                            //取消支付
                            self?.processCompletionHandler?(.failure(.userDidCancel), nil)
                            return
                        case "0":
                            //支付成功
                            self?.processCompletionHandler?(.success, nil)
                            return
                        default:
                            //未知
                            self?.processCompletionHandler?(.failure(.unknown), nil)
                            return
                        }
                    }
                }
                
                self?.processCompletionHandler?(.failure(.unknown), nil)
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
