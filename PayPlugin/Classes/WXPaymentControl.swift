//
//  Weixin.swift
//  Component_Pay
//
//  Created by 武飞跃 on 2018/7/30.
//

import UIKit
import SYWechatOpenSDK
/*
public class WXPaymentControl: MultipartPayControl {
    
    private var result: ResponseCompletion?
    
    override func payOrder(profile: OrderInfoProfile, result: @escaping ResponseCompletion) {
        WXApi.send(profile.payReq)
    }
    
    override func processOrder(with url: URL, result: @escaping ResponseCompletion) {
        self.result = result
        WXApi.handleOpen(url, delegate: self)
    }
    
}


extension WXPaymentControl: WXApiDelegate {

    public func onReq(_ req: BaseReq!) {

    }

    public func onResp(_ resp: BaseResp!) {

        guard resp is PayResp else { return }

//        let response = PayResponse(code: .weixin(resp.errCode), payResult: .weixin(resp.errCode), descriptor: nil)
//
//        result?(response)
    }

}

extension PayError {
    
    fileprivate static func weixin(_ code: Int32) -> PayError? {
        
        switch code {
        case WXErrCodeUserCancel.rawValue:
            return .userCancel
        case WXErrCodeSentFail.rawValue:
            return .sentFailure
        case WXErrCodeAuthDeny.rawValue:
            return .authDeny
        case WXErrCodeUnsupport.rawValue:
            return .unsupport
        case WXErrCodeCommon.rawValue:
            return .unknow
        default:
            return nil
        }
        
    }
    
    
}

//extension PaymentStatus {
//
//    fileprivate static func weixin(_ code: Int32) -> PaymentStatus {
//        switch code {
//        case WXSuccess.rawValue:
//            return .paySuccess
//        default:
//            return .payFailure
//        }
//    }
//
//}




extension OrderInfoProfile {
    
    fileprivate var payReq: PayReq {
        
        do {
            
//            let data = try JSONSerialization.data(withJSONObject: params, options: [])
//            let coder = JSONDecoder()
//            let result = try coder.decode(WeixinSignResult.self, from: data)
//            
//            return result.payRequest
        }
        catch {
            fatalError("解析出错")
        }
        
        
    }
}
*/
